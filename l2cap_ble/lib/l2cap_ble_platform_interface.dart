import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'l2cap_ble.dart';
import 'l2cap_ble_method_channel.dart';

abstract class L2capBlePlatform extends PlatformInterface {
  /// Constructs a L2capBlePlatform.
  L2capBlePlatform() : super(token: _token);

  static final Object _token = Object();

  static L2capBlePlatform _instance = MethodChannelL2capBle();

  /// The default instance of [L2capBlePlatform] to use.
  ///
  /// Defaults to [MethodChannelL2capBle].
  static L2capBlePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [L2capBlePlatform] when
  /// they register themselves.
  static set instance(L2capBlePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> connectToDevice(String deviceId) {
    throw UnimplementedError('connectToDevice() has not been implemented.');
  }

  Future<bool> disconnectFromDevice(String deviceId) {
    throw UnimplementedError('disconnectFromDevice() has not been implemented.');
  }

  Stream<L2CapConnectionState> getConnectionState() {
    throw UnimplementedError('getConnectionState() has not been implemented.');
  }

  Future<bool> createL2capChannel(int psm) {
    throw UnimplementedError('createL2capChannel() has not been implemented.');
  }

  Future<Uint8List> sendMessage(Uint8List message) {
    throw UnimplementedError('sendMessage() has not been implemented.');
  }
}
