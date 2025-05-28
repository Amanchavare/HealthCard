

import SwiftUI

struct HistoricalHealthCardsView: View {
    
    @ObservedObject var viewModel: HealthCardsView.ViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.userSessions) { userSession in
                NavigationLink {
                    ShareableHealthCardView(userSession: userSession)
                } label: {
                    Image(systemName: "heart.text.square")
                    Text("Health Card from \(userSession.timestamp!.formatted(relativeTo: Date.now))")
                }
            }
        }
        .navigationTitle("History")
    }
}
