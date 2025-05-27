//
//  Constants.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/18/23.
//

import SwiftUI

struct Keys {
    static let APPLICATION_NAME = "WellnessAI"
    static let LAST_USER_SESSSION = "lastUserSession"
    static let IS_DEVELOPER_MODE_ENABLED = "isDeveloperModeEnabled"
    static let GOOGLE_NEARBY_PLACES_API_KEY_IDENTIFIER = "googleAPIKey"
    static let OPEN_WEATHER_API_KEY_IDENTIFIER = "openWeatherKey"
    static let OPEN_AI_API_KEY_IDENTIFIER = "openAIKey"
    
    private init() {}
}

struct MeasurementConstants {
    static let MAX_TIME_DURATION = 45
    static let STARTING_FRAME_COUNT = 10
    static let FRAME_INTERVAL = 5
    static let AVERAGE_DIFFERENCE_THRESHOLD = 210_000
    static let ACCELEROMETER_INTERVAL = 0.1
    static let ACCELEROMETER_DIFFERENCE_THRESHOLD = 0.15
    
    private init() {}
}

struct APIConstants {
    static let API_THROTTLING_REGULAR_TIMEOUT = 30 * 60
    static let API_THROTTLING_FORCE_TIMEOUT = 60
    static let GOOGLE_NEARBY_PLACES_RADIUS = 5_000
    static let OPEN_WEATHER_UNITS = "metric"
    static let CHAT_GPT_MODEL = "gpt-3.5-turbo"
    static let CHAT_GPT_MODEL_TEMPERATURE = 0.7
    
    private init() {}
}

struct WeatherConstants {
    static let ICON_TO_SYSTEM_NAME_MAPPING = [
        "01d": "sun.max.fill",
        "01n": "moon.fill",
        "02d": "cloud.sun.fill",
        "02n": "cloud.moon.fill",
        "03d": "cloud.fill",
        "03n": "cloud.fill",
        "04d": "smoke.fill",
        "04n": "smoke.fill",
        "09d": "cloud.rain.fill",
        "09n": "cloud.rain.fill",
        "10d": "cloud.rain.fill",
        "10n": "cloud.rain.fill",
        "11d": "cloud.bolt.rain.fill",
        "11n": "cloud.bolt.rain.fill",
        "13d": "snowflake",
        "13n": "snowflake",
        "50d": "sun.haze.fill",
        "50n": "moon.haze.fill"
    ]
    
    static func getSystemName(forIcon: String) -> String? {
        return WeatherConstants.ICON_TO_SYSTEM_NAME_MAPPING[forIcon]
    }
    
    private init() {}
}

struct CalendarConstants {
    static let EVENTS_FUTURE_LOOKUP_TIME_INTERVAL: TimeInterval = 7 * 24 * 3600
    
    private init() {}
}

struct SuggestionConstants {
    static let STALE_WEATHER_TIME_INTERVAL: TimeInterval = 3600
    static let BUSY_WEEK_EVENTS_COUNT = 10
    static let STALE_HEALTH_TIME_INTERVAL = 24 * 3600
    static let HEALTH_PAST_LOOKUP_TIME_INTERVAL = 7 * 24 * 3600
    static let SYMPTOM_COUNT_THRESHOLD = 5
    static let SYMPTOM_AVERAGE_INTENSITY_THRESHOLD = 3.0
    static let MEASUREMENT_COUNT_THRESHOLD = 5
    
    private init() {}
}

struct UIConstants {
    static let CORNER_RADIUS: CGFloat = 10
    static let CARD_FRAME_WIDTH: CGFloat = 320
    static let CARD_BACKGROUND = LinearGradient(colors: [.accentColor, Color(uiColor: .systemBackground)], startPoint: .topLeading, endPoint: .bottomTrailing)
    
    private init() {}
}
