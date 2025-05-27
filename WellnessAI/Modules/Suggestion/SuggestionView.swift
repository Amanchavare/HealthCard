//
//  SuggestionView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/16/23.
//

import SwiftUI

struct SuggestionView: View {

    @Environment(\.defaultMinListRowHeight) var minRowHeight
    let suggestion: Suggestion
    let dateFormatter: (Date?) -> String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack {
                    Image(systemName: "clock")
                    Text(dateFormatter(suggestion.userSession?.timestamp))
                }
                Spacer()
                HStack {
                    Image(systemName: "tag")
                    Text(suggestion.source ?? "Unknown")
                }
            }
            .fontWeight(.light)
            .padding()
            HStack {
                Text(suggestion.content ?? "Unable to present suggestion's content!")
            }
            .fontWeight(.bold)
            .frame(maxWidth: .infinity)
            .padding()
            let parameters = suggestion.parameters?.allObjects as! [FineTuneParameter]
            if !parameters.isEmpty {
                Spacer()
                VStack(alignment: .leading) {
                    Section {
                        ForEach(parameters.sorted(by: { $0.label! < $1.label! })) { parameter in
                            HStack(alignment: .center) {
                                Image(systemName: parameter.icon)
                                Text(parameter.label!)
                                Spacer()
                                Text(parameter.value!)
                            }
                            .frame(minHeight: minRowHeight)
                        }
                    } header: {
                        Text("Fine-tune Paramters").fontWeight(.light)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UIConstants.CARD_BACKGROUND)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CORNER_RADIUS))
    }
}

