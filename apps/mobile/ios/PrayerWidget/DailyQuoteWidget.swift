import SwiftUI
import WidgetKit

// Home-screen "Dua of the Day" / "Dhikr of the Day" / "Verse of the Day"
// widgets.
//
// All three read whatever JSON `DailyQuoteWidgetService` (Dart,
// lib/core/home_widget/daily_quote_widget_service.dart) last wrote into the
// shared App Group's UserDefaults — this file picks nothing itself, no
// "today's dua" logic lives here, only rendering. Same shared-extension
// setup as PrayerWidget; see SETUP.md.

// MARK: - Data model (mirrors the JSON payload written from Dart)

private struct DailyQuoteData: Decodable {
    let isRtl: Bool
    let titleEmoji: String
    let title: String
    let text: String
    let subtitle: String
    let count: Int
}

// MARK: - Timeline

private struct DailyQuoteEntry: TimelineEntry {
    let date: Date
    let data: DailyQuoteData?
}

/// Shared provider for both widgets — only the SharedPreferences/UserDefaults
/// key differs between them.
private struct DailyQuoteProvider: TimelineProvider {
    static let appGroupId = "group.com.takwa.PrayerWidget"
    let dataKey: String

    func placeholder(in context: Context) -> DailyQuoteEntry {
        DailyQuoteEntry(date: Date(), data: loadData())
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyQuoteEntry) -> Void) {
        completion(DailyQuoteEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyQuoteEntry>) -> Void) {
        let now = Date()
        let data = loadData()

        // The pick only changes once a day (see DailyQuoteWidgetService),
        // so one entry for "now" is enough — just ask again right after
        // midnight for tomorrow's pick, or soon if nothing was shared yet.
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 3600)
        let reloadDate = data == nil ? now.addingTimeInterval(30 * 60) : nextMidnight

        completion(
            Timeline(entries: [DailyQuoteEntry(date: now, data: data)], policy: .after(reloadDate))
        )
    }

    private func loadData() -> DailyQuoteData? {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupId),
            let json = defaults.string(forKey: dataKey),
            let jsonData = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(DailyQuoteData.self, from: jsonData)
    }
}

// MARK: - View

private struct DailyQuoteEntryView: View {
    let entry: DailyQuoteEntry
    let fallbackEmptyText: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = TakwaWidgetTheme.resolve(colorScheme)
        Group {
            if let data = entry.data {
                DailyQuoteContentView(data: data, theme: theme)
                    .environment(\.layoutDirection, data.isRtl ? .rightToLeft : .leftToRight)
            } else {
                Text(fallbackEmptyText)
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .containerBackground(for: .widget) { TakwaWidgetBackgroundView(theme: theme) }
    }
}

private struct DailyQuoteContentView: View {
    let data: DailyQuoteData
    let theme: TakwaWidgetTheme

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(data.titleEmoji).font(.system(size: 15))
                Text(data.title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.gold)
                Spacer()
                if data.count > 1 {
                    Text("×\(data.count)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.teal)
                }
            }
            Text(data.text)
                .font(.system(size: 15))
                .foregroundColor(theme.textPrimary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .lineLimit(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            if !data.subtitle.isEmpty {
                Text(data.subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
        }
        .padding(14)
    }
}

// MARK: - Widget declarations

struct DuaOfDayWidget: Widget {
    // Must match `DailyQuoteWidgetService.iOSDuaWidgetName` (Dart).
    let kind: String = "DuaOfDayWidget"
    private let fallbackEmptyText = "افتح تطبيق تقوى لعرض دعاء اليوم"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DailyQuoteProvider(dataKey: "dua_of_day_widget_data")
        ) { entry in
            DailyQuoteEntryView(entry: entry, fallbackEmptyText: fallbackEmptyText)
        }
        .configurationDisplayName("دعاء اليوم")
        .description("يعرض دعاءً مختاراً من أدعية القرآن والسنة، يتغير كل يوم.")
        .supportedFamilies([.systemMedium])
    }
}

struct DhikrOfDayWidget: Widget {
    // Must match `DailyQuoteWidgetService.iOSDhikrWidgetName` (Dart).
    let kind: String = "DhikrOfDayWidget"
    private let fallbackEmptyText = "افتح تطبيق تقوى لعرض ذكر اليوم"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DailyQuoteProvider(dataKey: "dhikr_of_day_widget_data")
        ) { entry in
            DailyQuoteEntryView(entry: entry, fallbackEmptyText: fallbackEmptyText)
        }
        .configurationDisplayName("ذكر اليوم")
        .description("يعرض ذكراً مختاراً من الأذكار الصحيحة، يتغير كل يوم.")
        .supportedFamilies([.systemMedium])
    }
}

struct VerseOfDayWidget: Widget {
    // Must match `DailyQuoteWidgetService.iOSVerseWidgetName` (Dart).
    let kind: String = "VerseOfDayWidget"
    private let fallbackEmptyText = "افتح تطبيق تقوى لعرض آية اليوم"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DailyQuoteProvider(dataKey: "verse_of_day_widget_data")
        ) { entry in
            DailyQuoteEntryView(entry: entry, fallbackEmptyText: fallbackEmptyText)
        }
        .configurationDisplayName("آية اليوم")
        .description("يعرض آية مختارة من القرآن الكريم، تتغير كل يوم.")
        .supportedFamilies([.systemMedium])
    }
}
