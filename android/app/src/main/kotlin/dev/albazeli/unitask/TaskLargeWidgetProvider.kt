package dev.albazeli.unitask

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews
import android.content.SharedPreferences
import es.antonborri.home_widget.HomeWidgetProvider

class TaskLargeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.task_widget_large).apply {
                val count = widgetData.getInt("task_count", 0)
                
                if (count == 0) {
                    // Hide all or show empty state could be handled here
                    // For now we just show empty strings as per widgetData defaults
                }

                val rowIds = arrayOf(R.id.task_item_0, R.id.task_item_1, R.id.task_item_2, R.id.task_item_3, R.id.task_item_4)
                val titleIds = arrayOf(R.id.task_0_title, R.id.task_1_title, R.id.task_2_title, R.id.task_3_title, R.id.task_4_title)
                val timeIds = arrayOf(R.id.task_0_time, R.id.task_1_time, R.id.task_2_time, R.id.task_3_time, R.id.task_4_time)
                val weightIds = arrayOf(R.id.task_0_weight, R.id.task_1_weight, R.id.task_2_weight, R.id.task_3_weight, R.id.task_4_weight)
                val typeIds = arrayOf(R.id.task_0_type, R.id.task_1_type, R.id.task_2_type, R.id.task_3_type, R.id.task_4_type)

                for (i in 0 until 5) {
                    if (i < count) {
                        setViewVisibility(rowIds[i], View.VISIBLE)
                        setTextViewText(titleIds[i], widgetData.getString("task_${i}_title", "") ?: "")
                        setTextViewText(timeIds[i], widgetData.getString("task_${i}_time", "") ?: "")
                        setTextViewText(weightIds[i], widgetData.getString("task_${i}_weight", "") ?: "")
                        setTextViewText(typeIds[i], widgetData.getString("task_${i}_type", "") ?: "")
                    } else {
                        setViewVisibility(rowIds[i], View.GONE)
                    }
                }
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
