import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

enum DenTheme {

    // MARK: - Colors

    static let accent = Color(hex: "#F59E0B")
    static let accentUI = UIColor(hex: "#F59E0B")

    static let accentMuted = Color(hex: "#F59E0B").opacity(0.15)
    static let accentMutedUI = UIColor(hex: "#F59E0B").withAlphaComponent(0.15)

    static let cardBackground = Color(.secondarySystemGroupedBackground)
    static let listBackground = Color(.systemGroupedBackground)

    static let pinnedBadge = Color(hex: "#F59E0B")
    static let deleteRed = Color(.systemRed)

    // MARK: - Typography (SF Pro everywhere — no monospace)

    static let titleFont: Font = .system(size: 17, weight: .semibold)
    static let bodyFont: Font = .system(size: 15, weight: .regular)
    static let captionFont: Font = .system(size: 13, weight: .regular)
    static let timestampFont: Font = .system(size: 12, weight: .regular)
    static let headingFont: Font = .system(size: 20, weight: .bold)
    static let largeTitleFont: Font = .system(size: 28, weight: .bold)

    // MARK: - Spacing

    static let cardPadding: CGFloat = 14
    static let listSpacing: CGFloat = 6
    static let sectionSpacing: CGFloat = 20
    static let horizontalInset: CGFloat = 16

    // MARK: - Corner Radius

    static let cardRadius: CGFloat = 14
    static let buttonRadius: CGFloat = 22
    static let pillRadius: CGFloat = 100

    // MARK: - Animations

    static let springSnappy: Animation = .spring(duration: 0.4, bounce: 0.15)
    static let springBouncy: Animation = .spring(duration: 0.5, bounce: 0.3)
    static let springGentle: Animation = .spring(duration: 0.6, bounce: 0.2)
    static let springFast: Animation = .spring(duration: 0.3, bounce: 0.1)

    static let springAnimation: Animation = springSnappy

    // MARK: - Haptics

    @MainActor static func hapticLight() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @MainActor static func hapticMedium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    @MainActor static func hapticHeavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    @MainActor static func hapticSuccess() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    @MainActor static func hapticWarning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    // MARK: - Shadow

    static let cardShadowColor = Color.black.opacity(0.08)
    static let cardShadowRadius: CGFloat = 8
    static let cardShadowY: CGFloat = 2

    static let floatingShadowColor = Color.black.opacity(0.18)
    static let floatingShadowRadius: CGFloat = 16
    static let floatingShadowY: CGFloat = 6
}
