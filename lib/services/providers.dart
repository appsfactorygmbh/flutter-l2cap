import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_logger.dart';
import 'ble_scanner.dart';
import 'ble_status_monitor.dart';

final bleProvider = Provider<FlutterReactiveBle>((ref) {
  return FlutterReactiveBle();
});

final bleLoggerProvider = Provider<BleLogger>((ref) {
  return BleLogger(ble: ref.watch(bleProvider));
});

final scannerProvider = Provider<BleScanner>((ref) {
  return BleScanner(ble: ref.watch(bleProvider), logMessage: ref.watch(bleLoggerProvider).addToLog);
});

final monitorProvider = Provider<BleStatusMonitor>((ref) {
  return BleStatusMonitor(ref.watch(bleProvider));
});

final bleScannerStateProvider = StreamProvider<BleScannerState?>((ref) async* {
  yield const BleScannerState(
    discoveredDevices: [],
    scanIsInProgress: false,
  );
  yield* ref.watch(scannerProvider).state;
});

final bleStatusProvider = StreamProvider<BleStatus?>((ref) async* {
  yield BleStatus.unknown;
  yield* ref.watch(monitorProvider).state;
});
