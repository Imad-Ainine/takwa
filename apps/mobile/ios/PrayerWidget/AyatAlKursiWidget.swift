import SwiftUI
import WidgetKit

// 4×2-equivalent Ayat al-Kursi widget — fully static (Quran 2:255 typed
// once below), so it renders correctly even on a fresh install before the
// app has ever opened. Mirrors Android's AyatAlKursiWidgetProvider.kt.

private struct StaticEntry: TimelineEntry {
    let date = Date()
}

private struct AyatAlKursiProvider: TimelineProvider {
    func placeholder(in context: Context) -> StaticEntry { StaticEntry() }

    func getSnapshot(in context: Context, completion: @escaping (StaticEntry) -> Void) {
        completion(StaticEntry())
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<StaticEntry>) -> Void
    ) {
        // Nothing ever changes — a daily reload keeps the widget warm at
        // negligible cost.
        let now = Date()
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 3600)
        completion(Timeline(entries: [StaticEntry()], policy: .after(nextMidnight)))
    }
}

private struct AyatAlKursiEntryView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = TakwaWidgetTheme.resolve(colorScheme)
        VStack(spacing: 8) {
            HStack {
                Text("🕌").font(.system(size: 14))
                Text("آية الكرسي")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.gold)
                Spacer()
            }
            LinearGradient(
                colors: [theme.gold, theme.teal.opacity(0.15)],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 36, height: 2)
            .clipShape(Capsule())
            .frame(maxWidth: .infinity, alignment: .leading)

            Text("اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ")
                .font(.system(size: 13))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("سورة البقرة، آية ٢٥٥")
                .font(.system(size: 11))
                .foregroundColor(theme.textSecondary)
        }
        .environment(\.layoutDirection, .rightToLeft)
        .padding(14)
        .containerBackground(for: .widget) { TakwaWidgetBackgroundView(theme: theme) }
    }
}

struct AyatAlKursiWidget: Widget {
    let kind: String = "AyatAlKursiWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AyatAlKursiProvider()) { _ in
            AyatAlKursiEntryView()
        }
        .configurationDisplayName("آية الكرسي")
        .description("يعرض آية الكرسي كاملة على شاشة الرئيسية.")
        .supportedFamilies([.systemMedium])
    }
}
