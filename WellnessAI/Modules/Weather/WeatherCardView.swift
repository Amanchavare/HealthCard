//
//  WeatherCardView.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/21/23.
//

import SwiftUI

struct WeatherCardView: View {
    
    @Environment(\.defaultMinListRowHeight) var minRowHeight
    let weather: Weather
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack {
                    Image(systemName: "clock")
                    Text(weather.userSession?.timestamp?.formatted(relativeTo: Date.now) ?? "Unknown")
                }
                Spacer()
                HStack {
                    Image(systemName: "location")
                    Text(weather.locationName ?? "Unknown")
                }
            }
            .fontWeight(.light)
            .padding()
            HStack(alignment: .bottom, spacing: 8) {
                VStack(alignment: .trailing) {
                    Text(weather.weatherMain ?? "Unknown").fontWeight(.bold)
                    Text((weather.weatherDescription ?? "Unknown").capitalized)
                }
                Image(systemName: weather.iconSystemName ?? "questionmark").font(.largeTitle)
                VStack(alignment: .leading) {
                    Text("\(weather.currentTemp, specifier: "%.2f")° C").fontWeight(.bold)
                    Text("Feels like \(weather.feelsLikeTemp, specifier: "%.2f")° C")
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            VStack(alignment: .leading) {
                Section {
                    ForEach(weather.getUIFields(), id:\.label) { field in
                        HStack {
                            Image(systemName: field.icon)
                            Text(field.label)
                            Spacer()
                            field.value
                        }
                        .frame(minHeight: minRowHeight)
                    }
                } header: {
                    Text("Weather Details").fontWeight(.light)
                }
            }
            .padding()
        }
        .background(UIConstants.CARD_BACKGROUND)
        .clipShape(RoundedRectangle(cornerRadius: UIConstants.CORNER_RADIUS))
    }
}

