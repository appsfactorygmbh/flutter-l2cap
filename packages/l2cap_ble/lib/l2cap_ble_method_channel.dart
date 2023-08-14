import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:l2cap_ble/l2cap_ble.dart';

import 'l2cap_ble_platform_interface.dart';

/// An implementation of [L2capBlePlatform] that uses method channels.
class MethodChannelL2capBle extends L2capBlePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('l2cap_ble');

 @override
  Future<bool> connectToDevice(String deviceId) async {
    final success = await methodChannel.invokeMethod<bool>('connectToDevice', {'deviceId': deviceId});
    return success ?? false;
  }

  @override
  Future<bool> disconnectFromDevice(String deviceId) async {
    final success = await methodChannel.invokeMethod<bool>('disconnectFromDevice', {'deviceId': deviceId});
    return success ?? false;
  }

  @override
  Stream<L2CapConnectionState> getConnectionState() {
    final stream = const EventChannel('getConnectionState').receiveBroadcastStream().cast<int>();
    return stream.asyncMap((event) {
      debugPrint('new connection state is $event');
      switch (event) {
        case 0:
          return L2CapConnectionState.disconnected;
        case 1:
          return L2CapConnectionState.connecting;
        case 2:
          return L2CapConnectionState.connected;
        case 3:
          return L2CapConnectionState.disconnecting;
        case 4:
          return L2CapConnectionState.error;
        default:
          return L2CapConnectionState.error;
      }
    });
  }

  @override
  Future<bool> createL2capChannel(int psm) async {
    final success = await methodChannel.invokeMethod<bool>('createL2capChannel', {'psm': psm});
    return success ?? false;
  }

  @override
  Future<Uint8List> sendMessage(Uint8List message) async {
    final response = await methodChannel.invokeMethod<Uint8List>('sendMessage', {'message': message});
    return response ?? Uint8List.fromList([]);
  }
}
