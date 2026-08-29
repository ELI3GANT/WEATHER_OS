import UIKit

public enum WeatherNativeHaptics {
    private static let selectionGen = UISelectionFeedbackGenerator()
    private static let lightGen = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGen = UIImpactFeedbackGenerator(style: .heavy)
    private static let notifyGen = UINotificationFeedbackGenerator()

    public static func trigger(_ typeName: String) {
        DispatchQueue.main.async {
            switch typeName {
            case "selection":
                selectionGen.prepare()
                selectionGen.selectionChanged()
            case "light":
                lightGen.prepare()
                lightGen.impactOccurred()
            case "medium":
                mediumGen.prepare()
                mediumGen.impactOccurred()
            case "heavy":
                heavyGen.prepare()
                heavyGen.impactOccurred()
            case "success":
                notifyGen.prepare()
                notifyGen.notificationOccurred(.success)
            case "warning":
                notifyGen.prepare()
                notifyGen.notificationOccurred(.warning)
            case "error":
                notifyGen.prepare()
                notifyGen.notificationOccurred(.error)
            default:
                selectionGen.selectionChanged()
            }
        }
    }
}
