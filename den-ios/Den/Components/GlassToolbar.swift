import SwiftUI
import UIKit

struct GlassEffectView: UIViewRepresentable {
    var cornerRadius: CGFloat = 14
    var isInteractive: Bool = false

    func makeUIView(context: Context) -> UIVisualEffectView {
        let effect: UIVisualEffect
        if #available(iOS 26.0, *) {
            let glassEffect = UIGlassEffect()
            glassEffect.isInteractive = isInteractive
            effect = glassEffect
        } else {
            effect = UIBlurEffect(style: .systemMaterial)
        }
        let view = UIVisualEffectView(effect: effect)
        view.clipsToBounds = true
        view.layer.cornerRadius = cornerRadius
        return view
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.layer.cornerRadius = cornerRadius
    }
}

struct GlassBackground: View {
    var cornerRadius: CGFloat = DenTheme.cardRadius
    var isInteractive: Bool = false

    var body: some View {
        if #available(iOS 26.0, *) {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .glassEffect(.regular.interactive(isInteractive))
        } else {
            GlassEffectView(cornerRadius: cornerRadius, isInteractive: isInteractive)
        }
    }
}

struct GlassToolbar<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            if #available(iOS 26.0, *) {
                GlassEffectContainer {
                    toolbarContent
                }
            } else {
                toolbarContent
                    .background(
                        GlassEffectView(cornerRadius: 0)
                            .ignoresSafeArea()
                    )
            }
        }
    }

    private var toolbarContent: some View {
        HStack(spacing: 0) {
            content
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, DenTheme.horizontalInset)
        .padding(.vertical, 10)
        .background(
            Group {
                if #unavailable(iOS 26.0) {
                    Color(.systemBackground).opacity(0.85)
                }
            }
        )
    }
}

struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                Group {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: DenTheme.cardRadius, style: .continuous)
                            .glassEffect(.regular)
                    } else {
                        RoundedRectangle(cornerRadius: DenTheme.cardRadius, style: .continuous)
                            .fill(Color(.secondarySystemGroupedBackground))
                    }
                }
            )
    }
}

struct GlassButtonStyle: ButtonStyle {
    var cornerRadius: CGFloat = DenTheme.buttonRadius

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(DenTheme.springSnappy, value: configuration.isPressed)
            .background(
                Group {
                    if #available(iOS 26.0, *) {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .glassEffect(.regular.interactive())
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                            .shadow(
                                color: DenTheme.cardShadowColor,
                                radius: DenTheme.cardShadowRadius,
                                y: DenTheme.cardShadowY
                            )
                    }
                }
            )
    }
}
