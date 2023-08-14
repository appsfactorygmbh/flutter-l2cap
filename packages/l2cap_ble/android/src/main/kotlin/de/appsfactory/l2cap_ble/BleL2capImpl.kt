package de.appsfactory.l2cap_ble

import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGatt
import android.bluetooth.BluetoothGattCallback
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothSocket
import android.content.Context
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.launch
import java.util.*
import kotlin.coroutines.coroutineContext


class BleL2capImpl(
    private val context: Context,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO,
) : BleL2cap {

    private val connectionStateSharedFlow = MutableSharedFlow<ConnectionState>()

    private val bluetoothManager: BluetoothManager? by lazy {
        context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager?
    }
    private val bluetoothAdapter: BluetoothAdapter? by lazy {
        bluetoothManager?.adapter
    }

    private var bluetoothDevice: BluetoothDevice? = null
    private var bluetoothGatt: BluetoothGatt? = null
    private var bluetoothSocket: BluetoothSocket? = null

    override val connectionState: Flow<ConnectionState> = connectionStateSharedFlow.asSharedFlow()

    @SuppressLint("MissingPermission")
    override fun connectToDevice(macAddress: String): Flow<Result<Boolean>> = flow {
        val result = try {
            bluetoothDevice = bluetoothAdapter?.getRemoteDevice(macAddress)
            if (bluetoothDevice == null) {
                throw Exception("Device with address: $macAddress not found")
            }
            val connectionStateChannel = Channel<ConnectionState>(Channel.BUFFERED)
            connectionStateChannel.trySend(ConnectionState.CONNECTING)
            val gattCallback = object : BluetoothGattCallback() {

                // Implement the necessary callback methods, like onConnectionStateChange, onServicesDiscovered, etc.
                override fun onConnectionStateChange(gatt: BluetoothGatt?, status: Int, newState: Int) {
                    super.onConnectionStateChange(gatt, status, newState)

                    when (newState) {
                        BluetoothGatt.STATE_CONNECTED -> {
                            connectionStateChannel.trySend(ConnectionState.CONNECTED)
                        }

                        BluetoothGatt.STATE_CONNECTING -> {
                            connectionStateChannel.trySend(ConnectionState.CONNECTING)
                        }

                        BluetoothGatt.STATE_DISCONNECTING -> {
                            connectionStateChannel.trySend(ConnectionState.DISCONNECTING)
                        }

                        BluetoothGatt.STATE_DISCONNECTED -> {
                            connectionStateChannel.trySend(ConnectionState.DISCONNECTED)
                        }
                    }
                }
            }
            CoroutineScope(coroutineContext).launch {
                for (state in connectionStateChannel) {
                    connectionStateSharedFlow.emit(state)
                }
            }
            bluetoothGatt = bluetoothDevice?.connectGatt(context, false, gattCallback)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
        emit(result)
    }.flowOn(ioDispatcher)

    @SuppressLint("MissingPermission")
    override fun disconnectFromDevice(): Flow<Result<Boolean>> = flow {
        val result = try {
            connectionStateSharedFlow.emit(ConnectionState.DISCONNECTING)
            bluetoothGatt?.disconnect()
            bluetoothGatt = null
            connectionStateSharedFlow.emit(ConnectionState.DISCONNECTED)
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
        emit(result)
    }.flowOn(ioDispatcher)

    @SuppressLint("MissingPermission")
    override fun createL2capChannel(psm: Int): Flow<Result<Boolean>> = flow {
        // You should check if the device supports opening an L2CAP channel.
        val result = try {
            bluetoothSocket = bluetoothDevice?.createInsecureL2capChannel(psm)
            if (bluetoothSocket == null) {
                throw Exception("Failed to create L2CAP channel")
            }
            bluetoothSocket?.connect()
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
        emit(result)
    }.flowOn(ioDispatcher)

    @SuppressLint("MissingPermission")
    override fun sendMessage(message: ByteArray): Flow<Result<ByteArray>> = flow {
        val result = try {
            if (bluetoothSocket == null) {
                throw Exception("Bluetooth socket is null")
            }
            bluetoothSocket?.outputStream?.write(message)
            // Now, we should read the response from the input stream
            val response = ByteArray(1024) // Adjust the size depending on the expected response
            val bytesRead = bluetoothSocket?.inputStream?.read(response)
            // It's important to note that the above read call is blocking.
            // You might want to wrap it with 'withTimeout' to prevent it from blocking indefinitely.
            bytesRead?.let {
                Result.success(response.copyOfRange(0, it))
            } ?: Result.failure(Exception("Failed to read response"))
        } catch (e: Exception) {
            Result.failure(e)
        }
        emit(result)
    }.flowOn(ioDispatcher)
}
