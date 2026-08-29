import SwiftUI
import UIKit

public struct WeatherStationIntelligenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    public var onRefresh: () -> Void
    public var onTipSelected: (String, String) -> Void

    public init(
        onRefresh: @escaping () -> Void,
        onTipSelected: @escaping (String, String) -> Void
    ) {
        self.onRefresh = onRefresh
        self.onTipSelected = onTipSelected
    }

    public var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Zero-Subscription Pledge Card
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(Color(red: 0.41, green: 0.94, blue: 0.68))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PROUDLY 100% AD-FREE & PRIVATE")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color(red: 0.41, green: 0.94, blue: 0.68))

                            Text("No subscriptions, no third-party telemetry tracking, and zero advertising algorithms.")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color(red: 0.72, green: 0.77, blue: 0.83))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color(red: 0.41, green: 0.94, blue: 0.68).opacity(0.3), lineWidth: 1)
                            )
                    )

                    // Optional Tip Jar
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("SUPPORT INDEPENDENT DEVELOPMENT")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(red: 0.49, green: 0.57, blue: 0.64))
                            Spacer()
                            Text("OPTIONAL")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundStyle(Color(red: 0.89, green: 0.60, blue: 0.36))
                        }

                        HStack(spacing: 10) {
                            TipOptionButton(emoji: "☕", title: "Coffee", price: "$1.99") {
                                WeatherNativeHaptics.trigger("success")
                                onTipSelected("Coffee", "$1.99")
                            }
                            TipOptionButton(emoji: "⚡", title: "Supercharge", price: "$4.99") {
                                WeatherNativeHaptics.trigger("success")
                                onTipSelected("Supercharge", "$4.99")
                            }
                            TipOptionButton(emoji: "👑", title: "Patron", price: "$9.99") {
                                WeatherNativeHaptics.trigger("success")
                                onTipSelected("Patron", "$9.99")
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    )

                    // Sync Telemetry Action Button
                    Button(action: {
                        WeatherNativeHaptics.trigger("medium")
                        dismiss()
                        onRefresh()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.2.circlepath")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Sync Telemetry")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0.40, green: 0.79, blue: 1.00).opacity(0.2))
                        .foregroundStyle(Color(red: 0.40, green: 0.79, blue: 1.00))
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(red: 0.40, green: 0.79, blue: 1.00).opacity(0.4), lineWidth: 1)
                        )
                    }

                    // Version Footer
                    Text("WeatherOS • OnlyTruePerspective LLC")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(red: 0.49, green: 0.57, blue: 0.64))
                        .padding(.top, 8)
                }
                .padding(20)
            }
            .navigationTitle("Station Intelligence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        WeatherNativeHaptics.trigger("light")
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(Color(red: 0.49, green: 0.57, blue: 0.64))
                    }
                }
            }
            .background(Color(red: 0.02, green: 0.07, blue: 0.12).ignoresSafeArea())
        }
    }
}

private struct TipOptionButton: View {
    let emoji: String
    let title: String
    let price: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 20))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.white)
                Text(price)
                    .font(.system(size: 12, weight: .heavy))
                    .foregroundStyle(Color(red: 0.89, green: 0.60, blue: 0.36))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color(red: 0.09, green: 0.19, blue: 0.28).opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }
}
