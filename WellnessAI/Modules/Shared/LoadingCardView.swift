

import SwiftUI

struct LoadingCardView: View {
    var loadingMessage: String?
    var body: some View {
        VStack {
            ProgressView {
                Text(loadingMessage ?? "Loading Information").fontWeight(.bold)
            }
            .controlSize(.extraLarge)
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(UIConstants.CARD_BACKGROUND)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CORNER_RADIUS))
    }
}

#Preview {
    LoadingCardView()
}
