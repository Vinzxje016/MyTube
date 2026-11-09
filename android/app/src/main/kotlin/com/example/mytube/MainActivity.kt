package com.example.mytube

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private var pendingAvatarResult: MethodChannel.Result? = null
    private var paymentChannel: MethodChannel? = null

    companion object {
        private const val PICK_AVATAR_REQUEST = 7412
        private const val MAX_AVATAR_BYTES = 5L * 1024 * 1024
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.mytube/profile",
        ).setMethodCallHandler { call, result ->
            if (call.method != "pickAvatar") {
                result.notImplemented()
            } else if (pendingAvatarResult != null) {
                result.error("picker_busy", "Trình chọn ảnh đang được mở.", null)
            } else {
                pendingAvatarResult = result
                val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
                    type = "image/*"
                    addCategory(Intent.CATEGORY_OPENABLE)
                }
                try {
                    startActivityForResult(
                        Intent.createChooser(intent, "Chọn ảnh đại diện"),
                        PICK_AVATAR_REQUEST,
                    )
                } catch (error: Exception) {
                    pendingAvatarResult = null
                    result.error("picker_unavailable", error.message, null)
                }
            }
        }

        paymentChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.mytube/payment",
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                if (call.method == "getInitialPaymentUri") {
                    val launchIntent = intent
                    val paymentUri = launchIntent?.data?.takeIf(::isPaymentReturn)
                    if (paymentUri != null) setIntent(Intent(launchIntent).setData(null))
                    result.success(paymentUri?.toString())
                } else {
                    result.notImplemented()
                }
            }
        }

    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        intent.data?.takeIf(::isPaymentReturn)?.let { uri ->
            paymentChannel?.invokeMethod("paymentReturn", uri.toString())
        }
    }

    private fun isPaymentReturn(uri: Uri): Boolean =
        uri.scheme == "mytube" && uri.host == "payment-return"

    @Deprecated("Deprecated in Android, retained for compatibility with AudioServiceActivity")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_AVATAR_REQUEST) return

        val result = pendingAvatarResult ?: return
        pendingAvatarResult = null
        val uri: Uri? = if (resultCode == RESULT_OK) data?.data else null
        if (uri == null) {
            result.success(null)
            return
        }

        try {
            val fileSize = contentResolver.openAssetFileDescriptor(uri, "r")?.use {
                it.length
            }
            if (fileSize != null && fileSize > MAX_AVATAR_BYTES) {
                result.error("image_too_large", "Ảnh đại diện không được vượt quá 5 MB.", null)
                return
            }
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            val mimeType = contentResolver.getType(uri)
            if (bytes == null || mimeType == null) {
                result.error("image_unavailable", "Không thể đọc ảnh đã chọn.", null)
            } else {
                result.success(mapOf("bytes" to bytes, "mimeType" to mimeType))
            }
        } catch (error: Exception) {
            result.error("image_read_failed", error.message, null)
        }
    }
}
