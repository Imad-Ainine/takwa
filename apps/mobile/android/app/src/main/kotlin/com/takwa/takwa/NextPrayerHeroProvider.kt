package com.takwa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * 2×2 "next prayer hero" widget — the single upcoming prayer rendered big
 * (emoji, name, time) over a gold countdown pill, Muslim-Pro-style.
 *
 * Reads the exact same `prayer_widget_data` JSON the 4×2/4×3 widgets read
 * (pushed by PrayerHomeWidgetService, Dart); the "next" prayer is resolved
 * here from the `timestampMs` fields the same way
 * [PrayerWidgetLargeProvider.bindExtra] does, so the tile stays correct on
 * every redraw without any extra data from Flutter. After Isha (nothing
 * left today) it falls back to showing the day's first prayer — tomorrow's
 * Fajr — with the countdown pill hidden.
 */
class NextPrayerHeroProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = parseData(widgetData.getString(DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.next_prayer_hero_widget)
            views.setOnClickPendingIntent(
                R.id.next_prayer_hero_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            val prayers = data?.optJSONArray("prayers")
            if (data == null || prayers == null || prayers.length() == 0) {
                views.setViewVisibility(R.id.next_prayer_hero_content, View.GONE)
                views.setViewVisibility(R.id.next_prayer_hero_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.next_prayer_hero_content, View.VISIBLE)
                views.setViewVisibility(R.id.next_prayer_hero_empty, View.GONE)
                bindContent(views, prayers)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindContent(views: RemoteViews, prayers: JSONArray) {
        val now = System.currentTimeMillis()
        var next: JSONObject? = null
        for (i in 0 until prayers.length()) {
            val prayer = prayers.getJSONObject(i)
            val time = prayer.optLong("timestampMs", -1L)
            if (time > now && next == null) next = prayer
        }
        // Nothing left today — show the day's first prayer (tomorrow's
        // Fajr) without a countdown rather than an empty tile.
        val shown = next ?: prayers.getJSONObject(0)

        views.setTextViewText(
            R.id.next_prayer_hero_emoji,
            EMOJIS[shown.optString("key")] ?: "",
        )
        views.setTextViewText(R.id.next_prayer_hero_label, shown.optString("label"))
        views.setTextViewText(R.id.next_prayer_hero_time, shown.optString("time"))

        if (next == null) {
            views.setViewVisibility(R.id.next_prayer_hero_countdown, View.GONE)
        } else {
            val remainingMinutes =
                ((next.optLong("timestampMs", now) - now) / 60_000L).coerceAtLeast(0L)
            val hours = remainingMinutes / 60
            val minutes = remainingMinutes % 60
            val text = if (hours > 0) {
                "متبقٍ ${hours} س ${minutes} د"
            } else {
                "متبقٍ ${minutes} د"
            }
            views.setViewVisibility(R.id.next_prayer_hero_countdown, View.VISIBLE)
            views.setTextViewText(R.id.next_prayer_hero_countdown, text)
        }
    }

    private fun parseData(json: String?): JSONObject? {
        if (json.isNullOrEmpty()) return null
        return try {
            JSONObject(json)
        } catch (e: Exception) {
            null
        }
    }

    companion object {
        private const val DATA_KEY = "prayer_widget_data"

        /** Same icons the 4×2/4×3 layouts hard-code per cell. */
        private val EMOJIS = mapOf(
            "fajr" to "🌅",
            "dhuhr" to "☀️",
            "asr" to "⛅",
            "maghrib" to "🌇",
            "isha" to "🌙",
        )
    }
}
