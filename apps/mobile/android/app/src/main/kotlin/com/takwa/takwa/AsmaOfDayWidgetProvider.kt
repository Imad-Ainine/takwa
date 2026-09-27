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
 * 4×2 "Asma ul-Husna of the day" widget — one Name of Allah per day,
 * picked deterministically from the app's bundled `kAsmaData` by
 * DailyQuoteWidgetService (Dart) and pushed under
 * `asma_of_day_widget_data`; this class only renders it.
 */
class AsmaOfDayWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val data = parseData(widgetData.getString(DATA_KEY, null))

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.asma_widget)
            views.setOnClickPendingIntent(
                R.id.asma_widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )

            if (data == null) {
                views.setViewVisibility(R.id.asma_widget_content, View.GONE)
                views.setViewVisibility(R.id.asma_widget_empty, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.asma_widget_content, View.VISIBLE)
                views.setViewVisibility(R.id.asma_widget_empty, View.GONE)
                views.setTextViewText(R.id.asma_widget_title, data.optString("title"))
                views.setTextViewText(
                    R.id.asma_widget_number,
                    "${data.optInt("number")}/99",
                )
                views.setTextViewText(R.id.asma_widget_name, data.optString("name"))
                views.setTextViewText(R.id.asma_widget_meaning, data.optString("meaning"))
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

    companion object {
        private const val DATA_KEY = "asma_of_day_widget_data"
    }
}
