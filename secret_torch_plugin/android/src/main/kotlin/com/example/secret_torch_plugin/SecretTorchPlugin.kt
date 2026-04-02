package com.example.secret_torch_plugin

import android.content.Context
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SecretTorchPlugin */
class SecretTorchPlugin :
    FlutterPlugin,
    MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var cameraManager: CameraManager
    private var cameraIdWithFlash: String? = null
    private var torchEnabled = false

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "secret_torch_plugin")
        channel.setMethodCallHandler(this)
        cameraManager =
            flutterPluginBinding.applicationContext.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        cameraIdWithFlash = findCameraWithFlash(cameraManager)
    }

    override fun onMethodCall(
        call: MethodCall,
        result: Result
    ) {
        when (call.method) {
            "toggleTorch" -> toggleTorch(result)
            "setTorch" -> setTorch(call.argument<Boolean>("enabled") == true, result)
            else -> result.notImplemented()
        }
    }

    private fun toggleTorch(result: Result) {
        val cameraId = cameraIdWithFlash
        if (cameraId == null) {
            result.error("UNAVAILABLE", "Ліхтарик недоступний на цьому пристрої", null)
            return
        }

        try {
            torchEnabled = !torchEnabled
            cameraManager.setTorchMode(cameraId, torchEnabled)
            result.success(torchEnabled)
        } catch (securityException: SecurityException) {
            result.error("NO_PERMISSION", "Немає дозволу для керування ліхтариком", null)
        } catch (exception: Exception) {
            result.error("TOGGLE_FAILED", exception.localizedMessage, null)
        }
    }

    private fun setTorch(
        enabled: Boolean,
        result: Result
    ) {
        val cameraId = cameraIdWithFlash
        if (cameraId == null) {
            result.error("UNAVAILABLE", "Ліхтарик недоступний на цьому пристрої", null)
            return
        }

        try {
            torchEnabled = enabled
            cameraManager.setTorchMode(cameraId, enabled)
            result.success(torchEnabled)
        } catch (securityException: SecurityException) {
            result.error("NO_PERMISSION", "Немає дозволу для керування ліхтариком", null)
        } catch (exception: Exception) {
            result.error("SET_FAILED", exception.localizedMessage, null)
        }
    }

    private fun findCameraWithFlash(cameraManager: CameraManager): String? {
        for (cameraId in cameraManager.cameraIdList) {
            val characteristics = cameraManager.getCameraCharacteristics(cameraId)
            val hasFlash =
                characteristics.get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
            if (hasFlash) {
                return cameraId
            }
        }
        return null
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        val cameraId = cameraIdWithFlash
        if (cameraId != null && torchEnabled) {
            try {
                cameraManager.setTorchMode(cameraId, false)
            } catch (_: Exception) {
            }
        }
        channel.setMethodCallHandler(null)
    }
}
