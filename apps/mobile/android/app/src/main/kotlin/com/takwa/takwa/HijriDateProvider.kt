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
 * 4×2 Hijri-date widget — today's Hijri day number, month (teal pill) and
 * the weekday • Gregorian line, framed by a centered rub el hizb motif.
 *
 * Reads the same `prayer_widget_data` JSON the prayer widgets read
 * (PrayerHomeWidgetService, Dart); the `hijri` field arrives as
 * "<day> <month name>" (e.g. "1 ربيع الآخر"), so this class only splits
 * it back apart — no Hijri math of its own. That also means it refreshes
 * for free on every prayer-time push and every armed alarm.
 */
class HijriDateProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = parseData(widgetData.getString(DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.hijri_date_widget)
            views.setOnClickPendingIntent(
                R.id.hijri_widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            if (data == null) {
                views.setViewVisibility(R.id.hijri_widget_content, View.GONE)
                views.setViewVisibility(R.id.hijri_widget_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.hijri_widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.hijri_widget_empty, View.GONE)
                bindContent(views, data)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun bindContent(views: RemoteViews, data: JSONObject) {
        val hijri = data.optString("hijri")
        val day = hijri.substringBefore(' ')
        val month = hijri.substringAfter(' ', "")
        views.setTextViewText(R.id.hijri_widget_day, day)
        views.setTextViewText(R.id.hijri_widget_month, month)
        views.setViewVisibility(
            R.id.hijri_widget_month,
            if (month.isEmpty()) View.GONE else View.VISIBLE,
        )
        views.setTextViewText(R.id.hijri_widget_weekday, data.optString("weekday"))
        views.setTextViewText(R.id.hijri_widget_gregorian, data.optString("gregorian"))
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
    }
}
