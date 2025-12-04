import Foundation
import HomeKit

class ThermostatScheduler: ObservableObject {
    static let shared = ThermostatScheduler()
    @Published var schedules: [ThermostatSchedule] = []
    
    struct ThermostatSchedule: Identifiable, Codable {
        let id: UUID
        let thermostatID: String
        var weekdaySchedule: [TimeTemperature]
        var weekendSchedule: [TimeTemperature]
        var vacationMode: Bool
        var ecoMode: Bool
    }
    
    struct TimeTemperature: Codable {
        let hour: Int
        let minute: Int
        let temperature: Double
    }
    
    func createSchedule(for thermostat: HMService) {
        let schedule = ThermostatSchedule(
            id: UUID(),
            thermostatID: thermostat.uniqueIdentifier.uuidString,
            weekdaySchedule: [
                TimeTemperature(hour: 6, minute: 0, temperature: 21.0),
                TimeTemperature(hour: 22, minute: 0, temperature: 18.0)
            ],
            weekendSchedule: [
                TimeTemperature(hour: 8, minute: 0, temperature: 21.0),
                TimeTemperature(hour: 23, minute: 0, temperature: 18.0)
            ],
            vacationMode: false,
            ecoMode: true
        )
        schedules.append(schedule)
    }
}