package app.weatheros.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Build
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "tech.onlytrueperspective.weatheros/watch_sync"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateAndroidWidget" -> {
                        WeatherWidgetProvider.updateAllWidgets(this)
                        result.success(null)
                    }
                    "pinAndroidWidget" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            val manager = getSystemService(AppWidgetManager::class.java)
                            val provider = ComponentName(this, WeatherWidgetProvider::class.java)
                            if (manager.isRequestPinAppWidgetSupported) {
                                manager.requestPinAppWidget(provider, null, null)
                                result.success(true)
                                return@setMethodCallHandler
                            }
                        }
                        result.success(false)
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
