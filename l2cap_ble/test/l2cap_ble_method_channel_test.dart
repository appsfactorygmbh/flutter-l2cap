import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:l2cap_ble/l2cap_ble_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelL2capBle platform = MethodChannelL2capBle();
  const MethodChannel channel = MethodChannel('l2cap_ble');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return true;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('connectToDevice', () async {
    expect(await platform.connectToDevice('123'), true);
  });
}
