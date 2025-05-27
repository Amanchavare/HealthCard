//
//  ChatGPTModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/27/23.
//

import Foundation
import EventKit

enum EventClassification: String, CaseIterable {
    case Celebration
    case Health
    case Work
    case Personal
}

struct ChatGPTAPIRequest: Encodable {
    let model: String
    let messages: [ChatGPTAPIResponseChoiceMessage]
    let temperature: Double
    
    init(prompt: String) {
        model = APIConstants.CHAT_GPT_MODEL
        messages = [ChatGPTAPIResponseChoiceMessage(role: "user", content: prompt)]
        temperature = APIConstants.CHAT_GPT_MODEL_TEMPERATURE
    }
    
}

struct ChatGPTAPIResponse: Decodable {
    let choices: [ChatGPTAPIResponseChoice]?
}

struct ChatGPTAPIResponseChoice: Decodable {
    let message: ChatGPTAPIResponseChoiceMessage?
}

struct ChatGPTAPIResponseChoiceMessage: Codable {
    let role: String?
    let content: String?
}

extension ChatGPTAPIResponse {
    
    struct AbnormalMeasurement: Decodable {
        let heartRate: Bool
        let respRate: Bool
    }
    
    func getContent() -> String? {
        guard
            let choices = choices,
            let choice = choices.first,
            let message = choice.message,
            let content = message.content
        else {
            return nil
        }
        return content
    }
    
    func isValid() -> Bool {
        return !(getContent() ?? "").isEmpty
    }
    
    func getClassification() -> EventClassification? {
        guard
            let content = getContent(),
            let trim = content.split(separator: ": ").last,
            let classification = EventClassification(rawValue: String(trim))
        else {
            return nil
        }
        return classification
    }
    
