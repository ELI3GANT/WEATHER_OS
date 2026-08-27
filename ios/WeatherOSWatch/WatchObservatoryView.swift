import SwiftUI
import WatchKit

public struct WatchObservatoryView: View {
    @StateObject private var receiver = WatchSessionReceiver.shared
    @State private var crownAccumulator: Double = 0.0
    @State private var selectedHourIndex: Int = 0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                // Header location
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.58, green: 0.77, blue: 0.99))
                    Text(receiver.location)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                // Hero Telemetry Box
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(Int(receiver.temperature.rounded()))°")
                            .font(.system(size: 38, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text("Feels \(Int(receiver.feelsLike.rounded()))°")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    // Kinetic Condition Icon
                    VStack(spacing: 2) {
                        conditionIcon(for: receiver.condition)
                            .font(.system(size: 26))
                            .foregroundColor(Color(red: 0.96, green: 0.65, blue: 0.14))
                        Text(receiver.condition.uppercased())
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.08, green: 0.12, blue: 0.20).opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(red: 0.58, green: 0.77, blue: 0.99).opacity(0.25), lineWidth: 1)
                        )
                )

                // High / Low Pill
                HStack {
                    Text("H: \(Int(receiver.high.rounded()))°")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Text("•")
                        .foregroundColor(.gray)
                    Text("L: \(Int(receiver.low.rounded()))°")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                    Spacer()
                    if receiver.precipChance > 0 {
                        Text("🌧️ \(receiver.precipChance)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.58, green: 0.77, blue: 0.99))
                    }
                }
                .padding(.horizontal, 4)

                Divider()
                    .background(Color.white.opacity(0.15))
                    .padding(.vertical, 2)

                // Pops' 7-Day Spectrum Mini List
                Text("7-DAY OUTLOOK")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.58, green: 0.77, blue: 0.99))
                    .tracking(1.0)

                if !receiver.daily.isEmpty {
                    ForEach(0..<receiver.daily.count, id: \.self) { idx in
                        let item = receiver.daily[idx]
                        let day = item["day"] as? String ?? "Day"
                        let low = item["low"] as? Int ?? 60
                        let high = item["high"] as? Int ?? 75
                        let cond = item["condition"] as? String ?? "cloudy"

                        HStack(spacing: 6) {
                            Text(day.prefix(3))
                                .font(.system(size: 11, weight: .medium))
                                .frame(width: 28, alignment: .leading)
                            
                            conditionIcon(for: cond)
                                .font(.system(size: 11))
                                .foregroundColor(Color(red: 0.58, green: 0.77, blue: 0.99))

                            Text("\(low)°")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                                .frame(width: 20, alignment: .trailing)

                            // Spectrum Gradient Bar
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(LinearGradient(
                                        colors: [Color(red: 0.58, green: 0.77, blue: 0.99), Color(red: 0.96, green: 0.65, blue: 0.14)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ))
                                    .frame(width: 34, height: 4)
                                    .offset(x: 10)
                            }
                            .frame(maxWidth: .infinity)

                            Text("\(high)°")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 20, alignment: .trailing)
                        }
                        .padding(.vertical, 1)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .focusable()
        .digitalCrownRotation(
            $crownAccumulator,
            from: 0.0,
            through: 100.0,
            by: 5.0,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        .background(Color.black.edgesIgnoringSafeArea(.all))
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
