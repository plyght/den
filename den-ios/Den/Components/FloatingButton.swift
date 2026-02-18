import SwiftUI
import UIKit

struct FloatingButton: View {
    var action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button {
            DenTheme.hapticMedium()
            action()
        } label: {
            ZStack {
                if #available(iOS 26.0, *) {
                    Circle()
                        .glassEffect(.regular.interactive())
                        .frame(width: 56, height: 56)
                } else {
                    Circle()
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: 56, height: 56)
                        .shadow(
                            color: DenTheme.floatingShadowColor,
                            radius: DenTheme.floatingShadowRadius,
                            y: DenTheme.floatingShadowY
                        )
                }

                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DenTheme.accent)
            }
        }
        .buttonStyle(FloatingButtonStyle())
        .shadow(
            color: DenTheme.floatingShadowColor,
            radius: DenTheme.floatingShadowRadius,
            y: DenTheme.floatingShadowY
        )
    }
}

private struct FloatingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.88 : 1.0)
            .animation(DenTheme.springBouncy, value: configuration.isPressed)
    }
}
