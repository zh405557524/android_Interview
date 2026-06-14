package com.lxwx.narrate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        AliyunNumberAuthPlugin(this, flutterEngine.dartExecutor.binaryMessenger).register()
        AppUpdatePlugin(this, flutterEngine.dartExecutor.binaryMessenger).register()
    }
}
