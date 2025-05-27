//
//  SummaryCardView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/17/23.
//

import SwiftUI

struct HealthCardView: View {
    
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    let userSession: UserSession
    let dateFormatter: (Date?) -> String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "clock")
                Text(dateFormatter(userSession.timestamp))
            }
            .fontWeight(.light)
            .padding()
            VStack(alignment: .center) {
                HStack {
                    Spacer()
                    VStack {
                        HStack {
                            Image(systemName: "heart")
                            if 
                                let heartRate = userSession.userMeasurement?.heartRate,
                                heartRate > 0
                            {
                                Text("\(heartRate, specifier: "%.2f")")
                            } else {
                                Text("--")
                            }
                        }
                        .fontWeight(.bold)
                        Text("Heart Rate")
                    }
                    Spacer()
                    VStack {
                        HStack {
                            Image(systemName: "lungs")
                            if 
                                let respRate = userSession.userMeasurement?.respRate,
                                respRate > 0
                            {
                                Text("\(respRate, specifier: "%.2f")")
                            } else {
                                Text("--")
                            }
                        }
                        .fontWeight(.bold)
                        Text("Respiratory Rate")
                    }
                    Spacer()
                }
            }
            .padding()
            let userSymptoms = userSession.userSymptoms?.allObjects as! [UserSymptom]
            if !userSymptoms.isEmpty {
                VStack(alignment: .leading) {
                    Section {
                        ForEach(userSymptoms, id: \.self) { userSymptom in
                            HStack(alignment: .center) {
                                Image(systemName: "staroflife")
                                Text(userSymptom.symptom!.name!)
                                Spacer()
                                Text("\(userSymptom.intensityLabel!) (\(Int(userSymptom.intensityValue)))")
                            }
                            .frame(minHeight: minRowHeight)
                        }
                    } header: {
                        Text("Recorded Symptoms").fontWeight(.light)
                    }
                }
                .padding()
            }
        }
        .background(UIConstants.CARD_BACKGROUND)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CORNER_RADIUS))
    }
}
