package dev.albazeli.unitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class CountdownWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.countdown_widget).apply {
                
                val name = widgetData.getString("next_class_name", "No Classes")
                val code = widgetData.getString("next_class_code", "")
                val type = widgetData.getString("next_class_type", "")
                val section = widgetData.getString("next_class_section", "")
                val room = widgetData.getString("next_class_room", "TBA")
                val time = widgetData.getString("next_class_time", "")
                val countdown = widgetData.getString("next_class_countdown", "N/A")

                setTextViewText(R.id.widget_course_title, if (code.isNotEmpty()) "$code - $name" else name)
                setTextViewText(R.id.widget_class_details, "$type - $section")
                setTextViewText(R.id.widget_time, time)
                setTextViewText(R.id.widget_room, room)
                setTextViewText(R.id.widget_countdown, "Starts in $countdown")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
