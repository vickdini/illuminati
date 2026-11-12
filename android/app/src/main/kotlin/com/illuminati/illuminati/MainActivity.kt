package com.illuminati.illuminati

import android.content.Intent
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // App updates (lib/services/update_service.dart): opens the system
        // installer for a downloaded APK. Android asks the user to confirm,
        // and the first time to allow installs from Illuminati.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "illuminati/update")
            .setMethodCallHandler { call, result ->
                if (call.method != "install") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                try {
                    val apk = File(call.argument<String>("path")!!)
                    val uri = FileProvider.getUriForFile(this, "$packageName.updates", apk)
                    startActivity(
                        Intent(Intent.ACTION_VIEW)
                            .setDataAndType(uri, "application/vnd.android.package-archive")
                            .addFlags(
                                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                                    Intent.FLAG_ACTIVITY_NEW_TASK,
                            ),
                    )
                    result.success(null)
                } catch (e: Exception) {
                    result.error("install", e.message, null)
                }
            }
    }
}
