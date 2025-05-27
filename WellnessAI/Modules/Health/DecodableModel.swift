//
//  DecodableViewModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/22/23.
//

import Foundation

private func decodeJson<T: Decodable>(forResource: String) -> [T] {
    guard let path = Bundle.main.path(forResource: forResource, ofType: "json") else {
        fatalError("Unable to load \(forResource).json!")
    }
    do {
        let data = try Data(contentsOf: URL(filePath: path))
        return try JSONDecoder().decode([T].self, from: data)
    } catch {
        fatalError(error.localizedDescription)
    }
}

struct DecodableSymptom: Decodable, Identifiable {
    let id: Int16
    let name: String
    
    static let symptoms: [DecodableSymptom] = {
        decodeJson(forResource: "symptoms")
    }()
}

struct DecodableIntensity: Decodable {
    let label: String
    let value: Int
    
    static let intensities: [DecodableIntensity] = {
        decodeJson(forResource: "intensities")
    }()
    
    static let map: [Int:String] = {
        var map: [Int:String] = [:]
        for decodableIntensity in DecodableIntensity.intensities {
            map[decodableIntensity.value] = decodableIntensity.label
        }
        return map
    }()
}
