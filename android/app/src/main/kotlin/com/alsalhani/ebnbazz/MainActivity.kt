package com.alsalhani.ebnbazz

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {
    private var photoPickerHandler: StudentPhotoPickerHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        photoPickerHandler = StudentPhotoPickerHandler(this).also {
            it.attachTo(flutterEngine)
        }
    }
}
