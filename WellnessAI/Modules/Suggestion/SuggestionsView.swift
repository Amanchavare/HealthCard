//
//  SuggestionsView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/16/23.
//

import SwiftUI

struct SuggestionsView: View {
    
    @ObservedObject var viewModel: ViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "wand.and.stars")
                Text("AI Suggestions")
                if !viewModel.userSessions.isEmpty {
                    Spacer()
                    NavigationLink {
                        HistoricalSuggestionsCardView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top) {
                    if viewModel.isError {
                        ErrorCardView(errorMessage: viewModel.errorMessage).frame(width: UIConstants.CARD_FRAME_WIDTH)
                    } else if viewModel.suggestions.isEmpty {
                        LoadingCardView(loadingMessage: "Loading suggestions").frame(width: UIConstants.CARD_FRAME_WIDTH)
                    } else {
                        if viewModel.isUpdatingSuggestions {
                            HStack(alignment: .center) {
                                ProgressView()
                            }
                            .frame(maxHeight: .infinity)
                            .controlSize(.large)
                            .padding()
                        }
                        ForEach(viewModel.suggestions) { suggestion in
                            SuggestionView(suggestion: suggestion, dateFormatter: { $0?.formatted(relativeTo: Date.now) ?? "" })
                        }
                        .frame(width: UIConstants.CARD_FRAME_WIDTH)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
