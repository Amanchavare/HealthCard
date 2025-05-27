//
//  HealthCardsView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/17/23.
//

import SwiftUI

struct HealthCardsView: View {
    
    @Environment(\.managedObjectContext) var context
    @StateObject private var viewModel = ViewModel()
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "heart.text.square")
                Text("Health")
                if !viewModel.userSessions.isEmpty {
                    Spacer()
                    NavigationLink {
                        HistoricalHealthCardsView(viewModel: viewModel)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    if let userSession = viewModel.userSessions.first {
                        HealthCardView(userSession: userSession, dateFormatter: { $0?.formatted(relativeTo: Date.now) ?? "" })
                            .frame(width: UIConstants.CARD_FRAME_WIDTH)
                    }
                    NavigationLink {
                        HealthFormView()
                    } label: {
                        AddHealthCardView()
                    }
                    .frame(width: UIConstants.CARD_FRAME_WIDTH)
                    .frame(maxHeight: .infinity)
                }
                .fixedSize(horizontal: false, vertical: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
            }
            .onAppear {
                viewModel.setup(context: context)
            }
        }
    }
}
