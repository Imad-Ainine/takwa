import SwiftUI

/// Brand colors shared by every Takwa home-screen widget, mirroring
/// packages/takwa_ui/lib/src/theme/app_colors.dart's `AppColorsExtension`
/// (`.light` / `.dark`) so these widgets look like Takwa, not a one-off
/// palette invented for the widget.
///
/// WidgetKit has no hook into the *app's* own in-app theme setting — like
/// the Android side (`values-night/widget_colors.xml`), these follow the
/// system's light/dark appearance instead, resolved once per render via
/// `TakwaWidgetTheme.resolve(colorScheme)`.
struct TakwaWidgetTheme {
    let cardGradientStart: Color
    let cardGradientEnd: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    /// AA-contrast-safe gold for *text* — the raw brand gold fails contrast
    /// on the light card, same reasoning as `AppColorsExtension.goldText`.
    let gold: Color
    /// Same reasoning as `gold`, for teal (`AppColorsExtension.tealText`).
    let teal: Color
    let divider: Color
    /// Progress-bar track for the large prayer widget's countdown bar.
    let progressTrack: Color
    /// Brand gold→teal sheen laid over the card gradient — same ARGB as
    /// `AppColorsExtension.cardGradient`/Android's `widget_overlay_*`, see
    /// `TakwaWidgetBackgroundView`.
    let overlayGold: Color
    let overlayTeal: Color
    /// Rub el hizb corner motif stroke — same brand gold as `overlayGold`,
    /// just a touch more opaque so the outline actually reads.
    let motif: Color

    // ≈ AppColorsExtension.light
    static let light = TakwaWidgetTheme(
        cardGradientStart: Color(red: 1.00, green: 1.00, blue: 1.00), // card
        cardGradientEnd: Color(red: 0.953, green: 0.957, blue: 0.965), // card2/deep #F3F4F6
        border: Color(red: 0.886, green: 0.910, blue: 0.941), // #E2E8F0
        textPrimary: Color(red: 0.067, green: 0.094, blue: 0.153), // #111827
        textSecondary: Color(red: 0.294, green: 0.333, blue: 0.388), // #4B5563
        gold: Color(red: 0.420, green: 0.325, blue: 0.125), // goldText #6B5320
        teal: Color(red: 0.059, green: 0.361, blue: 0.341), // tealText #0F5C57
        divider: Color.black.opacity(0.1),
        progressTrack: Color.black.opacity(0.1),
        overlayGold: Color(red: 0.784, green: 0.663, blue: 0.431).opacity(0.0625), // #10C8A96E
        overlayTeal: Color(red: 0.227, green: 0.686, blue: 0.663).opacity(0.039), // #0A3AAFA9
        motif: Color(red: 0.784, green: 0.663, blue: 0.431).opacity(0.12)
    )

    // ≈ AppColorsExtension.dark
    static let dark = TakwaWidgetTheme(
        cardGradientStart: Color(red: 0.051, green: 0.067, blue: 0.090), // night #0D1117
        cardGradientEnd: Color(red: 0.118, green: 0.176, blue: 0.251), // card2 #1E2D40
        border: Color(red: 0.165, green: 0.227, blue: 0.314), // #2A3A50
        textPrimary: Color(red: 0.910, green: 0.929, blue: 0.953), // #E8EDF3
        textSecondary: Color(red: 0.561, green: 0.639, blue: 0.733), // #8FA3BB
        gold: Color(red: 0.784, green: 0.663, blue: 0.431), // gold #C8A96E
        teal: Color(red: 0.227, green: 0.686, blue: 0.663), // teal #3AAFA9
        divider: Color.white.opacity(0.15),
        progressTrack: Color.white.opacity(0.15),
        overlayGold: Color(red: 0.784, green: 0.663, blue: 0.431).opacity(0.125), // #20C8A96E
        overlayTeal: Color(red: 0.227, green: 0.686, blue: 0.663).opacity(0.051), // #0D3AAFA9
        motif: Color(red: 0.784, green: 0.663, blue: 0.431).opacity(0.15)
    )

    static func resolve(_ scheme: ColorScheme) -> TakwaWidgetTheme {
        scheme == .dark ? .dark : .light
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [cardGradientStart, cardGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The brand accent wash laid over `backgroundGradient` — see
    /// `TakwaWidgetBackgroundView`.
    var accentSheen: LinearGradient {
        LinearGradient(
            colors: [overlayGold, overlayTeal],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

/// Two squares, one rotated 45° over the other — the "rub el hizb" symbol
/// used throughout Islamic art (and to mark Quran section divisions).
/// Purely decorative: a low-opacity outline tucked into one corner behind
/// the real content, same idea as Android's `ic_widget_islamic_motif.xml`.
struct RubElHizbMotif: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.width * 0.18
        let square = CGRect(
            x: rect.minX + inset,
            y: rect.minY + inset,
            width: rect.width - inset * 2,
            height: rect.height - inset * 2
        )
        var path = Path()
        path.addRect(square)
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let rotation = CGAffineTransform(translationX: center.x, y: center.y)
            .rotated(by: .pi / 4)
            .translatedBy(x: -center.x, y: -center.y)
        path.addPath(Path(square), transform: rotation)
        return path
    }
}

/// Shared background for every Takwa home-screen widget: the brand card
/// gradient, the gold→teal accent sheen, and the corner motif — used via
/// `.containerBackground(for: .widget) { TakwaWidgetBackgroundView(theme:
/// theme) }` so it's declared once instead of per-widget.
struct TakwaWidgetBackgroundView: View {
    let theme: TakwaWidgetTheme

    var body: some View {
        ZStack {
            theme.backgroundGradient
            theme.accentSheen
            GeometryReader { geo in
                let size = min(geo.size.width, geo.size.height) * 1.05
                RubElHizbMotif()
                    .stroke(theme.motif, lineWidth: 2)
                    .frame(width: size, height: size)
                    .position(x: geo.size.width - size * 0.28, y: geo.size.height - size * 0.28)
            }
        }
    }
}
