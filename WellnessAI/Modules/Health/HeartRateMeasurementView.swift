//
//  HeartRateMeasurementView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/20/23.
//

import SwiftUI
import AVFoundation

struct HeartRateMeasurementView: View {
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ViewModel()
    @Binding var heartRate: Double?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                CameraPreviewView(previewLayer: viewModel.previewLayer)
                VStack {
                    if let overlayMessage = viewModel.overlayMessage {
                        Spacer()
                        ProgressView {
                            Text(overlayMessage)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .controlSize(.large)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        Spacer()
                    }
                }
                .padding()
            }
            .alert("Heart Rate Measurement Instructions", isPresented: $viewModel.showHeartRateTip) {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Start Measuring", role: .none) {
                    viewModel.recordHeartRateVideo { result in
                        switch result {
                        case .success(let heartRate):
                            self.heartRate = heartRate
                        case .failure(let error):
                            print(error.localizedDescription)
                        }
                        dismiss()
                    }
                }
            } message: {
                Text("Please ensure that you are in a well-lit area. Cover the back camera lens gently with your index finger. Point the camera lens towards a light source.")
            }
        }
        .navigationTitle("Heart Rate")
        .onAppear {
            viewModel.showHeartRateTip = true
            viewModel.startCaptureSession()
        }
        .onDisappear {
            viewModel.showHeartRateTip = false
            viewModel.stopCaptureSession()
        }
    }
    
    private struct CameraPreviewView: UIViewControllerRepresentable {
        typealias UIViewControllerType = UIViewController
        
        let previewLayer: AVCaptureVideoPreviewLayer
        
        func makeUIViewController(context: Context) -> UIViewController {
            let viewController = UIViewController()
            viewController.view.backgroundColor = .black
            viewController.view.layer.addSublayer(previewLayer)
            previewLayer.frame = viewController.view.bounds
            return viewController
        }
        
        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {

        }
        
        static func dismantleUIViewController(_ uiViewController: UIViewController, coordinator: ()) {
            
        }
        
    }
    
}
