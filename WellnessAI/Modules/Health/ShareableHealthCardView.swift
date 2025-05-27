//
//  ShareableHealthCardView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/20/23.
//

import SwiftUI

struct ShareableHealthCardView: View {
    
    let userSession: UserSession
    @State private var image: Image?
    
    var card: some View {
        HealthCardView(userSession: userSession, dateFormatter: { $0?.formatted() ?? "" })
            .padding(.horizontal)
    }
    
    var body: some View {
        ScrollView(.vertical) {
            card.onAppear {
                if image == nil {
                    image = Image(uiImage: card.snapshot())
                }
            }
        }
        .navigationTitle("Health Card")
        .toolbar {
            if image != nil {
                ShareLink(item: image!, preview: SharePreview(userSession.uuid!, image: image!)) {
                    Label("", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}
