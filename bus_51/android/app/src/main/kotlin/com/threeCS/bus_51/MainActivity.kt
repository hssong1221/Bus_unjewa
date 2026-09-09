package com.threeCS.bus_51

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 도착 알림 권한 다이얼로그의 "설정 열기": 이 앱의 알림 설정 화면으로 이동한다.
        // 별도 패키지(app_settings 등)는 Kotlin Gradle Plugin 을 직접 써서 Flutter 가 경고하므로 직접 연다
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SETTINGS_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> {
                        startActivity(notificationSettingsIntent())
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun notificationSettingsIntent(): Intent {
        val intent = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
        } else {
            // Android 7 (API 24~25): 공식 상수가 없던 시절의 액션과 extra 이름
            Intent("android.settings.APP_NOTIFICATION_SETTINGS")
                .putExtra("app_package", packageName)
                .putExtra("app_uid", applicationInfo.uid)
        }
        return intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }

    companion object {
        private const val SETTINGS_CHANNEL = "bus_51/settings"
    }
}