    func getAbnormalMeasurement() -> AbnormalMeasurement? {
        guard let content = getContent() else { return nil }
        do {
            let data = Data(content.utf8)
            return try JSONDecoder().decode(AbnormalMeasurement.self, from: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
}

extension ChatGPTAPIRequest {
    
    func fetch() async throws -> ChatGPTAPIResponse {
        let apiKey = UserDefaults.standard.string(forKey: Keys.OPEN_AI_API_KEY_IDENTIFIER)
        guard !(apiKey ?? "").isEmpty else { throw AppError.openAIAPIKeyMissing }
        
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey!)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(self)
        
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        guard
            let httpResponse = urlResponse as? HTTPURLResponse,
            httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(ChatGPTAPIResponse.self, from: data)
        guard apiResponse.isValid() else { throw URLError(.badServerResponse) }
        return apiResponse
    }
    
    static func classifyRequest(ofEvent event: EKEvent) -> ChatGPTAPIRequest? {
        guard let title = event.title else { return nil }
        let prompt = [
            "Classify \"\(title)\" calendar event into the following categories -",
            Array(EventClassification.allCases).map { "\"\($0.rawValue)\"" }.joined(separator: ", "),
            "\nAnswer in this format - \n\"Category: [INSERT CATEGORY HERE]\""
        ].joined(separator: " ")
        return ChatGPTAPIRequest(prompt: prompt)
    }
    
    static func shoppingRequest(forEvent event: EKEvent, atPlace place: GoogleNearbyPlace?, weather: Weather?) -> ChatGPTAPIRequest? {
        guard let title = event.title else { return nil }
        var prompts = [
            "Write one liner notification for a user with an upcoming \"\(title)\" celebration event on their calendar.",
        ]
        if let place = place {
            prompts.append("You may suggest the user to shop at \(place.name) if they want to. This shop is near them based on the device's location")
        }
        if let weather = weather, let main = weather.weatherMain, let desc = weather.weatherDescription {
            prompts.append("The weather at user's place is described as \"\(main) (\(desc)\"")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func healthRequest(forEvent event: EKEvent, atPlace place: GoogleNearbyPlace?, weather: Weather?) -> ChatGPTAPIRequest? {
        guard let title = event.title else { return nil }
        var prompts = [
            "Write one liner notification for a user with an upcoming \"\(title)\" health-related event on their calendar.",
        ]
        if let place = place {
            prompts.append("You may suggest the user to check-up at \(place.name) if they want to. This hospital is near them based on the device's location")
        }
        if let weather = weather, let main = weather.weatherMain, let desc = weather.weatherDescription {
            prompts.append("The weather at user's place is described as \"\(main) (\(desc)\"")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func emptyCalendarRequest(weather: Weather?) -> ChatGPTAPIRequest {
        var prompts = [
            "Write one liner notification for a user with no upcoming calendar events for the next week.",
            "You may suggest the user to take a break and focus on their well-being."
        ]
        if let weather = weather, let main = weather.weatherMain, let desc = weather.weatherDescription {
            prompts.append("The weather at user's place is described as \"\(main) (\(desc)\"")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func busyCalendarRequest(events: [EKEvent]) -> ChatGPTAPIRequest {
        let prompt = [
            "Write one liner notification for a user with a busy calendar.",
            "The user has \(events.count) calendar events for the next week.",
            "You may suggest the user to take care of their well-being."
        ].joined(separator: " ")
        return ChatGPTAPIRequest(prompt: prompt)
    }
    
    static func staleHealthInformationRequest(userSession: UserSession?) -> ChatGPTAPIRequest {
        var prompts = [
            "Write one liner notification for a user",
            "who didn't measure their heart rate, respiratory rate, or recorded symptoms",
            "using the application's built in measurement features",
        ]
        if let userSession = userSession, let timestamp = userSession.timestamp {
            prompts.append("in a long time.")
            prompts.append("The user last updated their health information \(timestamp.formatted(relativeTo: Date.now))")
        } else {
            prompts.append("ever.")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func symptomRequest(for symptoms: [Symptom], hospital: GoogleNearbyPlace?, weather: Weather?) -> ChatGPTAPIRequest? {
        guard !symptoms.isEmpty else { return nil }
        let names = symptoms.map { $0.name! }.joined(separator: ", ")
        var prompts = [
            "Write one liner notification for a user",
            "who has been suffering from \(names) symptoms for some while now.",
        ]
        if let hospital = hospital {
            prompts.append("You may recommend them to get themselves checked at \(hospital.name)")
            prompts.append("located near them based on their device's location.")
        } else {
            prompts.append("You may recommend them to take care of themselves and see a doctor, if needed.")
        }
        if let weather = weather, let main = weather.weatherMain, let desc = weather.weatherDescription {
            prompts.append("The weather at user's place is described as \"\(main) (\(desc)\"")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func isAbnormalRequest(
        forHeartRates heartRateMeasurements: [UserMeasurement],
        forRespRates respRateMeasurements: [UserMeasurement]
    ) -> ChatGPTAPIRequest? {
        if heartRateMeasurements.isEmpty && respRateMeasurements.isEmpty { return nil }
        let heartRates = heartRateMeasurements.filter { $0.heartRate > 0 }.map { "\($0.heartRate) bpm" }.joined(separator: ", ")
        let respRates = respRateMeasurements.filter { $0.respRate > 0 }.map { "\($0.respRate) bpm" }.joined(separator: ", ")
        if heartRates.isEmpty && respRates.isEmpty { return nil }
        var prompts = [
            "Following are the heart and respiratory rates of a user measured recently.",
            "Based on these, will you recommend user schedule medical check-up?",
            "\nAnswer in this JSON format: { \"heartRate\": true/false, \"respRate\": true/false }",
            "Here if heart rates are abnormal, then heartRate: true, otherwise heartRate: false,",
            "similarly if respiratory rates are abnormal, then respRate: true, otherwise respRate: false",
        ]
        if !heartRates.isEmpty { prompts.append("\nHeart rates (beats per minute) - \(heartRates)") }
        if !respRates.isEmpty { prompts.append("\nRespiratory rates (breadths per minute) - \(respRates)") }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
    static func measurementRequest(
        for abnormalMeasurement: ChatGPTAPIResponse.AbnormalMeasurement?,
        hosiptal: GoogleNearbyPlace?,
        weather: Weather?
    ) -> ChatGPTAPIRequest? {
        guard
            let abnormalMeasurement = abnormalMeasurement,
            (abnormalMeasurement.heartRate || abnormalMeasurement.respRate)
        else { return nil }
        var prompts = [ "Write one liner notification for a user who has been suffering from" ]
        if abnormalMeasurement.heartRate && abnormalMeasurement.respRate {
            prompts.append("both abnormal heart and respiratory rates recently.")
        } else if abnormalMeasurement.heartRate {
            prompts.append("abnormal heart rates recently.")
        } else {
            prompts.append("abnormal respiratory rates recently.")
        }
        if let hosiptal = hosiptal {
            prompts.append("You may suggest them to seek medical check-up at \(hosiptal.name) which is located near them.")
        } else {
            prompts.append("You may suggest them to seek medical check-up.")
        }
        if let weather = weather, let main = weather.weatherMain, let desc = weather.weatherDescription {
            prompts.append("The weather at user's place is described as \"\(main) (\(desc)\"")
        }
        return ChatGPTAPIRequest(prompt: prompts.joined(separator: " "))
    }
    
}
