import SwiftUI
import UIKit

public struct WeatherGlassTabBar: View {
    @Binding public var selectedTab: Int
    public var alertCount: Int
    public var onSelectTab: (Int) -> Void

    private let tabs: [(title: String, symbol: String, activeSymbol: String)] = [
        ("Today", "cloud.bolt.rain", "cloud.bolt.rain.fill"),
        ("Hourly", "clock", "clock.fill"),
        ("Daily", "calendar", "calendar"),
        ("Radar", "dot.radiowaves.left.and.right", "dot.radiowaves.left.and.right"),
        ("Alerts", "bell", "bell.fill")
    ]

    public init(
        selectedTab: Binding<Int>,
        alertCount: Int = 0,
        onSelectTab: @escaping (Int) -> Void
    ) {
        self._selectedTab = selectedTab
        self.alertCount = alertCount
        self.onSelectTab = onSelectTab
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                let tab = tabs[index]
                let isSelected = selectedTab == index

                Button(action: {
                    WeatherNativeHaptics.trigger("selection")
                    onSelectTab(index)
                }) {
                    VStack(spacing: 3) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: isSelected ? tab.activeSymbol : tab.symbol)
                                .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(
                                    isSelected
                                        ? Color(red: 0.40, green: 0.79, blue: 1.00) // Mist Blue
                                        : Color(red: 0.49, green: 0.57, blue: 0.64) // Tertiary
                                )
                                .scaleEffect(isSelected ? 1.08 : 1.0)
                                .animation(.spring(response: 0.28, dampingFraction: 0.72), value: isSelected)

                            if index == 4 && alertCount > 0 {
                                Text("\(alertCount)")
                                    .font(.system(size: 9, weight: .heavy))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(Color.red)
                                    .clipShape(Capsule())
                                    .offset(x: 10, y: -6)
                            }
                        }

                        Text(tab.title)
                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(
                                isSelected
                                    ? Color(red: 0.40, green: 0.79, blue: 1.00)
                                    : Color(red: 0.49, green: 0.57, blue: 0.64)
                            )
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .padding(.vertical, 8)
                }
                .buttonStyle(GlassTabButtonStyle())
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(
            ZStack {
                // Glass background surface
                #if compiler(>=6.0)
                if #available(iOS 26.0, *) {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.62, green: 0.86, blue: 1.0).opacity(0.35),
                                            Color.white.opacity(0.08),
                                            Color(red: 0.62, green: 0.86, blue: 1.0).opacity(0.12)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                } else {
                    fallbackGlassBackground
                }
                #else
                fallbackGlassBackground
                #endif
            }
        )
        .padding(.horizontal, 12)
    }

    private var fallbackGlassBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(Color(red: 0.02, green: 0.07, blue: 0.12).opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        Color(red: 0.62, green: 0.86, blue: 1.0).opacity(0.25),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 6)
    }
}

private struct GlassTabButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.68), value: configuration.isPressed)
    }
}
