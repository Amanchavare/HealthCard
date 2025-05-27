//
//  HomeView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/16/23.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    
    @Environment(\.managedObjectContext) private var context
    @StateObject private var suggestionsViewModel = SuggestionsView.ViewModel()
    @StateObject private var weatherViewModel = WeatherCardsView.ViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    SuggestionsView(viewModel: suggestionsViewModel).padding()
                    HealthCardsView().padding()
                    WeatherCardsView(viewModel: weatherViewModel).padding()
                }
            }
            .navigationTitle("WellnessAI")
            .onAppear {
                weatherViewModel.refreshWeatherInformation(context: context)
                suggestionsViewModel.refreshSuggestions(context: context)
            }
            .refreshable {
                weatherViewModel.refreshWeatherInformation(context: context, force: true)
                suggestionsViewModel.refreshSuggestions(context: context, force: true)
            }
        }
    }
}

