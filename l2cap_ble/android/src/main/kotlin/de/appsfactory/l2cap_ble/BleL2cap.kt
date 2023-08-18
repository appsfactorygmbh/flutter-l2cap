package de.appsfactory.l2cap_ble

import kotlinx.coroutines.flow.Flow

interface BleL2cap {

    val connectionState: Flow<ConnectionState>

    fun connectToDevice(macAddress: String): Flow<Result<Boolean>>

    fun disconnectFromDevice(): Flow<Result<Boolean>>

    fun createL2capChannel(psm: Int): Flow<Result<Boolean>>

    fun sendMessage(message: ByteArray): Flow<Result<ByteArray>>
}

enum class ConnectionState {
    DISCONNECTED,
    CONNECTING,
    CONNECTED,
    DISCONNECTING,
    ERROR
}
