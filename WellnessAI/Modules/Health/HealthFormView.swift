//
//  HealthFormView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/17/23.
//

import SwiftUI

struct HealthFormView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) var context
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        Form {
            Section("Measurements") {
                HStack {
                    Image(systemName: "heart")
                    Text("Heart Rate")
                    Spacer()
                    if viewModel.heartRate != nil {
                        Text("\(viewModel.heartRate!, specifier: "%.2f") bpm")
                    } else {
                        Text("-- bpm")
                    }
                }
                .background(
                    NavigationLink("", destination: HeartRateMeasurementView(heartRate: $viewModel.heartRate))
                        .opacity(0)
                )
                Button {
                    viewModel.showRespRateTip.toggle()
                } label: {
                    HStack {
                        if viewModel.isMeasuringRespRate {
                            ProgressView()
                            Text(" Measuring Respiratory Rate")
                        }
                        else {
                            Image(systemName: "lungs")
                            Text("Respiratory Rate")
                            Spacer()
                            if viewModel.respRate != nil {
                                Text("\(viewModel.respRate!, specifier: "%.2f") bpm")
                            } else {
                                Text("-- bpm")
                            }
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isMeasuringRespRate)
                .alert("Respiratory Rate Measurement Instructions", isPresented: $viewModel.showRespRateTip) {
                    Button("Cancel", role: .cancel) { }
                    Button("Start Measuring", role: .none) {
                        viewModel.measureRespiratoryRate()
                    }
                } message: {
                    Text("Please lay down facing up. Place the device flat between your chest and stomach. Press the \"Start Measuring\" button and continue to take deep breaths.")
                }
            }
            Section("Symptoms") {
                Picker(selection: $viewModel.selectedSymptomIndex) {
                    ForEach(Array(viewModel.symptoms.enumerated()), id:\.offset) { index, symptom in
                        Text(symptom.name!).tag(index)
                    }
                } label: {
                    Image(systemName: "staroflife")
                    Text("Symptom")
                }
                .pickerStyle(.navigationLink)
                Picker(selection: $viewModel.selectedIntensityValue) {
                    ForEach(Array(viewModel.intensities.keys).sorted(), id:\.self) { key in
                        Text("\(viewModel.intensities[key]!) (\(key))").tag(key)
                    }
                } label: {
                    Image(systemName: "exclamationmark.circle")
                    Text("Intensity")
                }
                .pickerStyle(.navigationLink)
                Button {
                    viewModel.addUserSymptom()
                } label: {
                    HStack {
                        Image(systemName: "plus")
                        Text("Add Symptom")
                    }
                }
            }
            if !viewModel.userSymptoms.isEmpty {
                Section("Recorded Symptoms") {
                    List {
                        ForEach(viewModel.userSymptoms, id:\.self) { userSymptom in
                            HStack {
                                Image(systemName: "staroflife")
                                Text(userSymptom.symptom?.name ?? "Unknown")
                                Spacer()
                                Text("\(userSymptom.intensityLabel!) (\(Int(userSymptom.intensityValue)))")
                            }
                        }
                        .onDelete { indexes in
                            viewModel.removeUserSymptoms(atOffsets: indexes)
                        }
                    }
                }
            }
            
        }
        .navigationTitle("Health")
        .toolbar {
            HStack {
                Button {
                    viewModel.showSaveAlert.toggle()
                    viewModel.saveHealthInformation()
                } label: {
                    Image(systemName: "square.and.arrow.down")
                }
                .alert("Successfully saved your health information.", isPresented: $viewModel.showSaveAlert) {
                    Button("Dismiss", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            viewModel.setup(context: context)
        }
    }
}
