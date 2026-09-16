package com.takwa

import android.view.View
import android.widget.RemoteViews
import org.json.JSONArray

/**
 * 4×3 "large" size variant of the prayer-times widget — same data and same
 * 5 cells as [PrayerWidgetProvider] (reused via subclassing, not
 * duplicated), plus a countdown row to the next prayer that only this
 * bigger layout has room for. See prayer_widget_large.xml.
 *
 * The countdown is computed here, natively, from the same `timestampMs`
 * fields Dart already puts on every prayer entry — no new data needs to be
 * pushed from Flutter for this. It advances whenever this provider redraws
 * (on data push, on the alarms `HomeWidget.scheduleWidgetUpdates()` arms
 * for each remaining prayer, and on the 30-minute `updatePeriodMillis`
 * fallback) — a periodic approximation, not a per-second tick, same as
 * every other value in these widgets.
 */
class PrayerWidgetLargeProvider : PrayerWidgetProvider() {

    override val layoutRes: Int get() = R.layout.prayer_widget_large

    override fun bindExtra(views: RemoteViews, prayers: JSONArray, nextKey: String?) {
        val now = System.currentTimeMillis()
        var prevTime = -1L
        var nextTime = -1L
        var nextLabel = ""

        for (i in 0 until prayers.length()) {
            val prayer = prayers.getJSONObject(i)
            val time = prayer.optLong("timestampMs", -1L)
            if (time <= 0L) continue
            if (time <= now) {
                prevTime = time
            } else if (nextTime < 0L) {
                nextTime = time
                nextLabel = prayer.optString("label")
            }
        }

        if (nextTime < 0L) {
            // Nothing left to count down to today (after Isha, before
            // tomorrow's data has been pushed) — same empty treatment as
            // "no next prayer" gets everywhere else in this widget.
            views.setViewVisibility(R.id.prayer_widget_countdown, View.GONE)
            return
        }

        views.setViewVisibility(R.id.prayer_widget_countdown, View.VISIBLE)

        // No earlier prayer today yet (before Fajr) — fall back to a 6-hour
        // window so the bar still shows *some* progress rather than always
        // reading 0%.
        val start = if (prevTime > 0L) prevTime else nextTime - SIX_HOURS_MS
        val total = (nextTime - start).coerceAtLeast(1L)
        val elapsed = (now - start).coerceIn(0L, total)
        val progress = ((elapsed * 100L) / total).toInt().coerceIn(0, 100)
        views.setProgressBar(R.id.prayer_widget_progress, 100, progress, false)

        val remainingMinutes = ((nextTime - now) / 60_000L).coerceAtLeast(0L)
        val hours = remainingMinutes / 60
        val minutes = remainingMinutes % 60
        val remainingText = if (hours > 0) {
            "متبقٍ ${hours} س ${minutes} د لـ $nextLabel"
        } else {
            "متبقٍ ${minutes} د لـ $nextLabel"
        }
        views.setTextViewText(R.id.prayer_widget_countdown_text, remainingText)
    }

    companion object {
        private const val SIX_HOURS_MS = 6 * 60 * 60 * 1000L
    }
}
