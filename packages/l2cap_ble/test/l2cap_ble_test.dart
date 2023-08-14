import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:l2cap_ble/l2cap_ble.dart';
import 'package:l2cap_ble/l2cap_ble_method_channel.dart';
import 'package:l2cap_ble/l2cap_ble_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockL2capBlePlatform with MockPlatformInterfaceMixin implements L2capBlePlatform {
  @override
  Future<bool> connectToDevice(String deviceId)async {
    return true;
  }

  @override
  Future<bool> createL2capChannel(int psm) {
    throw UnimplementedError();
  }

  @override
  Future<bool> disconnectFromDevice(String deviceId) {
    throw UnimplementedError();
  }

  @override
  Stream<L2CapConnectionState> getConnectionState() {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> sendMessage(Uint8List message) {
    throw UnimplementedError();
  }
}

void main() {
  final L2capBlePlatform initialPlatform = L2capBlePlatform.instance;

  test('$MethodChannelL2capBle is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelL2capBle>());
  });

  test('connectToDevice', () async {
    L2capBle l2capBlePlugin = L2capBle();
    MockL2capBlePlatform fakePlatform = MockL2capBlePlatform();
    L2capBlePlatform.instance = fakePlatform;

    expect(await l2capBlePlugin.connectToDevice('123'), true);
  });
}
