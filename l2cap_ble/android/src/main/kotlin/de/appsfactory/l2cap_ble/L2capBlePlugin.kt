package de.appsfactory.l2cap_ble

import androidx.annotation.NonNull

import de.appsfactory.l2cap_ble.BleL2capImpl
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.Log
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.PluginRegistry.Registrar
import kotlin.Result as KResult

/** L2capBlePlugin */
class L2capBlePlugin : FlutterPlugin, MethodCallHandler, EventChannel.StreamHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel
    private var mEventSink: EventChannel.EventSink? = null
    private lateinit var bleL2capImpl: BleL2capImpl

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "l2cap_ble")
        channel.setMethodCallHandler(this)
        val eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "getConnectionState")
        eventChannel.setStreamHandler(this)
        bleL2capImpl = BleL2capImpl(flutterPluginBinding.applicationContext, Dispatchers.IO)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
       if (call.method == "connectToDevice") {
            CoroutineScope(Dispatchers.Main).launch {
                val macAddress: String = requireNotNull(call.argument("deviceId"))
                bleL2capImpl.connectToDevice(macAddress).collect { res: KResult<Boolean> ->
                    Log.d("L2capBlePlugin", "connectToDevice: $res")
                    res.mapToResult(result)
                }
            }
        } else if (call.method == "disconnectFromDevice") {
            CoroutineScope(Dispatchers.Main).launch {
                bleL2capImpl.disconnectFromDevice().collect { res: KResult<Boolean> ->
                    Log.d("L2capBlePlugin", "disconnectFromDevice: $res")
                    res.mapToResult(result)
                }
            }
        } else if (call.method == "createL2capChannel") {
            CoroutineScope(Dispatchers.Main).launch {
                val psm: Int = requireNotNull(call.argument("psm"))
                bleL2capImpl.createL2capChannel(psm).collect { res: KResult<Boolean> ->
                    Log.d("L2capBlePlugin", "createL2capChannel: $res")
                    res.mapToResult(result)
                }
            }
        } else if (call.method == "sendMessage") {
            CoroutineScope(Dispatchers.Main).launch {
                val message: ByteArray = requireNotNull(call.argument("message"))
                bleL2capImpl.sendMessage(message).collect { res: KResult<ByteArray> ->
                    Log.d("L2capBlePlugin", "sendMessage: $res")
                    res.mapToResult(result)
                }
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onCancel(arguments: Any?) {
        mEventSink = null
    }

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        CoroutineScope(Dispatchers.Main).launch {
            bleL2capImpl.connectionState.collect { state: ConnectionState ->
                Log.d("L2capBlePlugin", "ConnectionState: $state")
                eventSink?.success(state.ordinal)
            }
        }
    }

    private suspend fun KResult<Any>.mapToResult(@NonNull result: Result) {
        withContext(Dispatchers.Main) {
            if (isSuccess) {
                result.success(getOrNull())
            } else {
                result.error("error", exceptionOrNull()?.message, null)
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }
}
