package id.basyainvestama.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.os.Build

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "basya/notifications")
            .setMethodCallHandler { call, result ->
                if (call.method != "show") {
                    result.notImplemented()
                } else {
                    try {
                        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
                        val channelId = "basya_messages"
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            manager.createNotificationChannel(NotificationChannel(
                                channelId, "Notifikasi Basya", NotificationManager.IMPORTANCE_HIGH
                            ))
                        }
                        val intent = Intent(this, MainActivity::class.java)
                            .addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                        val pendingIntent = PendingIntent.getActivity(this, 0, intent,
                            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
                        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            Notification.Builder(this, channelId)
                        } else {
                            Notification.Builder(this).setPriority(Notification.PRIORITY_HIGH)
                        }
                        val body = call.argument<String>("body") ?: ""
                        val notification = builder
                            .setSmallIcon(R.drawable.ic_notification)
                            .setContentTitle(call.argument<String>("title") ?: "Basya Investama")
                            .setContentText(body)
                            .setStyle(Notification.BigTextStyle().bigText(body))
                            .setContentIntent(pendingIntent)
                            .setAutoCancel(true)
                            .setDefaults(Notification.DEFAULT_ALL)
                            .build()
                        val tag = call.argument<String>("id") ?: System.nanoTime().toString()
                        manager.notify(tag, 0, notification)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("notification_failed", error.message, null)
                    }
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "basya/app_lifecycle")
            .setMethodCallHandler { call, result ->
                if (call.method == "moveToBackground") {
                    result.success(moveTaskToBack(true))
                } else {
                    result.notImplemented()
                }
            }
    }
}
