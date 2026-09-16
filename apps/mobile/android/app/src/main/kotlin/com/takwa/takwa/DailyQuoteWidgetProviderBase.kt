package com.takwa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject

/**
 * Shared rendering for the "Dua of the Day" and "Dhikr of the Day"
 * home-screen widgets (`DuaOfDayWidgetProvider` / `DhikrOfDayWidgetProvider`
 * below) — same layout, same JSON shape, only the SharedPreferences key
 * they each read differs.
 *
 * Renders whatever JSON `DailyQuoteWidgetService` (Dart,
 * lib/core/home_widget/daily_quote_widget_service.dart) last wrote; this
 * class picks nothing itself — no "today's dua" logic lives here, only
 * formatting.
 */
abstract class DailyQuoteWidgetProviderBase(
    private val dataKey: String,
    /** Shown only when nothing has ever been saved yet (fresh install,
     *  before the app has opened once) — not localized past Arabic/English
     *  detection, since the widget has no locale of its own to ask; the
     *  moment the app runs, real (correctly localized) data replaces it. */
    private val fallbackEmptyText: String,
) : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = parseData(widgetData.getString(dataKey, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.daily_quote_widget)
            views.setOnClickPendingIntent(
                R.id.daily_quote_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            if (data == null) {
                views.setViewVisibility(R.id.daily_quote_content, View.GONE)
                views.setViewVisibility(R.id.daily_quote_empty, View.VISIBLE)
                views.setTextViewText(R.id.daily_quote_empty, fallbackEmptyText)
            } else {
                views.setViewVisibility(R.id.daily_quote_content, View.VISIBLE)
                views.setViewVisibility(R.id.daily_quote_empty, View.GONE)
                bindContent(views, data)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindContent(views: RemoteViews, data: JSONObject) {
        views.setTextViewText(R.id.daily_quote_emoji, data.optString("titleEmoji"))
        views.setTextViewText(R.id.daily_quote_title, data.optString("title"))
        views.setTextViewText(R.id.daily_quote_text, data.optString("text"))

        val subtitle = data.optString("subtitle")
        if (subtitle.isNullOrEmpty()) {
            views.setViewVisibility(R.id.daily_quote_subtitle, View.GONE)
        } else {
            views.setViewVisibility(R.id.daily_quote_subtitle, View.VISIBLE)
            views.setTextViewText(R.id.daily_quote_subtitle, subtitle)
        }

        // Repetition pill (e.g. "×3") — only meaningful for adhkar, so
        // hidden whenever the count is 1 (duas always pass 1).
        val count = data.optInt("count", 1)
        if (count > 1) {
            views.setViewVisibility(R.id.daily_quote_count, View.VISIBLE)
            views.setTextViewText(R.id.daily_quote_count, "×$count")
        } else {
            views.setViewVisibility(R.id.daily_quote_count, View.GONE)
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
}

/** "Dua of the Day" — reads `dua_of_day_widget_data`. */
class DuaOfDayWidgetProvider :
    DailyQuoteWidgetProviderBase(
        dataKey = "dua_of_day_widget_data",
        fallbackEmptyText = "افتح تطبيق تقوى لعرض دعاء اليوم",
    )

/** "Dhikr of the Day" — reads `dhikr_of_day_widget_data`. */
class DhikrOfDayWidgetProvider :
    DailyQuoteWidgetProviderBase(
        dataKey = "dhikr_of_day_widget_data",
        fallbackEmptyText = "افتح تطبيق تقوى لعرض ذكر اليوم",
    )

/** "Verse of the Day" — reads `verse_of_day_widget_data`. */
class VerseOfDayWidgetProvider :
    DailyQuoteWidgetProviderBase(
        dataKey = "verse_of_day_widget_data",
        fallbackEmptyText = "افتح تطبيق تقوى لعرض آية اليوم",
    )
