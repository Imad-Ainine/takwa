package com.takwa

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * 4×2 Ayat al-Kursi widget — fully static (Quran 2:255 is hardcoded in
 * ayat_al_kursi_widget.xml), so it shows the verse correctly even before
 * the app has ever been opened. All this class does is wire tap-to-open;
 * it extends HomeWidgetProvider anyway so the plugin's alarm re-arming
 * on boot/update applies to it like every other widget here.
 */
class AyatAlKursiWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.ayat_al_kursi_widget)
            views.setOnClickPendingIntent(
                R.id.ayat_kursi_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
