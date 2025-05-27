//
//  HeartRateMeasurementViewModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/20/23.
//

import Foundation
import AVFoundation
import Photos

extension HeartRateMeasurementView {
    @MainActor class ViewModel: NSObject, AVCaptureFileOutputRecordingDelegate, ObservableObject {
        
        private var session: AVCaptureSession?
        private var timer: Timer?
        private var completion: ((Result<Double, Error>) -> ())? = nil
        
        private let defaults = UserDefaults.standard
        let output = AVCaptureMovieFileOutput()
        let previewLayer = AVCaptureVideoPreviewLayer()
        
        @Published var showHeartRateTip: Bool = false
        @Published private(set) var isRecording: Bool = false
        @Published private(set) var isProcessing: Bool = false
        @Published private(set) var secondsElapsed: Int = 0
        
        var overlayMessage: String? {
            if isProcessing {
                return "Please be patient while we are calculating your heart rate."
            } else if isRecording {
                return "Please wait for \(MeasurementConstants.MAX_TIME_DURATION - secondsElapsed) seconds while we record your video."
            }
            return nil
        }
        
        func recordHeartRateVideo(completion: @escaping (Result<Double, Error>) -> ()) -> Void {
            if isRecording || isProcessing { return }
            self.completion = completion

            let filePath = NSTemporaryDirectory() + "\(UserSession.getCurrentUUID()).mov"
            output.startRecording(to: URL(filePath: filePath), recordingDelegate: self)
            
            isRecording.toggle()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                Task { @MainActor in
                    guard self.secondsElapsed + 1 < MeasurementConstants.MAX_TIME_DURATION else {
                        self.output.stopRecording()
                        self.isRecording.toggle()
                        self.secondsElapsed = 0
                        self.timer?.invalidate()
                        self.timer = nil
                        return
                    }
                    self.secondsElapsed += 1
                }
            }
        }
        
        private func processHeartRateVideo(at videoUrl: URL) -> Void {
            isProcessing.toggle()
            let videoAsset = AVAsset(url: videoUrl)
            Task {
                do {
                    defer {
                        deleteHeartRateVideo(at: videoUrl)
                    }
                    
                    // Loading video's metadata
                    let tracks = try await AVURLAsset(url: videoUrl).load(.tracks)
                    let fps = try await tracks[0].load(.nominalFrameRate).rounded()
                    let duration = try await videoAsset.load(.duration)
                    let frames = Double(fps) * duration.seconds

                    // Generating image frames for the request times and calculating pixel data
                    var colorIntensities: [Int64] = []
                    let generator = AVAssetImageGenerator(asset: videoAsset)
                    for i in stride(from: MeasurementConstants.STARTING_FRAME_COUNT, to: Int(frames), by: MeasurementConstants.FRAME_INTERVAL) {
                        
                        // Extracting image from the video at the given frame index
                        let result = try await generator.image(at: CMTime(value: Int64(i), timescale: Int32(fps)))
                        let image = result.image
                        
                        // Extracting color intensities from the extracted image
                        let data = image.dataProvider?.data
                        let ptr: UnsafePointer<UInt8> = CFDataGetBytePtr(data)
                        let length: CFIndex = CFDataGetLength(data)
                        var colorIntensity: Int64 = 0
                        for i in stride(from: 0, to: length-1, by: 4) {
                            // red = ptr[i]; green = ptr[i+1]; blue = ptr[i+2]; alpha = ptr[i+3]
                            let r = Int64(ptr[i])
                            let g = Int64(ptr[i+1])
                            let b = Int64(ptr[i+2])
                            colorIntensity += r + g + b
                        }
                        colorIntensities.append(colorIntensity)
                    }
                    
                    // Averaging the red buckets
                    var averages: [Int64] = []
                    for i in 0...colorIntensities.count-5 {
                        var average: Int64 = 0
                        for j in 0...4 {
                            average += colorIntensities[i + j]
                        }
                        average /= 5
                        averages.append(average)
                    }
                    
                    // Calculating heart rate from the averaged red buckets
                    var count: Int64 = 0, prev = averages[0]
                    for i in 1...averages.count-1 {
                        if abs(averages[i] - prev) > MeasurementConstants.AVERAGE_DIFFERENCE_THRESHOLD {
                            count += 1
                        }
                        prev = averages[i]
                    }
                    let heartRate = (Double(count) / duration.seconds) * 30
                    isProcessing.toggle()
                    if let completion = completion {
                        completion(.success(heartRate))
                    }
                } catch {
                    if let completion = completion {
                        completion(.failure(error))
                    }
                }
            }
        }
        
        private func deleteHeartRateVideo(at videoUrl: URL) -> Void {
            if !defaults.bool(forKey: Keys.IS_DEVELOPER_MODE_ENABLED) {
                try? FileManager.default.removeItem(at: videoUrl)
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoUrl)
            }) { saved, error in
                if let error = error {
                    print(error.localizedDescription)
                }
                else if !saved {
                    print("Error: Unable to save the video!")
                }
                try? FileManager.default.removeItem(at: videoUrl)
            }
        }
        
        func startCaptureSession() -> Void {
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    guard granted else { return }
                    DispatchQueue.main.async {
                        self.setupCaptureSession()
                    }
                }
                break;
            case .authorized:
                setupCaptureSession()
                break
            default:
                print("Camera permissions not available!")
                break
            }
        }
        
        private func setupCaptureSession() -> Void {
            let session = AVCaptureSession()
            session.sessionPreset = AVCaptureSession.Preset.vga640x480
            
            if let device = AVCaptureDevice.default(for: .video) {
                do {
                    let input = try AVCaptureDeviceInput(device: device)
                    if session.canAddInput(input) && session.canAddOutput(output) {
                        session.addInput(input)
                        session.addOutput(output)
                    }
                    previewLayer.videoGravity = .resizeAspectFill
                    previewLayer.session = session
                    
                    // Running session on a background thread as recommended
                    DispatchQueue.global(qos: .background).async {
                        session.startRunning()
                    }
                    self.session = session
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        func stopCaptureSession() -> Void {
            if let running = session?.isRunning {
                if running {
                    session?.removeOutput(output)
                    session?.stopRunning()
                }
            }
        }
        
        nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
            Task { @MainActor in
                if let error = error {
                    if let completion = self.completion {
                        completion(.failure(error))
                    }
                    return
                }
                self.processHeartRateVideo(at: outputFileURL)
            }
        }
        
    }
}
