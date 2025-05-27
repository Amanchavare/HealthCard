//
//  Extensions.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/21/23.
//

import SwiftUI
import CoreData
import EventKit

extension View {
    
    func snapshot() -> UIImage {
        let controller = UIHostingController(rootView: self)
        let view = controller.view
    
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
            
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear
            
        let window = UIWindow(frame: view!.bounds)
        window.addSubview(controller.view)
        window.makeKeyAndVisible()
            
        let renderer = UIGraphicsImageRenderer(bounds: view!.bounds, format: format)
        return renderer.image { rendererContext in
            view?.layer.render(in: rendererContext.cgContext)
        }
    }
    
}

extension Date {
    
    func formatted(relativeTo: Date) -> String {
        if self + 60 > relativeTo { return "Now" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: relativeTo)
    }
    
}

extension UserSession {
    
    static func getCurrentUUID() -> String {
        let uuid = UserDefaults.standard.string(forKey: Keys.LAST_USER_SESSSION)
        if (uuid ?? "").isEmpty { fatalError("No user session was set!") }
        return uuid!
    }
    
    static func fetchCurrentRequest() -> NSFetchRequest<UserSession> {
        return UserSession.fetchRequest(uuid: getCurrentUUID())
    }
    
    static func fetchRequest(uuid: String) -> NSFetchRequest<UserSession> {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "uuid CONTAINS %@", uuid)
        return request
    }
    
    static func fetchWithHealthRequest() -> NSFetchRequest<UserSession> {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "userMeasurement != nil || userSymptoms.@count > 0")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    static func fetchWithWeatherRequest() -> NSFetchRequest<UserSession> {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "weather != nil")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    static func fetchWithSuggestionsRequest() -> NSFetchRequest<UserSession> {
        let request = UserSession.fetchRequest()
        request.predicate = NSPredicate(format: "suggestions.@count > 0")
        request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return request
    }
    
    static func getCurrent(context: NSManagedObjectContext) -> UserSession {
        let uuid = getCurrentUUID()
        let userSessions = try! context.fetch(UserSession.fetchRequest(uuid: uuid))
        let userSession = userSessions.first ?? UserSession(context: context)
        userSession.uuid = userSession.uuid ?? uuid
        userSession.timestamp = Date.now
        return userSession
    }
    
}

extension Symptom {
    
    static func create(context: NSManagedObjectContext, from decodable: DecodableSymptom) -> Symptom {
        let symptom = Symptom(context: context)
        symptom.id = decodable.id
        symptom.name = decodable.name
        return symptom
    }
    
    static func fetchRequest(forId: Int16) -> NSFetchRequest<Symptom> {
        let request = Symptom.fetchRequest()
        request.predicate = NSPredicate(format: "id == %i", forId)
        return request
    }
    
}

extension Suggestion {
    
    enum Source: String {
        case Calendar
        case Health
    }
    
    static func fromCalendar(context: NSManagedObjectContext, content: String) -> Suggestion {
        return Suggestion.from(context: context, source: .Calendar, content: content)
    }
    
    static func fromHealth(context: NSManagedObjectContext, content: String) -> Suggestion {
        return Suggestion.from(context: context, source: .Health, content: content)
    }
    
    private static func from(context: NSManagedObjectContext, source: Source, content: String) -> Suggestion {
        let suggestion = Suggestion(context: context)
        suggestion.source = source.rawValue
        suggestion.content = content
        suggestion.userSession = UserSession.getCurrent(context: context)
        return suggestion
    }
    
}

extension FineTuneParameter {
    
    enum Label: String {
        case Place
        case Weather
        case Health
        case Calendar
    }
    
    var icon: String {
        guard
            let labelString = self.label,
            let labelEnum = Label(rawValue: labelString)
        else {
            return "questionmark.circle"
        }
        switch labelEnum {
        case .Place: return "map"
        case .Weather: return "cloud.sun"
        case .Health: return "heart.text.square"
        case .Calendar: return "calendar"
        }
    }
    
    static func ofPlace(context: NSManagedObjectContext, place: GoogleNearbyPlace) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Place, value: place.name)
    }
    
    static func ofWeather(context: NSManagedObjectContext, weather: Weather) -> FineTuneParameter {
        let value = weather.weatherDescription!.capitalized
        return FineTuneParameter.of(context: context, label: .Weather, value: value)
    }
    
    static func ofCalendar(context: NSManagedObjectContext, event: EKEvent) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Calendar, value: event.title ?? "Unknown")
    }
    
    static func ofEmptyCalendar(context: NSManagedObjectContext) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Calendar, value: "No upcoming events!")
    }
    
    static func ofBusyCalendar(context: NSManagedObjectContext, events: [EKEvent]) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Calendar, value: "\(events.count) events this week")
    }
    
    static func ofStaleHealthInformation(context: NSManagedObjectContext, userSession: UserSession?) -> FineTuneParameter {
        var value = "No health information!"
        if let userSession = userSession, let timestamp = userSession.timestamp {
            value = "Last recorded: \(timestamp.formatted(relativeTo: Date.now))"
        }
        return FineTuneParameter.of(context: context, label: .Health, value: value)
    }
    
    static func ofSymptom(context: NSManagedObjectContext, symptom: Symptom) -> FineTuneParameter {
        let value = "\(symptom.name!) (Symptom)"
        return FineTuneParameter.of(context: context, label: .Health, value: value)
    }
    
    static func ofHeartRate(context: NSManagedObjectContext) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Health, value: "Heart Rates")
    }
    
    static func ofRespRate(context: NSManagedObjectContext) -> FineTuneParameter {
        return FineTuneParameter.of(context: context, label: .Health, value: "Respiratory Rates")
    }
    
    private static func of(context: NSManagedObjectContext, label: Label, value: String) -> FineTuneParameter {
        let parameter = FineTuneParameter(context: context)
        parameter.label = label.rawValue
        parameter.value = value
        return parameter
    }
    
}

extension Weather {
    
    struct UIField {
        let icon: String
        let label: String
        let value: Text
    }
    
    func getUIFields() -> [UIField] {
        return [
            UIField(icon: "thermometer.low", label: "Min. Temperature", value: Text("\(minTemp, specifier: "%.2f")° C")),
            UIField(icon: "thermometer.high", label: "Max. Temperature", value: Text("\(maxTemp, specifier: "%.2f")° C")),
            UIField(icon: "barometer", label: "Pressure", value: Text("\(pressure / 1000, specifier: "%.2f") khPa")),
            UIField(icon: "humidity", label: "Humidity", value: Text("\(humidity, specifier: "%.2f") %")),
            UIField(icon: "eye", label: "Visibility", value: Text("\(visibility / 1000, specifier: "%.2f") km")),
            UIField(icon: "wind", label: "Wind Speed", value: Text("\(windSpeed, specifier: "%.2f") m/s")),
        ]
    }
    
}

extension EKEventStore {
    
    func upcomingEvents() -> [EKEvent] {
        let startDate = Date.now
        let endDate = startDate + CalendarConstants.EVENTS_FUTURE_LOOKUP_TIME_INTERVAL
        let calendars = self.calendars(for: .event)
        let predicate = self.predicateForEvents(withStart: startDate, end: endDate, calendars: calendars)
        
        var events = self.events(matching: predicate)
        events.sort { $0.startDate < $1.startDate }
        return events
    }
    
}
