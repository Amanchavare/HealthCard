//
//  HistoricalSuggestionsCardView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/28/23.
//

import SwiftUI

struct HistoricalSuggestionsCardView: View {
    
    @ObservedObject var viewModel: SuggestionsView.ViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.userSessions) { userSession in
                NavigationLink {
                    ScrollView(.vertical) {
                        VStack {
                            let suggestions = userSession.suggestions?.allObjects as? [Suggestion]
                            if let suggestions = suggestions {
                                ForEach(suggestions) { suggestion in
                                    SuggestionView(suggestion: suggestion, dateFormatter: { $0?.formatted() ?? "" })
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    .navigationTitle("Suggestions")
                } label: {
                    Image(systemName: "wand.and.stars")
                    Text("Suggestions from \(userSession.timestamp!.formatted(relativeTo: Date.now))")
                }
            }
        }
        .navigationTitle("History")
    }
}

