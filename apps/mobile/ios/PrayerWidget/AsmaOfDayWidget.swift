import SwiftUI
import WidgetKit

// 4×2-equivalent "Asma ul-Husna of the day" widget — one Name of Allah per
// day, picked deterministically from the app's bundled kAsmaData by
// DailyQuoteWidgetService (Dart) and pushed under `asma_of_day_widget_data`;
// this file only renders it. Mirrors Android's AsmaOfDayWidgetProvider.kt.

// MARK: - Data model (mirrors the JSON payload written from Dart)

private struct AsmaData: Decodable {
    let isRtl: Bool
    let title: String
    let number: Int
    let name: String
    let meaning: String
}

// MARK: - Timeline

private struct AsmaEntry: TimelineEntry {
    let date: Date
    let data: AsmaData?
}

private struct AsmaProvider: TimelineProvider {
    static let appGroupId = "group.com.takwa.PrayerWidget"
    static let dataKey = "asma_of_day_widget_data"

    func placeholder(in context: Context) -> AsmaEntry {
        AsmaEntry(date: Date(), data: loadData())
    }

    func getSnapshot(in context: Context, completion: @escaping (AsmaEntry) -> Void) {
        completion(AsmaEntry(date: Date(), data: loadData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AsmaEntry>) -> Void) {
        let now = Date()
        let data = loadData()
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 3600)
        let reloadDate = data == nil ? now.addingTimeInterval(30 * 60) : nextMidnight
        completion(Timeline(entries: [AsmaEntry(date: now, data: data)], policy: .after(reloadDate)))
    }

    private func loadData() -> AsmaData? {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupId),
            let json = defaults.string(forKey: Self.dataKey),
            let jsonData = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(AsmaData.self, from: jsonData)
    }
}

// MARK: - View

private struct AsmaEntryView: View {
    let entry: AsmaEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = TakwaWidgetTheme.resolve(colorScheme)
        Group {
            if let data = entry.data {
                VStack(spacing: 8) {
                    HStack {
                        Text("✨").font(.system(size: 14))
                        Text(data.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.gold)
                        Spacer()
                        Text("\(data.number)/99")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(theme.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 10).fill(theme.tealTint))
                    }
                    LinearGradient(
                        colors: [theme.gold, theme.teal.opacity(0.15)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: 36, height: 2)
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, alignment: .leading)

                    ZStack {
                        GeometryReader { geo in
                            let size = min(geo.size.width, geo.size.height) * 1.1
                            RubElHizbMotif()
                                .stroke(theme.motif, lineWidth: 2)
                                .frame(width: size, height: size)
                                .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        }
                        VStack(spacing: 6) {
                            Text(data.name)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(theme.gold)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                            Text(data.meaning)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .environment(\.layoutDirection, data.isRtl ? .rightToLeft : .leftToRight)
                .padding(14)
            } else {
                Text("افتح تطبيق تقوى لعرض اسم الله الحسنى")
                    .font(.caption)
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .containerBackground(for: .widget) { TakwaWidgetBackgroundView(theme: theme) }
    }
}

// MARK: - Widget declaration

struct AsmaOfDayWidget: Widget {
    // Must match `DailyQuoteWidgetService.iOSAsmaWidgetName` (Dart).
    let kind: String = "AsmaOfDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AsmaProvider()) { entry in
            AsmaEntryView(entry: entry)
        }
        .configurationDisplayName("اسم الله الحسنى")
        .description("يعرض اسمًا من أسماء الله الحسنى كل يوم، من بيانات التطبيق.")
        .supportedFamilies([.systemMedium])
    }
}
