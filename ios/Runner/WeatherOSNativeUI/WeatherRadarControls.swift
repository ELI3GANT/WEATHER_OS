import SwiftUI
import UIKit

public struct WeatherRadarControls: View {
    @Binding public var isPlaying: Bool
    @Binding public var selectedRangeIndex: Int
    public var ranges: [String] = ["50 mi", "100 mi", "250 mi"]
    public var onRangeChanged: (Int) -> Void
    public var onTogglePlay: () -> Void

    public init(
        isPlaying: Binding<Bool>,
        selectedRangeIndex: Binding<Int>,
        ranges: [String] = ["50 mi", "100 mi", "250 mi"],
        onRangeChanged: @escaping (Int) -> Void,
        onTogglePlay: @escaping () -> Void
    ) {
        self._isPlaying = isPlaying
        self._selectedRangeIndex = selectedRangeIndex
        self.ranges = ranges
        self.onRangeChanged = onRangeChanged
        self.onTogglePlay = onTogglePlay
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Segmented range pills
            HStack(spacing: 4) {
                ForEach(0..<ranges.count, id: \.self) { index in
                    let isSelected = selectedRangeIndex == index
                    Button(action: {
                        WeatherNativeHaptics.trigger("selection")
                        onRangeChanged(index)
                    }) {
                        Text(ranges[index])
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(
                                isSelected
                                    ? Color(red: 0.40, green: 0.79, blue: 1.00)
                                    : Color(red: 0.72, green: 0.77, blue: 0.83)
                            )
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                isSelected
                                    ? Color(red: 0.40, green: 0.79, blue: 1.00).opacity(0.22)
                                    : Color.clear
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(3)
            .background(Color(red: 0.09, green: 0.19, blue: 0.28).opacity(0.5))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(red: 0.62, green: 0.86, blue: 1.0).opacity(0.18), lineWidth: 1)
            )

            Spacer()

            // Play / Pause Button
            Button(action: {
                WeatherNativeHaptics.trigger("light")
                onTogglePlay()
            }) {
                Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Color(red: 0.40, green: 0.79, blue: 1.00))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.62, green: 0.86, blue: 1.0).opacity(0.3),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }
}
