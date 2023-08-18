import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:l2cap_ble/l2cap_ble.dart';
import 'package:native_ble_impl/presentation/app_text_button.dart';

const _psm = 0x80;

class ConnectionPage extends HookConsumerWidget {
  final DiscoveredDevice device;
  const ConnectionPage({super.key, required this.device});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ble = useMemoized(() => L2capBle(), const []);
    final lastMessage = useState<String>('');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Page'),
      ),
      body: StreamBuilder<L2CapConnectionState>(
        stream: ble.getConnectionState(),
        builder: (context, snapshot) {
          return Column(
            children: [
              Text('connection state: ${snapshot.data}'),
              AppTextButton(
                  onPressed: () {
                    ble.connectToDevice(device.id).then((value) => print(value));
                  },
                  text: 'connect'),
              AppTextButton(
                  onPressed: () {
                    ble.disconnectFromDevice(device.id).then((value) => print(value));
                  },
                  text: 'disconnect'),
              AppTextButton(
                  onPressed: () {
                    ble.createL2capChannel(_psm).then((value) {
                      print(value);
                    });
                  },
                  text: 'create Channel'),
              AppTextButton(
                  onPressed: () => ble.sendMessage(Uint8List.fromList([0X04, 0X00, 0X13, 0X00])).then((value) {
                        lastMessage.value = value.toString();
                        print(value);
                      }),
                  text: 'send message'),
              const Text('last message:'),
              Text(lastMessage.value),
            ],
          );
        },
      ),
    );
  }
}
