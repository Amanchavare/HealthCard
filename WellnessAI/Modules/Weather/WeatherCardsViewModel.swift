//
//  WeatherCardsViewModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/21/23.
//

import Foundation
import CoreLocation
import CoreData

extension WeatherCardsView {
    @MainActor class ViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
        
        private var context: NSManagedObjectContext?
        private var locationManager: CLLocationManager?
        
        @Published private(set) var errorMessage: String? = nil
        @Published private(set) var userSessions: [UserSession] = []
        @Published private(set) var isAwaitingAPIResponse: Bool = false
        
        var isError: Bool {
            return !(errorMessage ?? "").isEmpty
        }
        
        func refreshWeatherInformation(context: NSManagedObjectContext, force: Bool = false) -> Void {
            self.context = context
            self.errorMessage = nil
            
            // Loading weather sessions from database
            setUserSessionsWithWeather()
            
            if shouldCallOpenWeatherAPI(force: force) {
                locationManager = CLLocationManager()
                locationManager?.delegate = self
                locationManager?.desiredAccuracy = kCLLocationAccuracyBest
                locationManager?.requestWhenInUseAuthorization()
            }
        }
        
        private func shouldCallOpenWeatherAPI(force: Bool) -> Bool {
            if isAwaitingAPIResponse { return false }
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
                guard !isAwaitingAPIResponse else { return }
                isAwaitingAPIResponse = true
                do {
                    defer {
                        isAwaitingAPIResponse = false
                    }
                    let response = try await OpenWeatherAPIRequest(location: currentLocation).fetch()
                    saveWeather(from: response)
                    setUserSessionsWithWeather()
                } catch {
                    errorMessage = error.localizedDescription
                }
            }
        }
        
        private func saveWeather(from response: OpenWeatherAPIResponse) -> Void {
            guard let context = context else { return }
            
            // Converting response to CoreData entity
            let weather = response.toWeather(context: context)
            
            // Connecting weather entity to session and persisting
            weather.userSession = UserSession.getCurrent(context: context)
            try? context.save()
        }
        
        private func setUserSessionsWithWeather() -> Void {
            guard let context = context else { return }
            
            var userSessions: [UserSession] = []
            for userSession in try! context.fetch(UserSession.fetchWithWeatherRequest()) {
                userSessions.append(userSession)
            }
            self.userSessions = userSessions
        }
        
    }
}
