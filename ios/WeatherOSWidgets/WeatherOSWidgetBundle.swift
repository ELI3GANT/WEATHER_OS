import WidgetKit
import SwiftUI

// MARK: - Timeline Entry
struct WeatherTimelineEntry: TimelineEntry {
    let date: Date
    let location: String
    let temperature: Int
    let condition: String
    let high: Int
    let low: Int
    let precipChance: Int
    let dailySummary: String
}

// MARK: - Timeline Provider
struct WeatherTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeatherTimelineEntry {
        WeatherTimelineEntry(
            date: Date(),
            location: "Woonsocket, RI",
            temperature: 71,
            condition: "rain",
            high: 72,
            low: 62,
            precipChance: 90,
            dailySummary: "Scattered showers with gusty winds."
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WeatherTimelineEntry) -> Void) {
        completion(fetchCurrentEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeatherTimelineEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh every 30 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> WeatherTimelineEntry {
        if let defaults = UserDefaults(suiteName: "group.tech.onlytrueperspective.weatheros"),
           let jsonString = defaults.string(forKey: "weather_payload"),
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            return WeatherTimelineEntry(
                date: Date(),
                location: json["location"] as? String ?? "Woonsocket",
                temperature: Int((json["temperature"] as? Double ?? 71.0).rounded()),
                condition: json["condition"] as? String ?? "rain",
                high: Int((json["high"] as? Double ?? 72.0).rounded()),
                low: Int((json["low"] as? Double ?? 62.0).rounded()),
                precipChance: json["precipChance"] as? Int ?? 90,
                dailySummary: json["dailySummary"] as? String ?? "Nominal weather conditions."
            )
        }
        return placeholder(in: .init())
    }
}

// MARK: - Widget Views
struct WeatherWidgetEntryView: View {
    var entry: WeatherTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    conditionIcon(for: entry.condition)
                        .font(.system(size: 13, weight: .bold))
                    Text("\(entry.temperature)°")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                }
            }

        case .accessoryCorner:
            Text("\(entry.temperature)° \(entry.condition.uppercased())")
                .font(.system(size: 12, weight: .bold))
                .widgetLabel {
                    Text("H:\(entry.high)° L:\(entry.low)°")
                }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 3) {
                    conditionIcon(for: entry.condition)
                        .font(.system(size: 11, weight: .bold))
                    Text("\(entry.location) • \(entry.temperature)°")
                        .font(.system(size: 11, weight: .bold))
                }
                Text(entry.dailySummary)
                    .font(.system(size: 9))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
                // Pops' Mini Thermal Bar
                HStack(spacing: 4) {
                    Text("\(entry.low)°").font(.system(size: 8))
                    Capsule().fill(Color.white.opacity(0.4)).frame(height: 3)
                    Text("\(entry.high)°").font(.system(size: 8, weight: .bold))
                }
            }

        case .systemSmall:
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.location)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    conditionIcon(for: entry.condition)
                        .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                }
                Spacer()
                Text("\(entry.temperature)°")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                HStack {
                    Text("H:\(entry.high)° L:\(entry.low)°")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    if entry.precipChance > 0 {
                        Text("\(entry.precipChance)% 🌧️")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color(red: 0.58, green: 0.77, blue: 0.99))
                    }
                }
            }
            .padding(12)
            .background(Color(red: 0.04, green: 0.07, blue: 0.12))

        case .systemMedium:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.location)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(entry.temperature)°")
                        .font(.system(size: 38, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("H:\(entry.high)° L:\(entry.low)° • Feels \(entry.temperature - 2)°")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        conditionIcon(for: entry.condition)
                            .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                        Text(entry.condition.capitalized)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text(entry.dailySummary)
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                        .lineLimit(2)
                }
                .frame(maxWidth: 140)
            }
            .padding(14)
            .background(Color(red: 0.04, green: 0.07, blue: 0.12))

        default:
            Text("\(entry.temperature)°")
        }
    }

    private func conditionIcon(for condition: String) -> Image {
        switch condition.lowercased() {
        case "rain": return Image(systemName: "cloud.rain.fill")
        case "sunny": return Image(systemName: "sun.max.fill")
        case "storm": return Image(systemName: "cloud.bolt.rain.fill")
        case "snow": return Image(systemName: "snowflake")
        case "fog": return Image(systemName: "cloud.fog.fill")
        default: return Image(systemName: "cloud.fill")
        }
    }
}

// MARK: - Main Widget Bundle
@main
struct WeatherOSWidgetBundle: WidgetBundle {
    var body: some Widget {
        WeatherOSMainWidget()
    }
}

struct WeatherOSMainWidget: Widget {
    let kind: String = "WeatherOSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeatherTimelineProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("WeatherOS Telemetry")
        .description("Real-time meteorological conditions and Pops' thermal spectrum.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryCorner,
            .accessoryRectangular
        ])
    }
}
