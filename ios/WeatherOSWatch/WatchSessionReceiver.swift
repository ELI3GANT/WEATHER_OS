import Foundation
import WatchConnectivity
import Combine

/// Receives real-time weather telemetry from the parent iPhone app via WCSession
public class WatchSessionReceiver: NSObject, ObservableObject, WCSessionDelegate {
    public static let shared = WatchSessionReceiver()

    @Published public var location: String = "Woonsocket, RI"
    @Published public var temperature: Double = 71.0
    @Published public var feelsLike: Double = 69.0
    @Published public var condition: String = "rain"
    @Published public var high: Double = 72.0
    @Published public var low: Double = 62.0
    @Published public var precipChance: int = 90
    @Published public var dailySummary: String = "Scattered showers with gusty winds."
    @Published public var hourly: [[String: Any]] = []
    @Published public var daily: [[String: Any]] = []

    private override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        loadFromSharedDefaults()
    }

    private func loadFromSharedDefaults() {
        if let defaults = UserDefaults(suiteName: "group.tech.onlytrueperspective.weatheros"),
           let jsonString = defaults.string(forKey: "weather_payload"),
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parsePayload(json)
        }
    }

    private func parsePayload(_ dict: [String: Any]) {
        DispatchQueue.main.async {
            if let loc = dict["location"] as? String { self.location = loc }
            if let temp = dict["temperature"] as? Double { self.temperature = temp }
            if let feels = dict["feelsLike"] as? Double { self.feelsLike = feels }
            if let cond = dict["condition"] as? String { self.condition = cond }
            if let h = dict["high"] as? Double { self.high = h }
            if let l = dict["low"] as? Double { self.low = l }
            if let precip = dict["precipChance"] as? Int { self.precipChance = precip }
            if let summary = dict["dailySummary"] as? String { self.dailySummary = summary }
            if let hr = dict["hourly"] as? [[String: Any]] { self.hourly = hr }
            if let d = dict["daily"] as? [[String: Any]] { self.daily = d }
        }
    }

    // MARK: - WCSessionDelegate
    public func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    public func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        if let jsonString = applicationContext["jsonPayload"] as? String,
           let data = jsonString.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            parsePayload(json)
        }
    }
}
