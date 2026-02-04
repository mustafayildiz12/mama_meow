package com.yildiz.mama_meow

import android.app.AlarmManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: AudioServiceActivity() {  // ← DEĞİŞİKLİK BURASI
  private val CHANNEL = "exact_alarm_permission"

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    
    Log.d("MainActivity", "🔥 configureFlutterEngine ÇALIŞTI!")
    Log.d("MainActivity", "🔥 MethodChannel kuruluyor: $CHANNEL")
    
    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
      .setMethodCallHandler { call, result ->
        Log.d("MainActivity", "🔥 Method çağrıldı: ${call.method}")
        
        when (call.method) {
          "canScheduleExactAlarms" -> {
            val canSchedule = canScheduleExactAlarms()
            Log.d("MainActivity", "🔥 canScheduleExactAlarms sonuç: $canSchedule")
            result.success(canSchedule)
          }
          "requestExactAlarmPermission" -> {
            Log.d("MainActivity", "🔥 requestExactAlarmPermission çağrıldı")
            requestExactAlarmPermission()
            result.success(true)
          }
          else -> {
            Log.w("MainActivity", "⚠️ Bilinmeyen method: ${call.method}")
            result.notImplemented()
          }
        }
      }
    
    Log.d("MainActivity", "✅ MethodChannel kurulumu tamamlandı")
  }

  private fun canScheduleExactAlarms(): Boolean {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return true
    val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    return am.canScheduleExactAlarms()
  }

  private fun requestExactAlarmPermission() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) return
    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
    startActivity(intent)
  }
}