import WidgetKit

/// Single entry point for the whole widget extension — every Widget this
/// target hosts is listed here. A WidgetKit extension only gets one
/// `@main`, so PrayerWidget/DuaOfDayWidget/DhikrOfDayWidget/
/// VerseOfDayWidget each stay in their own file without one of their own.
@main
struct TakwaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PrayerWidget()
        DuaOfDayWidget()
        DhikrOfDayWidget()
        VerseOfDayWidget()
    }
}
