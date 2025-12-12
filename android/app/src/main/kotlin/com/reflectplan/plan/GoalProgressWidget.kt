package com.reflectplan.plan

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GoalProgressWidget : AppWidgetProvider() {
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }

    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
    
    companion object {
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.goal_progress_widget)
            
            // Get data from shared preferences
            val topGoalName = widgetData.getString("top_goal_name", "No active goals") ?: "No active goals"
            val topGoalProgress = widgetData.getInt("top_goal_progress", 0)
            val topGoalCategory = widgetData.getString("top_goal_category", "") ?: ""
            val activeGoals = widgetData.getInt("active_goals", 0)
            val completedGoals = widgetData.getInt("completed_goals", 0)
            val habitsCompleted = widgetData.getInt("habits_completed", 0)
            val habitsTotal = widgetData.getInt("habits_total", 0)
            val habitProgress = widgetData.getInt("habit_progress", 0)
            
            // Update views
            views.setTextViewText(R.id.top_goal_name, topGoalName)
            views.setTextViewText(R.id.top_goal_progress, "$topGoalProgress%")
            views.setTextViewText(R.id.top_goal_category, topGoalCategory.ifEmpty { "Goal" })
            views.setProgressBar(R.id.progress_bar, 100, topGoalProgress, false)
            
            views.setTextViewText(R.id.active_goals, activeGoals.toString())
            views.setTextViewText(R.id.completed_goals, completedGoals.toString())
            views.setTextViewText(R.id.habits_today, "$habitsCompleted/$habitsTotal")
            views.setTextViewText(R.id.habit_progress, "$habitProgress%")
            
            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
