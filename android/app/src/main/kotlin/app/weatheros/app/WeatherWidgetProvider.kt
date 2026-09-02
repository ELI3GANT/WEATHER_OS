package app.weatheros.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.ComponentName
import android.widget.RemoteViews
import org.json.JSONObject

class WeatherWidgetProvider : AppWidgetProvider() {

    companion object {
        fun updateAllWidgets(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val component = ComponentName(context, WeatherWidgetProvider::class.java)
            val ids = manager.getAppWidgetIds(component)
            if (ids.isNotEmpty()) {
                WeatherWidgetProvider().onUpdate(context, manager, ids)
            }
        }
    }

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

        views.setTextViewText(R.id.widget_location, "WeatherOS")
        views.setTextViewText(R.id.widget_glyph, "◌")
        views.setTextViewText(R.id.widget_temperature, "—")
        views.setTextViewText(R.id.widget_condition, "Waiting for weather sync")
        views.setTextViewText(R.id.widget_high_low, "Open WeatherOS to sync")
        views.setTextViewText(R.id.widget_updated, "Waiting for first sync")

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
                views.setTextViewText(R.id.widget_glyph, weatherGlyph(condition))
                views.setTextViewText(R.id.widget_temperature, "$temp°")
                views.setTextViewText(R.id.widget_condition, "$condition • Feels like $feelsLike°")
                views.setTextViewText(R.id.widget_high_low, "H $high°   L $low°")
                val updatedAt = json.optLong("timestamp", 0L)
                val ageMinutes = if (updatedAt > 0L) {
                    ((System.currentTimeMillis() - updatedAt).coerceAtLeast(0L) / 60_000L)
                } else -1L
                views.setTextViewText(
                    R.id.widget_updated,
                    when {
                        ageMinutes < 0L -> "Waiting for first sync"
                        ageMinutes == 0L -> "Updated just now"
                        else -> "Updated ${ageMinutes}m ago"
                    }
                )
            }
        } catch (_: Exception) {
            views.setTextViewText(R.id.widget_condition, "Weather sync unavailable")
            views.setTextViewText(R.id.widget_updated, "Open WeatherOS to retry")
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

    private fun weatherGlyph(condition: String): String {
        val value = condition.lowercase()
        return when {
            value.contains("storm") || value.contains("thunder") -> "ϟ"
            value.contains("snow") || value.contains("sleet") -> "❄"
            value.contains("rain") || value.contains("drizzle") -> "☂"
            value.contains("fog") || value.contains("mist") || value.contains("haze") -> "≋"
            value.contains("partly") -> "◐"
            value.contains("cloud") || value.contains("overcast") -> "☁"
            value.contains("clear") || value.contains("sun") -> "☀"
            else -> "◌"
        }
    }
}
