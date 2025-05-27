//
//  OpenWeatherAPIResponseModel.swift
//  WellnessAI
//
//  Created by Shubham Chawla on 12/27/23.
//

import Foundation
import CoreLocation
import CoreData

struct OpenWeatherAPIRequest {
    let location: CLLocation
}

struct OpenWeatherAPIResponse: Decodable {
    let cod: Int?
    let message: String?
    let name: String?
    let visibility: Double?
    let weather: [OpenWeatherAPIResponseWeather]?
    let main: OpenWeatherAPIResponseMain?
    let wind: OpenWeatherAPIResponseWind?
    let coord: OpenWeatherAPIResponseCoord?
}

struct OpenWeatherAPIResponseWeather: Decodable {
    let main: String?
    let description: String?
    let icon: String?
}

struct OpenWeatherAPIResponseMain: Decodable {
    let temp: Double?
    let feels_like: Double?
    let temp_min: Double?
    let temp_max: Double?
    let pressure: Double?
    let humidity: Double?
}

struct OpenWeatherAPIResponseWind: Decodable {
    let speed: Double?
}

struct OpenWeatherAPIResponseCoord: Decodable {
    let lat: Double?
    let lon: Double?
}

extension OpenWeatherAPIRequest {
    
    func fetch() async throws -> OpenWeatherAPIResponse {
        let appid = UserDefaults.standard.string(forKey: Keys.OPEN_WEATHER_API_KEY_IDENTIFIER)
        guard !(appid ?? "").isEmpty else { throw AppError.openWeatherAPIKeyMissing }
        
        var components = URLComponents(string: "https://api.openweathermap.org/data/2.5/weather")!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "lon", value: "\(location.coordinate.longitude)"),
            URLQueryItem(name: "units", value: APIConstants.OPEN_WEATHER_UNITS),
            URLQueryItem(name: "appid", value: appid)
        ]
        
        let request = URLRequest(url: components.url!)
        let (data, urlResponse) = try await URLSession.shared.data(for: request)
        
        guard
            let httpResponse = urlResponse as? HTTPURLResponse,
            httpResponse.statusCode >= 200 && httpResponse.statusCode < 300
        else {
            throw URLError(.badServerResponse)
        }
        
        let apiResponse = try JSONDecoder().decode(OpenWeatherAPIResponse.self, from: data)
        guard apiResponse.cod == 200 else { throw URLError(.badServerResponse) }
        return apiResponse
    }
    
}

extension OpenWeatherAPIResponse {
    
    func toWeather(context: NSManagedObjectContext) -> Weather {
        let weather = Weather(context: context)
        weather.locationName = self.name
        weather.weatherMain = self.weather?.first?.main
        weather.weatherDescription = self.weather?.first?.description
        weather.iconSystemName = WeatherConstants.getSystemName(forIcon: self.weather?.first?.icon ?? "")
        weather.currentTemp = self.main?.temp ?? weather.currentTemp
        weather.feelsLikeTemp = self.main?.feels_like ?? weather.feelsLikeTemp
        weather.minTemp = self.main?.temp_min ?? weather.minTemp
        weather.maxTemp = self.main?.temp_max ??  weather.maxTemp
        weather.pressure = self.main?.pressure ?? weather.pressure
        weather.humidity = self.main?.humidity ?? weather.humidity
        weather.visibility = self.visibility ?? weather.visibility
        weather.windSpeed = self.wind?.speed ?? weather.windSpeed
        weather.latitude = self.coord?.lat ?? weather.latitude
        weather.longitude = self.coord?.lon ?? weather.longitude
        weather.units = APIConstants.OPEN_WEATHER_UNITS
        return weather
    }
    
}
