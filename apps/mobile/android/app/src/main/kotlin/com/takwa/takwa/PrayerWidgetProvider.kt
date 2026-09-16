package com.takwa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONArray
import org.json.JSONObject

/**
 * Home-screen prayer-times widget.
 *
 * Renders whatever JSON `PrayerHomeWidgetService` (Dart,
 * lib/core/home_widget/prayer_home_widget_service.dart) last wrote under the
 * `prayer_widget_data` key — this class does no prayer-time math or Hijri
 * conversion of its own, only formatting. It is redrawn by:
 *  - `HomeWidget.updateWidget()` right after Flutter saves new data;
 *  - the alarms `HomeWidget.scheduleWidgetUpdates()` arms for the day's
 *    remaining prayer times, so the "next prayer" highlight still advances
 *    while the app is closed;
 *  - the system's own `updatePeriodMillis` (prayer_widget_info.xml) as a
 *    30-minute fallback.
 *
 * `open`/`protected` throughout so [PrayerWidgetLargeProvider] can reuse
 * every bit of this — the 4×3 "large" size variant is the exact same data
 * and the exact same 5 cells, just with one extra countdown row that only
 * it knows how to draw.
 */
open class PrayerWidgetProvider : HomeWidgetProvider() {

    /** Which layout this size variant inflates — override for a bigger one. */
    protected open val layoutRes: Int get() = R.layout.prayer_widget

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = parseData(widgetData.getString(DATA_KEY, null))
        val colorDefault = ContextCompat.getColor(context, R.color.widget_text_primary)
        val colorHighlight = ContextCompat.getColor(context, R.color.widget_gold)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, layoutRes)
            views.setOnClickPendingIntent(
                R.id.prayer_widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            if (data == null) {
                views.setViewVisibility(R.id.prayer_widget_content, View.GONE)
                views.setViewVisibility(R.id.prayer_widget_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.prayer_widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.prayer_widget_empty, View.GONE)
                bindContent(views, data, colorDefault, colorHighlight)
            }

            appWidgetManager.updateAppWidget(widgetId, views)
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

    private fun bindContent(
        views: RemoteViews,
        data: JSONObject,
        colorDefault: Int,
        colorHighlight: Int,
    ) {
        views.setTextViewText(R.id.prayer_widget_hijri, data.optString("hijri"))
        views.setTextViewText(R.id.prayer_widget_gregorian, data.optString("gregorian"))
        views.setTextViewText(R.id.prayer_widget_weekday, data.optString("weekday"))

        val nextKey = if (data.isNull("nextKey")) null else data.getString("nextKey")
        val prayers: JSONArray = data.optJSONArray("prayers") ?: JSONArray()

        for (i in CELL_IDS.indices) {
            val (cellId, labelId, timeId) = CELL_IDS[i]
            if (i >= prayers.length()) {
                views.setViewVisibility(cellId, View.GONE)
                continue
            }

            views.setViewVisibility(cellId, View.VISIBLE)
            val prayer = prayers.getJSONObject(i)
            views.setTextViewText(labelId, prayer.optString("label"))
            views.setTextViewText(timeId, prayer.optString("time"))

            val isNext = nextKey != null && nextKey == prayer.optString("key", null)
            val color = if (isNext) colorHighlight else colorDefault
            views.setTextColor(labelId, color)
            views.setTextColor(timeId, color)
        }

        bindExtra(views, prayers, nextKey)
    }

    /**
     * Hook for a size variant to draw anything beyond the 5 cells above —
     * a no-op here, overridden by [PrayerWidgetLargeProvider] to fill in
     * the countdown-to-next-prayer row its layout has and this one
     * doesn't.
     */
    protected open fun bindExtra(views: RemoteViews, prayers: JSONArray, nextKey: String?) {}

    companion object {
        private const val DATA_KEY = "prayer_widget_data"

        /** (container id, label TextView id, time TextView id) per prayer slot. */
        internal val CELL_IDS = listOf(
            Triple(R.id.prayer_widget_cell_0, R.id.prayer_widget_label_0, R.id.prayer_widget_time_0),
            Triple(R.id.prayer_widget_cell_1, R.id.prayer_widget_label_1, R.id.prayer_widget_time_1),
            Triple(R.id.prayer_widget_cell_2, R.id.prayer_widget_label_2, R.id.prayer_widget_time_2),
            Triple(R.id.prayer_widget_cell_3, R.id.prayer_widget_label_3, R.id.prayer_widget_time_3),
            Triple(R.id.prayer_widget_cell_4, R.id.prayer_widget_label_4, R.id.prayer_widget_time_4),
        )
    }
}
