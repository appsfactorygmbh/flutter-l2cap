import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:native_ble_impl/presentation/connection_page.dart';
import 'package:native_ble_impl/services/ble_scanner.dart';
import 'package:native_ble_impl/services/providers.dart';

import 'app_text_button.dart';

class ScanPage extends HookConsumerWidget {
  const ScanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanner = ref.watch(scannerProvider);
    final bleStatus = ref.watch(bleStatusProvider).value;
    useEffect(() {
      scanner.startScan([]);
      return scanner.stopScan;
    }, const []);
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scanner'),
        ),
        body: StreamBuilder<BleScannerState>(
            stream: scanner.state,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final isScanning = snapshot.data!.scanIsInProgress;
                final state = snapshot.data!;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Text('ble status $bleStatus'),
                      AppTextButton(
                          onPressed: () {
                            if (isScanning) {
                              scanner.stopScan();
                            } else {
                              scanner.startScan([]);
                            }
                          },
                          text: isScanning ? 'Stop Scan' : 'Start Scan'),
                      if (!state.scanIsInProgress)
                        const Text('Scan is stopped')
                      else
                        Column(
                            children: state.discoveredDevices
                                .map((e) => Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            child: Column(
                                              children: [
                                                Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [const Text('id'), Expanded(child: Text(e.id, textAlign: TextAlign.end))]),
                                                const SizedBox(height: 10),
                                                Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [const Text('name'), Expanded(child: Text(e.name, textAlign: TextAlign.end))])
                                              ],
                                            ),
                                          ),
                                        ),
                                        AppTextButton(
                                            onPressed: () {
                                              scanner.stopScan();
                                              Navigator.of(context).push(MaterialPageRoute(builder: (context) => ConnectionPage(device: e)));
                                            },
                                            text: 'connect'),
                                      ],
                                    ))
                                .toList()),
                    ],
                  ),
                );
              } else {
                return const Text('Scan state is unknown');
              }
            }),
      ),
    );
  }
}
