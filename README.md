# L2CAP Flutter Package

[![Pub Version](https://img.shields.io/pub/v/l2cap_ble.svg)](https://pub.dev/packages/l2cap_ble)
[![GitHub License](https://img.shields.io/github/license/your-username/l2cap-flutter-package)](https://github.com/your-username/l2cap-flutter-package/blob/main/LICENSE)

Effortlessly integrate L2CAP communication into your Flutter apps with the L2CAP Flutter package. Streamline Bluetooth device communication with a simplified and intuitive interface.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Installation

To use this package, add `l2cap_ble` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  l2cap_ble: ^latest_version
```

## Usage
Scan for Bluetooth Devices: Use your preferred Bluetooth scanning package to find and obtain the deviceId of the target device.

### Initialize L2CAP Communication:

```dart
final ble = L2capBle();
```
### Monitor Connection State:
Subscribe to the connection state stream to track L2CAP connection progress.

```dart
final connectionStream = ble.getConnectionState();
```
### Connect to Device:
Establish a connection to the device using connectToDevice, and await the 'connected' state.

```dart
await ble.connectToDevice(deviceId);
````
### Create L2CAP Channel:
Use createL2capChannel to establish the L2CAP channel, providing the required psm.

```dart
final channelCreated = await ble.createL2capChannel(psm);
````
### Exchange Messages:
Send and receive messages seamlessly via the L2CAP channel with sendMessage.

```dart
final response = await ble.sendMessage(myMessage);
````
### Disconnect Gracefully:
Disconnect using disconnectFromDevice. The L2CAP channel closes automatically.

```dart
ble.disconnectFromDevice(deviceId);
````

## Example
Explore the example directory for a complete usage scenario, demonstrating L2CAP communication.

## Contributing
Contributions are welcome! If you encounter issues, have feature suggestions, or want to improve the package, feel free to open an issue or submit a pull request. Please read our Contribution Guidelines for more information.

## License
This project is licensed under the MIT License.