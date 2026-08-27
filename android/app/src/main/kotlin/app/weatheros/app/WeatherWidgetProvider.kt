package app.weatheros.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import org.json.JSONObject

class WeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.weather_widget_layout)

        // Read cached weather from Flutter shared preferences
        try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val jsonString = prefs.getString("flutter.weatheros_cached_weather_payload", null)
            if (!jsonString.isNullOrEmpty()) {
                val json = JSONObject(jsonString)
                val location = json.optString("location", "Woonsocket, RI")
                val temp = json.optDouble("temperature", 71.0).toInt()
                val condition = json.optString("condition", "rain").replaceFirstChar { it.uppercase() }
                val feelsLike = json.optDouble("feelsLike", 69.0).toInt()
                val high = json.optDouble("high", 72.0).toInt()
                val low = json.optDouble("low", 62.0).toInt()

                views.setTextViewText(R.id.widget_location, location)
                views.setTextViewText(R.id.widget_temperature, "$temp°")
                views.setTextViewText(R.id.widget_condition, "$condition • Feels like $feelsLike°")
                views.setTextViewText(R.id.widget_high_low, "H $high°   L $low°")
            }
        } catch (_: Exception) {
            // Graceful fallback to default layout strings
        }

        // Click to launch main app
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        // Update widget
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}
