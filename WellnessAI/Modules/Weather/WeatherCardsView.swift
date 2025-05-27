//
//  WeatherCardsView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/21/23.
//

import SwiftUI

struct WeatherCardsView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "cloud.sun")
                Text("Weather")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if viewModel.isAwaitingAPIResponse {
                        HStack(alignment: .center) {
                            ProgressView()
                        }
                        .controlSize(.large)
                        .padding()
                    }
                    Group {
                        if viewModel.isError {
                            ErrorCardView(errorMessage: viewModel.errorMessage)
                        } else if viewModel.userSessions.isEmpty {
                            LoadingCardView(loadingMessage: "Loading weather information")
                        } else {
                            WeatherCardView(weather: viewModel.userSessions.first!.weather!)
                        }
                    }
                    .frame(width: UIConstants.CARD_FRAME_WIDTH)
                }
            }
        }
    }
}
