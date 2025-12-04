import SwiftUI

/// Integration hub view for external services
struct IntegrationHubView: View {
    @EnvironmentObject var homeManager: HomeKitManager
    @ObservedObject private var integrationManager = IntegrationManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 40) {
                    Text("Integration Hub")
                        .font(.largeTitle)
                        .bold()
                        .padding(.horizontal, 80)
                        .padding(.top, 60)

                    // Weather Integration
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Weather")
                                .font(.title2)

                            Spacer()

                            Button(action: {
                                integrationManager.fetchWeather()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh")
                                }
                                .font(.title3)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 80)

                        if integrationManager.isLoadingWeather {
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity)
                                .padding(60)
                        } else if let weather = integrationManager.weather {
                            WeatherCard(weather: weather)
                                .padding(.horizontal, 80)
                        } else {
                            VStack(spacing: 20) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("Tap refresh to load weather")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        }
                    }

                    // Calendar Events
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Calendar Events")
                                .font(.title2)

                            Spacer()

                            Button(action: {
                                integrationManager.loadCalendarEvents()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.clockwise")
                                    Text("Refresh")
                                }
                                .font(.title3)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 80)

                        if integrationManager.calendarEvents.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No calendar events")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(integrationManager.calendarEvents) { event in
                                    CalendarEventRow(event: event)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                    }

                    // Webhooks
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("Webhooks")
                                .font(.title2)

                            Spacer()

                            NavigationLink(destination: CreateWebhookView()) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("New Webhook")
                                }
                                .font(.title3)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 80)

                        if integrationManager.webhooks.isEmpty {
                            VStack(spacing: 20) {
                                Image(systemName: "link.circle")
                                    .font(.system(size: 60))
                                    .foregroundColor(.secondary)
                                Text("No webhooks configured")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(60)
                        } else {
                            VStack(spacing: 15) {
                                ForEach(integrationManager.webhooks) { webhook in
                                    WebhookRow(webhook: webhook)
                                }
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}

/// Weather card
struct WeatherCard: View {
    let weather: WeatherData

    var body: some View {
        VStack(spacing: 25) {
            HStack(spacing: 30) {
                // Current conditions
                VStack(spacing: 15) {
                    Image(systemName: weather.icon)
                        .font(.system(size: 80))
                        .foregroundColor(.orange)

                    Text("\(weather.temperature)°")
                        .font(.system(size: 60, weight: .bold))

                    Text(weather.condition)
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Details
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "thermometer.high")
                        Text("High: \(weather.highTemp)°")
                    }
                    HStack {
                        Image(systemName: "thermometer.low")
                        Text("Low: \(weather.lowTemp)°")
                    }
                    HStack {
                        Image(systemName: "humidity.fill")
                        Text("Humidity: \(weather.humidity)%")
                    }
                    HStack {
                        Image(systemName: "wind")
                        Text("Wind: \(weather.windSpeed) mph")
                    }
                }
                .font(.title3)

                Spacer()

                // Sun times
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Image(systemName: "sunrise.fill")
                        Text(weather.sunrise, style: .time)
                    }
                    HStack {
                        Image(systemName: "sunset.fill")
                        Text(weather.sunset, style: .time)
                    }
                }
                .font(.title3)
                .foregroundColor(.secondary)
            }
        }
        .padding(40)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
    }
}

/// Calendar event row
struct CalendarEventRow: View {
    @EnvironmentObject var homeManager: HomeKitManager
    let event: CalendarEvent

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: event.isNow ? "calendar.circle.fill" : "calendar")
                .font(.system(size: 35))
                .foregroundColor(event.isNow ? .green : .blue)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(event.title)
                    .font(.title3)
                    .bold()

                HStack {
                    Text(event.startTime, style: .time)
                    Text("-")
                    Text(event.endTime, style: .time)
                }
                .font(.caption)
                .foregroundColor(.secondary)

                if let scene = event.suggestedScene {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Suggested: \(scene)")
                    }
                    .font(.caption)
                    .foregroundColor(.purple)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(6)
                }
            }

            Spacer()

            if let scene = event.suggestedScene, let matchedScene = homeManager.scenes.first(where: { $0.name == scene }) {
                Button(action: {
                    homeManager.executeScene(matchedScene)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(event.isNow ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Webhook row
struct WebhookRow: View {
    @ObservedObject private var integrationManager = IntegrationManager.shared
    let webhook: Webhook

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: "link.circle.fill")
                .font(.system(size: 35))
                .foregroundColor(.orange)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 6) {
                Text(webhook.name)
                    .font(.title3)
                    .bold()

                Text(webhook.trigger.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(6)

                Text(webhook.url)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            HStack(spacing: 15) {
                Button(action: {
                    integrationManager.triggerWebhook(webhook)
                }) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)

                Button(action: {
                    integrationManager.deleteWebhook(webhook)
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

/// Create webhook view
struct CreateWebhookView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var integrationManager = IntegrationManager.shared

    @State private var name = ""
    @State private var url = ""
    @State private var trigger: WebhookTrigger = .sceneExecuted
    @State private var method = "POST"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                Text("Create Webhook")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top, 60)

                VStack(alignment: .leading, spacing: 15) {
                    Text("Name")
                        .font(.title3)

                    TextField("Webhook name", text: $name)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .padding(15)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("URL")
                        .font(.title3)

                    TextField("https://example.com/webhook", text: $url)
                        .font(.title3)
                        .textFieldStyle(.plain)
                        .padding(15)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("Trigger")
                        .font(.title3)

                    Picker("Trigger", selection: $trigger) {
                        ForEach(WebhookTrigger.allCases, id: \.self) { triggerType in
                            Text(triggerType.rawValue).tag(triggerType)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 15) {
                    Text("Method")
                        .font(.title3)

                    Picker("Method", selection: $method) {
                        Text("POST").tag("POST")
                        Text("GET").tag("GET")
                        Text("PUT").tag("PUT")
                    }
                    .pickerStyle(.segmented)
                }

                Spacer()

                HStack(spacing: 25) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .buttonStyle(.plain)

                    Button("Create") {
                        integrationManager.createWebhook(name: name, url: url, trigger: trigger, method: method)
                        dismiss()
                    }
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(name.isEmpty || url.isEmpty ? Color.gray : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .buttonStyle(.plain)
                    .disabled(name.isEmpty || url.isEmpty)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 80)
        }
    }
}

#Preview {
    IntegrationHubView()
        .environmentObject(HomeKitManager())
}
