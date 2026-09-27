import SwiftUI
import WidgetKit

// 4×2-equivalent Hijri-date widget — today's Hijri day number large in
// brand gold over a centered rub el hizb motif, the month in a teal pill,
// and the weekday • Gregorian line below.
//
// Reads the same `prayer_widget_data` JSON the prayer widgets read (see
// PrayerWidget.swift); the `hijri` field arrives as "<day> <month name>"
// (e.g. "1 ربيع الآخر"), split back apart here — no Hijri math of its own,
// mirroring Android's HijriDateProvider.kt.

// MARK: - Data model (subset of the prayer payload this widget renders)

private struct HijriDateData: Decodable {
    let isRtl: Bool
    let weekday: String
    let hijri: String
    let gregorian: String
}

// MARK: - Timeline

private struct HijriDateEntry: TimelineEntry {
    let date: Date
    let data: HijriDateData?
}

private struct HijriDateProvider: TimelineProvider {
    static let appGroupId = "group.com.takwa.PrayerWidget"
    static let dataKey = "prayer_widget_data"

    func placeholder(in context: Context) -> HijriDateEntry {
        HijriDateEntry(date: Date(), data: loadData())
    }

    func getSnapshot(in context: Context, completion: @escaping (HijriDateEntry) -> Void) {
        completion(HijriDateEntry(date: Date(), data: loadData()))
    }

    func getTimeline(
        in context: Context, completion: @escaping (Timeline<HijriDateEntry>) -> Void
    ) {
        let now = Date()
        let data = loadData()
        // The date rolls at local midnight — ask again right after it.
        let nextMidnight = Calendar.current.nextDate(
            after: now,
            matching: DateComponents(hour: 0, minute: 0),
            matchingPolicy: .nextTime
        ) ?? now.addingTimeInterval(24 * 3600)
        let reloadDate = data == nil ? now.addingTimeInterval(30 * 60) : nextMidnight
        completion(Timeline(entries: [HijriDateEntry(date: now, data: data)], policy: .after(reloadDate)))
    }

    private func loadData() -> HijriDateData? {
        guard
            let defaults = UserDefaults(suiteName: Self.appGroupId),
            let json = defaults.string(forKey: Self.dataKey),
            let jsonData = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(HijriDateData.self, from: jsonData)
    }
}

// MARK: - View

private struct HijriDateEntryView: View {
    let entry: HijriDateEntry
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let theme = TakwaWidgetTheme.resolve(colorScheme)
        Group {
            if let data = entry.data {
                let parts = data.hijri.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
                VStack(spacing: 6) {
                    Text(parts.first.map(String.init) ?? data.hijri)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(theme.gold)
                    if parts.count > 1 {
                        Text(String(parts[1]))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.teal)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 10).fill(theme.tealTint))
                    }
                    HStack(spacing: 6) {
                        Text(data.weekday)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(theme.textPrimary)
                        Text(data.gregorian)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    GeometryReader { geo in
                        let size = min(geo.size.width, geo.size.height) * 0.9
                        RubElHizbMotif()
                            .stroke(theme.motif, lineWidth: 2)
                            .frame(width: size, height: size)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2 - 8)
                    }
                }
                .environment(\.layoutDirection, data.isRtl ? .rightToLeft : .leftToRight)
            } else {
                Text("افتح تطبيق تقوى لعرض التاريخ الهجري")
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

struct HijriDateWidget: Widget {
    // Must match `PrayerHomeWidgetService.iOSHijriWidgetName` (Dart).
    let kind: String = "HijriDateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HijriDateProvider()) { entry in
            HijriDateEntryView(entry: entry)
        }
        .configurationDisplayName("التاريخ الهجري")
        .description("يعرض تاريخ اليوم بالتقويم الهجري مع الشهر الميلادي.")
        .supportedFamilies([.systemMedium])
    }
}
