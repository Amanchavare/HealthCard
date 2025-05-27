//
//  SuggestionsViewModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/27/23.
//

import Foundation
import CoreLocation
import CoreData
import EventKit

extension SuggestionsView {
    @MainActor class ViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
        
        private var context: NSManagedObjectContext?
        private var locationManager: CLLocationManager?
        private let eventStore: EKEventStore = EKEventStore()
        
        @Published private(set) var hasCalendarAccess: Bool = false
        @Published private(set) var isUpdatingSuggestions: Bool = false
        @Published private(set) var errorMessage: String? = nil
        @Published private(set) var userSessions: [UserSession] = []
        
        private var hospital: GoogleNearbyPlace? = nil
        private var mall: GoogleNearbyPlace? = nil
        private var weather: Weather? = nil
        
        var isError: Bool {
            return !(errorMessage ?? "").isEmpty
        }
        
        var suggestions: [Suggestion] {
            guard
                let userSession = userSessions.first,
                let set = userSession.suggestions,
                let suggestions = set.allObjects as? [Suggestion]
            else {
                return []
            }
            return suggestions
        }
        
        override init() {
            super.init()
            requestFullAccesstoCalendarEvents()
        }
        
        func refreshSuggestions(context: NSManagedObjectContext, force: Bool = false) -> Void {
            guard hasCalendarAccess else { return }
            self.context = context
            errorMessage = nil
            
            // Loading sessions with suggestions from database
            setUserSessionsWithSuggestions()
            
            if shouldCallOpenWeatherAPI(force: force) {
                locationManager = CLLocationManager()
                locationManager?.delegate = self
                locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                locationManager?.requestWhenInUseAuthorization()
            }
        }
        
        private func shouldCallOpenWeatherAPI(force: Bool) -> Bool {
            if isUpdatingSuggestions { return false }
            if userSessions.isEmpty { return true }
            let userSession = userSessions.first
            let timestamp = userSession?.timestamp ?? Date.now
            let timeout = force ? APIConstants.API_THROTTLING_FORCE_TIMEOUT : APIConstants.API_THROTTLING_REGULAR_TIMEOUT
            return abs(Int(timestamp.timeIntervalSinceNow)) > timeout
        }
        
        nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            Task { @MainActor in
                switch status {
                case .authorized:
                    fallthrough
                case .authorizedAlways:
                    fallthrough
                case .authorizedWhenInUse:
                    locationManager?.startUpdatingLocation()
                    break
                default:
                    errorMessage = "Unable to access your location!"
                }
            }
        }
        
        nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let currentLocation = locations.last else { return }
            manager.stopUpdatingLocation()
            Task { @MainActor in
                guard !isUpdatingSuggestions else { return }
                isUpdatingSuggestions = true
                do {
                    defer {
                        isUpdatingSuggestions = false
                    }
                    try await setNearbyPlacesAndWeather(currentLocation)
                    try await saveSuggestions()
                    setUserSessionsWithSuggestions()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        private func saveSuggestions() async throws -> Void {
            guard let context = context else { return }
            
            // Clearing old suggestions in current user session
            let userSession = UserSession.getCurrent(context: context)
            userSession.suggestions = []
            try context.save()
            
            // Generating suggestions from events
            let events = eventStore.upcomingEvents()
            await saveSuggestions(forEvents: events)
            
            // Generating suggestions from health cards
            let userSessions = getUserSessionsWithHealthInformation()
            await saveSuggestions(forHealthInformationIn: userSessions)
        }
        
        private func saveSuggestions(forEvents events: [EKEvent]) async -> Void {
            // Saving suggestion for empty calendar and well-being
            await saveSuggestion(forNoEvents: events)
            
            // Saving suggestion from the upcoming event
            await saveSuggestion(forUpcomingEvent: events.first)
            
            // Adding suggestion if busy week
            await saveSuggestion(forManyEvents: events)
        }
        
        private func saveSuggestions(forHealthInformationIn userSessions: [UserSession]) async -> Void {
            // Saving suggestions with stale or no health information
            await saveSuggestion(forStaleOrNoHealthInformationIn: userSessions)
            
            // Saving suggestions if persistent symptoms persists
            await saveSuggestion(forSymptomsIn: userSessions)
            
            // Saving suggestions if abnormal measurements are detected
            await saveSuggestion(forMeasurementsIn: userSessions)
        }
        
        private func saveSuggestion(forNoEvents events: [EKEvent]?) async -> Void {
            guard
                let events = events,
                events.isEmpty,
                let context = context,
                let response = try? await ChatGPTAPIRequest.emptyCalendarRequest(weather: weather).fetch(),
                let content = response.getContent()
            else { return }
            let suggestion = Suggestion.fromCalendar(context: context, content: content)
            if let weather = weather {
                [
                    FineTuneParameter.ofWeather(context: context, weather: weather),
                    FineTuneParameter.ofEmptyCalendar(context: context)
                ].forEach { $0.suggestion = suggestion }
            }
            try? context.save()
        }
        
        private func saveSuggestion(forUpcomingEvent event: EKEvent?) async -> Void {
            guard let context = context, let event = event else { return }
            do {
                if
                    let response = try await ChatGPTAPIRequest.classifyRequest(ofEvent: event)?.fetch(),
                    let classification = response.getClassification()
                {
                    var request: ChatGPTAPIRequest? = nil
                    var parameters: [FineTuneParameter] = [FineTuneParameter.ofCalendar(context: context, event: event)]
                    switch classification {
                    case .Celebration:
                        request = ChatGPTAPIRequest.shoppingRequest(forEvent: event, atPlace: mall, weather: weather)
                        if let mall = mall { parameters.append(FineTuneParameter.ofPlace(context: context, place: mall)) }
                        if let weather = weather { parameters.append(FineTuneParameter.ofWeather(context: context, weather: weather)) }
                        break
                    case .Health:
                        request = ChatGPTAPIRequest.healthRequest(forEvent: event, atPlace: hospital, weather: weather)
                        if let hospital = hospital { parameters.append(FineTuneParameter.ofPlace(context: context, place: hospital)) }
                        if let weather = weather { parameters.append(FineTuneParameter.ofWeather(context: context, weather: weather)) }
                        break
                    case .Work:
                        break
                    case .Personal:
                        break
                    }
                    if let request = request, let content = try await request.fetch().getContent() {
                        let suggestion = Suggestion.fromCalendar(context: context, content: content)
                        parameters.forEach { $0.suggestion = suggestion }
                        try context.save()
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        private func saveSuggestion(forManyEvents events: [EKEvent]) async -> Void {
            guard
                let context = context,
                events.count > SuggestionConstants.BUSY_WEEK_EVENTS_COUNT,
                let response = try? await ChatGPTAPIRequest.busyCalendarRequest(events: events).fetch(),
                let content = response.getContent()
            else { return }
            let suggestion = Suggestion.fromCalendar(context: context, content: content)
            [FineTuneParameter.ofBusyCalendar(context: context, events: events)].forEach { $0.suggestion = suggestion }
            try? context.save()
        }
        
        private func saveSuggestion(forStaleOrNoHealthInformationIn userSessions: [UserSession]) async -> Void {
            if
                !userSessions.isEmpty,
                let userSession = userSessions.first,
                let timestamp = userSession.timestamp,
                abs(Int(timestamp.timeIntervalSinceNow)) < SuggestionConstants.STALE_HEALTH_TIME_INTERVAL
            { return }
            let userSession: UserSession? = userSessions.isEmpty ? nil : userSessions.first
            guard
                let context = context,
                let response = try? await ChatGPTAPIRequest.staleHealthInformationRequest(userSession: userSession).fetch(),
                let content = response.getContent()
            else { return }
            let suggestion = Suggestion.fromHealth(context: context, content: content)
            [FineTuneParameter.ofStaleHealthInformation(context: context, userSession: userSession)].forEach { $0.suggestion = suggestion }
            try? context.save()
        }
        
        private func saveSuggestion(forSymptomsIn userSessions: [UserSession]) async -> Void {
            guard let context = context, !userSessions.isEmpty else { return }
            
            // Finding all registered symptoms and their frequency and intensities
            var reduce: [Symptom:[UserSymptom]] = [:]
            userSessions
                .filter { abs(Int($0.timestamp!.timeIntervalSinceNow)) < SuggestionConstants.HEALTH_PAST_LOOKUP_TIME_INTERVAL }
                .filter { !($0.userSymptoms?.allObjects.isEmpty ?? true) }
                .forEach({ userSession in
                    if let set = userSession.userSymptoms, let userSymptoms = set.allObjects as? [UserSymptom] {
                        for userSymptom in userSymptoms {
                            guard let symptom = userSymptom.symptom else { continue }
                            var values = reduce[symptom] ?? []
                            values.append(userSymptom)
                            reduce[symptom] = values
                        }
                    }
                })
            
            // Finding out prominent symptoms
            var prominentSymptoms: [Symptom] = []
            for entry in reduce {
                let count = entry.value.count
                let total = entry.value.reduce(0, { $0 + Double($1.intensityValue) })
                if
                    count >= SuggestionConstants.SYMPTOM_COUNT_THRESHOLD,
                    (total / Double(count)) >= SuggestionConstants.SYMPTOM_AVERAGE_INTENSITY_THRESHOLD
                { prominentSymptoms.append(entry.key) }
            }
            
            guard
                !prominentSymptoms.isEmpty,
                let request = ChatGPTAPIRequest.symptomRequest(for: prominentSymptoms, hospital: hospital, weather: weather),
                let response = try? await request.fetch(),
                let content = response.getContent()
            else { return }
            
            let suggestion = Suggestion.fromHealth(context: context, content: content)
            var parameters = prominentSymptoms.map { FineTuneParameter.ofSymptom(context: context, symptom: $0) }
            if let hospital = hospital { parameters.append(FineTuneParameter.ofPlace(context: context, place: hospital)) }
            if let weather = weather { parameters.append(FineTuneParameter.ofWeather(context: context, weather: weather)) }
            parameters.forEach { $0.suggestion = suggestion }
            try? context.save()
        }
        
        private func saveSuggestion(forMeasurementsIn userSessions: [UserSession]) async -> Void {
            guard let context = context, !userSessions.isEmpty else { return }
            
            // Filtering latest user measurements
            let measurements = userSessions
                .filter { abs(Int($0.timestamp!.timeIntervalSinceNow)) < SuggestionConstants.HEALTH_PAST_LOOKUP_TIME_INTERVAL }
                .filter { $0.userMeasurement != nil }
                .map { $0.userMeasurement! }
     
            // Preparing individual heart and respiratory rate measurements
            var heartRateMeasurements = measurements.filter { $0.heartRate > 0 }
            var respRateMeasurements = measurements.filter { $0.respRate > 0 }
            if heartRateMeasurements.count < SuggestionConstants.MEASUREMENT_COUNT_THRESHOLD { heartRateMeasurements = [] }
            if respRateMeasurements.count < SuggestionConstants.MEASUREMENT_COUNT_THRESHOLD { respRateMeasurements = [] }
            
            // Checking if measurements are abnormal
            guard
                let isAbnormalRequest = ChatGPTAPIRequest.isAbnormalRequest(forHeartRates: heartRateMeasurements, forRespRates: respRateMeasurements),
                let isAbnormalResponse = try? await isAbnormalRequest.fetch(),
                let abnormalMeasuremnt = isAbnormalResponse.getAbnormalMeasurement(),
                let measurementRequest = ChatGPTAPIRequest.measurementRequest(for: abnormalMeasuremnt, hosiptal: hospital, weather: weather),
                let measurementResponse = try? await measurementRequest.fetch(),
                let content = measurementResponse.getContent()
            else { return }
            
            let suggestion = Suggestion.fromHealth(context: context, content: content)
            var parameters: [FineTuneParameter] = []
            if abnormalMeasuremnt.heartRate { parameters.append(FineTuneParameter.ofHeartRate(context: context)) }
            if abnormalMeasuremnt.respRate { parameters.append(FineTuneParameter.ofRespRate(context: context)) }
            if let hospital = hospital { parameters.append(FineTuneParameter.ofPlace(context: context, place: hospital)) }
            if let weather = weather { parameters.append(FineTuneParameter.ofWeather(context: context, weather: weather)) }
            parameters.forEach { $0.suggestion = suggestion }
            try? context.save()
        }
        
        private func setUserSessionsWithSuggestions() -> Void {
            do {
                userSessions = try context!.fetch(UserSession.fetchWithSuggestionsRequest())
            } catch {
                userSessions = []
                errorMessage = error.localizedDescription
            }
        }
        
        private func setNearbyPlacesAndWeather(_ location: CLLocation) async throws -> Void {
            let hospitals = try await GoogleNearbyPlacesRequest(location: location, type: .hospital).fetch()
            let malls = try await GoogleNearbyPlacesRequest(location: location, type: .shopping_mall).fetch()
            await MainActor.run {
                self.hospital = GoogleNearbyPlace.getBestPlace(from: hospitals)
                self.mall = GoogleNearbyPlace.getBestPlace(from: malls)
                self.weather = getLatestWeather(location: location)
            }
        }
        
        private func getUserSessionsWithHealthInformation() -> [UserSession] {
            guard let context = context else { return [] }
            return (try? context.fetch(UserSession.fetchWithHealthRequest())) ?? []
        }
        
        private func getLatestWeather(location: CLLocation) -> Weather? {
            // Checking if weather is a) not too old b) roughly same coordinates
            guard
                let context = context,
                let userSessions = try? context.fetch(UserSession.fetchWithWeatherRequest()),
                let userSession = userSessions.first,
                userSession.timestamp! > (Date.now - SuggestionConstants.STALE_WEATHER_TIME_INTERVAL),
                let weather = userSession.weather,
                abs(weather.latitude - location.coordinate.latitude) < 0.5,
                abs(weather.longitude - location.coordinate.longitude) < 0.5
            else { return nil }
            return weather
        }
        
        private func requestFullAccesstoCalendarEvents() -> Void {
            switch EKEventStore.authorizationStatus(for: .event) {
            case .notDetermined:
                Task {
                    var granted = false
                    do { granted = try await eventStore.requestFullAccessToEvents() } catch { granted = false }
                    if !granted {
                        await MainActor.run {
                            errorMessage = "Permissions denied to access your calendar!"
                        }
                    }
                }
            case .fullAccess:
                self.hasCalendarAccess = true
                break
            default:
                errorMessage = "Permissions denied to access your calendar!"
            }
        }
        
    }
}
