package dev.albazeli.unitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class TaskSmallWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_widget_small).apply {
                val title = widgetData.getString("next_task_title", "No Tasks") ?: "No Tasks"
                val subject = widgetData.getString("next_task_subject", "") ?: ""
                val countdown = widgetData.getString("next_task_countdown", "N/A") ?: "N/A"

                setTextViewText(R.id.widget_task_title, title)
                setTextViewText(R.id.widget_task_subject, subject)
                setTextViewText(R.id.widget_task_countdown, countdown)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
