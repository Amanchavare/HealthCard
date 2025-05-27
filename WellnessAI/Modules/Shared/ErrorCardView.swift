//
//  ErrorCardView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/27/23.
//

import SwiftUI

struct ErrorCardView: View {
    var errorMessage: String?
    var body: some View {
        Group {
            HStack(alignment: .center) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("Something went wrong!").fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    Text(errorMessage ?? "Please try again later.")
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity)
        .background(UIConstants.CARD_BACKGROUND)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CORNER_RADIUS))
    }
}

#Preview {
    ErrorCardView()
}
