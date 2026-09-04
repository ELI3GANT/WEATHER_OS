import Flutter
import SwiftUI
import UIKit
import WatchConnectivity
import WidgetKit

public enum NativeSheetState: String {
    case none
    case station
    case settings
    case privacy
    case tipJar
}

public class WeatherNativeBridge: NSObject, FlutterPlugin, ObservableObject, UIAdaptivePresentationControllerDelegate {
    public static var instance: WeatherNativeBridge?
    private var channel: FlutterMethodChannel?

    @Published public var selectedTab: Int = 0
    @Published public var alertCount: Int = 0
    @Published public var isPlayingRadar: Bool = true
    @Published public var selectedRadarRangeIndex: Int = 1
    @Published public var showTabBar: Bool = true
    @Published public var showHeader: Bool = true
    @Published public var showRadarControls: Bool = false
    @Published public var currentSheetState: NativeSheetState = .none

    private var lastNavigationRevision: Int = -1
    private var lastRadarRevision: Int = -1
    private var lastReportedInsets: [String: Double] = [:]

    private var hostingController: UIHostingController<WeatherNativeRootOverlayView>?
    private weak var currentPresentedSheetVC: UIViewController?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "tech.onlytrueperspective.weatheros/native_ui",
            binaryMessenger: registrar.messenger()
        )
        let watchChannel = FlutterMethodChannel(
            name: "tech.onlytrueperspective.weatheros/watch_sync",
            binaryMessenger: registrar.messenger()
        )
        let instance = WeatherNativeBridge()
        instance.channel = channel
        WeatherNativeBridge.instance = instance
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addMethodCallDelegate(instance, channel: watchChannel)

        // Attach native overlay when root view controller is ready
        DispatchQueue.main.async {
            let keyWindow = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            if let rootVC = keyWindow?.rootViewController {
                instance.attachOverlay(to: rootVC)
            }
        }
    }

    public func attachOverlay(to rootVC: UIViewController) {
        guard hostingController == nil else { return }

        let rootView = WeatherNativeRootOverlayView(bridge: self)
        let host = UIHostingController(rootView: rootView)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false

        let container = PassThroughView(bridge: self)
        container.translatesAutoresizingMaskIntoConstraints = false
        rootVC.view.addSubview(container)

        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: rootVC.view.topAnchor),
            container.bottomAnchor.constraint(equalTo: rootVC.view.bottomAnchor),
            container.leadingAnchor.constraint(equalTo: rootVC.view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: rootVC.view.trailingAnchor)
        ])

        rootVC.addChild(host)
        container.addSubview(host.view)

        NSLayoutConstraint.activate([
            host.view.topAnchor.constraint(equalTo: container.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            host.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        host.didMove(toParent: rootVC)
        hostingController = host

        // Calculate and report initial native layout metrics
        updateAndReportInsets(for: rootVC.view)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "ping":
            result(true)

        case "updateNavigationState":
            guard let args = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            let revision = args["revision"] as? Int ?? 0
            DispatchQueue.main.async {
                guard revision >= self.lastNavigationRevision else {
                    // Stale confirmation: ignore to prevent out-of-order state drift
                    return
                }
                self.lastNavigationRevision = revision
                if let tab = args["selectedTab"] as? Int {
                    self.selectedTab = tab
                    self.showRadarControls = (tab == 3) // Radar tab
                }
                if let alerts = args["alertCount"] as? Int {
                    self.alertCount = alerts
                }
            }
            result(nil)

        case "updateRadarControls":
            guard let args = call.arguments as? [String: Any] else {
                result(nil)
                return
            }
            let revision = args["revision"] as? Int ?? 0
            DispatchQueue.main.async {
                guard revision >= self.lastRadarRevision else {
                    // Stale confirmation: ignore
                    return
                }
                self.lastRadarRevision = revision
                if let playing = args["isPlaying"] as? Bool {
                    self.isPlayingRadar = playing
                }
                if let range = args["selectedRangeIndex"] as? Int {
                    self.selectedRadarRangeIndex = range
                }
            }
            result(nil)

        case "presentNativeSheet":
            let args = call.arguments as? [String: Any]
            let requestedType = args?["sheetType"] as? String ?? "station"
            DispatchQueue.main.async {
                self.presentSheet(type: requestedType) { action in
                    result(["sheetType": requestedType, "action": action])
                }
            }

        case "triggerHaptic":
            if let args = call.arguments as? [String: Any],
               let type = args["type"] as? String {
                WeatherNativeHaptics.trigger(type)
            }
            result(nil)

        case "setChromeVisibility":
            if let args = call.arguments as? [String: Any] {
                DispatchQueue.main.async {
                    if let tab = args["showTabBar"] as? Bool { self.showTabBar = tab }
                    if let header = args["showHeader"] as? Bool { self.showHeader = header }
                    if let radar = args["showRadarControls"] as? Bool { self.showRadarControls = radar }
                }
            }
            result(nil)

        case "updateWatchAndWidgets":
            guard let args = call.arguments as? [String: Any],
                  let jsonPayload = args["jsonPayload"] as? String else {
                result(FlutterError(
                    code: "invalid_payload",
                    message: "Weather telemetry payload is missing.",
                    details: nil
                ))
                return
            }

            let appGroup = args["appGroup"] as? String
                ?? "group.tech.onlytrueperspective.weatheros"
            UserDefaults(suiteName: appGroup)?.set(jsonPayload, forKey: "weather_payload")
            WidgetCenter.shared.reloadAllTimelines()

            if WCSession.isSupported() {
                do {
                    try WCSession.default.updateApplicationContext([
                        "jsonPayload": jsonPayload
                    ])
                } catch {
                    // Widgets are still updated through the App Group even if
                    // Apple Watch connectivity is unavailable at this moment.
                }
            }
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func emitTabSelected(_ tabIndex: Int) {
        channel?.invokeMethod("onTabSelected", arguments: tabIndex)
    }

    public func emitRadarRangeChanged(_ rangeIndex: Int) {
        channel?.invokeMethod("onRadarRangeChanged", arguments: rangeIndex)
    }

    public func emitRadarTogglePlay() {
        channel?.invokeMethod("onRadarTogglePlay", arguments: nil)
    }

    public func emitHeaderAction(_ action: String) {
        channel?.invokeMethod("onHeaderAction", arguments: action)
    }

    public func updateAndReportInsets(for view: UIView?) {
        guard let view = view ?? hostingController?.view else { return }
        let safeArea = view.safeAreaInsets
        let systemBottom = Double(safeArea.bottom)
        let systemTop = Double(safeArea.top)

        // Native tab bar occupies ~64pt height + 6pt bottom padding above safe area
        let chromeBottom = showTabBar ? 70.0 : 0.0
        let chromeTop = showHeader ? 0.0 : 0.0

        let totalBottom = systemBottom + chromeBottom
        let totalTop = systemTop + chromeTop

        let newInsets: [String: Double] = [
            "top": totalTop,
            "bottom": totalBottom,
            "leading": Double(safeArea.left),
            "trailing": Double(safeArea.right),
            "systemTop": systemTop,
            "systemBottom": systemBottom,
            "chromeTop": chromeTop,
            "chromeBottom": chromeBottom
        ]

        // Tolerance check: only emit if changes exceed 0.5pt
        var hasSignificantChange = false
        for (key, val) in newInsets {
            let oldVal = lastReportedInsets[key] ?? -999.0
            if abs(val - oldVal) > 0.5 {
                hasSignificantChange = true
                break
            }
        }

        if hasSignificantChange {
            lastReportedInsets = newInsets
            channel?.invokeMethod("onNativeInsetsChanged", arguments: newInsets)
        }
    }

    private func presentSheet(type: String, completion: @escaping (String) -> Void) {
        guard currentSheetState == .none else {
            // Already presenting a sheet; reject duplicate presentation race
            completion("already_presented")
            return
        }

        let targetState: NativeSheetState = switch type {
        case "station": .station
        case "settings": .settings
        case "privacy": .privacy
        case "tipJar": .tipJar
        default: .station
        }

        self.currentSheetState = targetState

        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let rootVC = keyWindow?.rootViewController else {
            self.currentSheetState = .none
            completion("failed")
            return
        }

        let sheetView = WeatherStationIntelligenceSheet(
            onRefresh: { [weak self] in
                self?.channel?.invokeMethod("onHeaderAction", arguments: "refresh")
            },
            onTipSelected: { [weak self] (title, price) in
                self?.channel?.invokeMethod("onHeaderAction", arguments: "tip:\(title)")
            }
        )

        let hostingVC = UIHostingController(rootView: sheetView)
        hostingVC.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        hostingVC.presentationController?.delegate = self
        self.currentPresentedSheetVC = hostingVC

        if let sheet = hostingVC.sheetPresentationController {
            sheet.detents = [
                UISheetPresentationController.Detent.medium(),
                UISheetPresentationController.Detent.large()
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 32
        }

        rootVC.present(hostingVC, animated: true) {
            completion("presented")
        }
    }

    // UIAdaptivePresentationControllerDelegate for interactive dismissal
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.currentSheetState = .none
        self.currentPresentedSheetVC = nil
        channel?.invokeMethod("onSheetResult", arguments: [
            "sheetType": "station",
            "action": "dismissed"
        ])
    }
}

// SwiftUI overlay containing the Native Liquid Glass Chrome
public struct WeatherNativeRootOverlayView: View {
    @ObservedObject public var bridge: WeatherNativeBridge

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Native Floating Radar Controls (Visible only on Radar Tab)
                if bridge.showRadarControls {
                    WeatherRadarControls(
                        isPlaying: $bridge.isPlayingRadar,
                        selectedRangeIndex: $bridge.selectedRadarRangeIndex,
                        onRangeChanged: { index in
                            bridge.emitRadarRangeChanged(index)
                        },
                        onTogglePlay: {
                            bridge.emitRadarTogglePlay()
                        }
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Native Liquid Glass Tab Bar
                if bridge.showTabBar {
                    WeatherGlassTabBar(
                        selectedTab: $bridge.selectedTab,
                        alertCount: bridge.alertCount,
                        onSelectTab: { tabIndex in
                            // Authoritative Flow: Emit intent to Flutter.
                            // Flutter confirms state and bridge.selectedTab updates via updateNavigationState.
                            bridge.emitTabSelected(tabIndex)
                        }
                    )
                    .padding(.bottom, 6)
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.76), value: bridge.selectedTab)
        .animation(.spring(response: 0.32, dampingFraction: 0.76), value: bridge.showRadarControls)
    }
}

// Precise Pass-Through Container View:
// Only intercepts touches that land directly inside active native controls (Tab Bar / Radar Controls).
// Touches anywhere else pass directly through to Flutter.
public class PassThroughView: UIView {
    private weak var bridge: WeatherNativeBridge?

    public init(bridge: WeatherNativeBridge) {
        self.bridge = bridge
        super.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let bridge = bridge else { return nil }

        // If no native chrome is visible, pass everything to Flutter
        if !bridge.showTabBar && !bridge.showRadarControls {
            return nil
        }

        let boundsHeight = bounds.height
        guard boundsHeight > 0 else { return nil }

        // Calculate active interactive region height at bottom of screen
        let safeAreaBottom = safeAreaInsets.bottom
        var interactiveHeight: CGFloat = 0.0

        if bridge.showTabBar {
            // Tab bar height ~64pt + bottom padding ~6pt + safe area
            interactiveHeight += 70.0 + safeAreaBottom
        }

        if bridge.showRadarControls {
            // Radar controls height ~50pt + bottom padding ~8pt
            interactiveHeight += 58.0
        }

        let interactiveTopY = boundsHeight - interactiveHeight

        // If touch point is above the interactive controls region, pass straight to Flutter!
        if point.y < interactiveTopY {
            return nil
        }

        // Test subviews for actual interactive targets
        let hit = super.hitTest(point, with: event)
        if hit == self {
            return nil
        }
        return hit
    }
}

