import 'package:sandwich_ai/src/core/config/feature_registry.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:sandwich_ai/src/core/config/app_environment.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/features/pos/data/model/pos_order_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';

enum PrinterConnectionType { network, bluetooth, usb, serial }

class PrinterService {
  static final PrinterService _instance = PrinterService._internal();
  factory PrinterService() => _instance;
  PrinterService._internal();

  final List<PrinterConfig> _printers = [];

  List<PrinterConfig> get printers => _printers;

  void addPrinter(PrinterConfig config) {
    _printers.add(config);
  }

  void removePrinter(String id) {
    _printers.removeWhere((p) => p.id == id);
  }

  void clearPrinters() {
    _printers.clear();
  }

  /// Print order to all configured kitchen printers
  Future<Map<String, bool>> printOrderToKitchen(
    PosOrderResponseModel order,
  ) async {
    final results = <String, bool>{};

    if (!_isPrinterEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.printer),
      );
      return results;
    }

    for (final printer in _printers.where((p) => p.isKitchenPrinter)) {
      try {
        bool success = false;

        switch (printer.connectionType) {
          case PrinterConnectionType.network:
            success = await _printToNetworkPrinter(
              printer.ipAddress!,
              printer.port,
              order,
            );
            break;

          case PrinterConnectionType.bluetooth:
            success = await _printToBluetoothPrinter(
              printer.bluetoothAddress!,
              order,
            );
            break;

          case PrinterConnectionType.usb:
            success = await _printToUSBPrinter(printer.usbDeviceId!, order);
            break;

          case PrinterConnectionType.serial:
            success = await _printToSerialPrinter(printer.serialPort!, order);
            break;
        }

        results[printer.name] = success;
      } catch (e) {
        AppLogger.log('Error printing to ${printer.name}: $e');
        results[printer.name] = false;
      }
    }

    return results;
  }

  // ==================== NETWORK PRINTING ====================

  Future<bool> _printToNetworkPrinter(
    String ipAddress,
    int port,
    PosOrderResponseModel order,
  ) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 5),
      );

      final bytes = _buildESCPOSReceipt(order);
      socket.add(bytes);
      await socket.flush();

      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (e) {
      AppLogger.log('Error in _printToNetworkPrinter: $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }

  /// Discover network printers
  static Future<List<PrinterDiscoveryResult>>
  discoverPrintersOnNetwork() async {
    final List<PrinterDiscoveryResult> devices = [];

    if (!_isScannerEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.scanner),
      );
      return devices;
    }

    try {
      final interfaces = await NetworkInterface.list();
      String? subnet;

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 &&
              !addr.isLoopback &&
              !addr.address.startsWith('169.254')) {
            final parts = addr.address.split('.');
            subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
            break;
          }
        }
        if (subnet != null) break;
      }

      if (subnet == null) {
        AppLogger.log('Could not determine network subnet');
        return devices;
      }

      AppLogger.log('Scanning subnet: $subnet.x');

      // Common printer ports
      final ports = [9100, 9101, 9102, 515];

      // Scan network
      final futures = <Future<void>>[];

      for (int i = 1; i <= 254; i++) {
        final host = '$subnet.$i';

        for (final port in ports) {
          futures.add(
            _checkHost(host, port).then((isOpen) {
              if (isOpen) {
                final existingIndex = devices.indexWhere(
                  (d) =>
                      d.address == host &&
                      d.connectionType == PrinterConnectionType.network,
                );
                if (existingIndex == -1) {
                  devices.add(
                    PrinterDiscoveryResult(
                      name: 'Network Printer',
                      address: host,
                      port: port,
                      connectionType: PrinterConnectionType.network,
                    ),
                  );
                }
              }
            }),
          );
        }
      }

      await Future.wait(futures);

      AppLogger.log('Found ${devices.length} network printers');
    } catch (e) {
      AppLogger.log('Error discovering network printers: $e');
    }

    return devices;
  }

  static Future<bool> _checkHost(String host, int port) async {
    try {
      final socket = await Socket.connect(
        host,
        port,
        timeout: const Duration(milliseconds: 200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  // ==================== BLUETOOTH PRINTING ====================

  Future<bool> _printToBluetoothPrinter(
    String bluetoothAddress,
    PosOrderResponseModel order,
  ) async {
    try {
      final device = BluetoothDevice.fromId(bluetoothAddress);
      await device.connect(license: License.free);

      final services = await device.discoverServices();
      BluetoothCharacteristic? writeCharacteristic;

      for (var service in services) {
        for (var characteristic in service.characteristics) {
          if (characteristic.properties.write) {
            writeCharacteristic = characteristic;
            break;
          }
        }
        if (writeCharacteristic != null) break;
      }

      if (writeCharacteristic != null) {
        final bytes = _buildESCPOSReceipt(order);

        // Split into chunks (Bluetooth has MTU limitations)
        const chunkSize = 512;
        for (var i = 0; i < bytes.length; i += chunkSize) {
          final end = (i + chunkSize < bytes.length)
              ? i + chunkSize
              : bytes.length;
          await writeCharacteristic.write(
            bytes.sublist(i, end),
            withoutResponse: false,
          );
          await Future.delayed(const Duration(milliseconds: 50));
        }
      }

      await device.disconnect();
      return true;
    } catch (e) {
      AppLogger.log('Error in _printToBluetoothPrinter: $e');
      return false;
    }
  }

  /// Discover Bluetooth printers
  static Future<List<PrinterDiscoveryResult>>
  discoverBluetoothPrinters() async {
    final List<PrinterDiscoveryResult> devices = [];

    if (!_isScannerEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.scanner),
      );
      return devices;
    }

    try {
      // This requires flutter_blue_plus package

      // Check if Bluetooth is available
      if (await FlutterBluePlus.isSupported == false) {
        AppLogger.log('Bluetooth not supported on this device');
        return devices;
      }

      // Check if Bluetooth is on
      var adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        AppLogger.log('Bluetooth is off');
        return devices;
      }

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      // Listen to scan results
      var subscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final deviceName = result.device.platformName;

          // Filter for printer devices (common names)
          if (deviceName.toLowerCase().contains('printer') ||
              deviceName.toLowerCase().contains('pos') ||
              deviceName.toLowerCase().contains('escpos') ||
              deviceName.toLowerCase().contains('thermal')) {
            final existingIndex = devices.indexWhere(
              (d) => d.address == result.device.remoteId.toString(),
            );

            if (existingIndex == -1) {
              devices.add(
                PrinterDiscoveryResult(
                  name: deviceName.isNotEmpty
                      ? deviceName
                      : 'Unknown Bluetooth Printer',
                  address: result.device.remoteId.toString(),
                  connectionType: PrinterConnectionType.bluetooth,
                  rssi: result.rssi,
                ),
              );
            }
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(const Duration(seconds: 15));

      // Stop scanning
      await FlutterBluePlus.stopScan();
      subscription.cancel();

      AppLogger.log('Bluetooth discovery not yet implemented');
    } catch (e) {
      AppLogger.log('Error discovering Bluetooth printers: $e');
    }

    return devices;
  }

  // ==================== USB PRINTING ====================

  Future<bool> _printToUSBPrinter(
    String usbDeviceId,
    PosOrderResponseModel order,
  ) async {
    try {
      // This requires usb_serial package for Android

      final ports = await UsbSerial.listDevices();
      UsbPort? targetPort;

      for (var port in ports) {
        if (port.deviceId.toString() == usbDeviceId) {
          targetPort = port as UsbPort?;
          break;
        }
      }

      if (targetPort == null) {
        AppLogger.log('USB device not found');
        return false;
      }

      await targetPort.open();
      await targetPort.setDTR(true);
      await targetPort.setRTS(true);

      // Configure serial parameters
      await targetPort.setPortParameters(
        9600, // Baud rate
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      final bytes = _buildESCPOSReceipt(order);
      await targetPort.write(bytes);

      await Future.delayed(const Duration(milliseconds: 500));
      await targetPort.close();

      return true;
    } catch (e) {
      AppLogger.log('Error in _printToUSBPrinter: $e');
      return false;
    }
  }

  /// Discover USB printers
  static Future<List<PrinterDiscoveryResult>> discoverUSBPrinters() async {
    final List<PrinterDiscoveryResult> devices = [];

    if (!_isScannerEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.scanner),
      );
      return devices;
    }

    try {
      // This requires usb_serial package

      final ports = await UsbSerial.listDevices();

      for (var port in ports) {
        devices.add(
          PrinterDiscoveryResult(
            name: 'USB Printer (${port.productName ?? 'Unknown'})',
            address: port.deviceId.toString(),
            connectionType: PrinterConnectionType.usb,
            manufacturer: port.manufacturerName,
            productId: port.pid,
            vendorId: port.vid,
          ),
        );
      }

      AppLogger.log('USB discovery not yet implemented');
    } catch (e) {
      AppLogger.log('Error discovering USB printers: $e');
    }

    return devices;
  }

  // ==================== SERIAL PORT PRINTING ====================

  Future<bool> _printToSerialPrinter(
    String serialPort,
    PosOrderResponseModel order,
  ) async {
    try {
      // For desktop platforms, you might use package:libserialport
      // This is typically used on Windows/Linux/macOS

      AppLogger.log('Serial port printing not yet implemented');
      return false;
    } catch (e) {
      AppLogger.log('Error in _printToSerialPrinter: $e');
      return false;
    }
  }

  // ==================== UNIFIED DISCOVERY ====================

  /// Discover all available printers across all connection types
  static Future<List<PrinterDiscoveryResult>> discoverAllPrinters() async {
    final allPrinters = <PrinterDiscoveryResult>[];

    if (!_isScannerEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.scanner),
      );
      return allPrinters;
    }

    // Discover network printers
    final networkPrinters = await discoverPrintersOnNetwork();
    allPrinters.addAll(networkPrinters);

    // Discover Bluetooth printers
    final bluetoothPrinters = await discoverBluetoothPrinters();
    allPrinters.addAll(bluetoothPrinters);

    // Discover USB printers
    final usbPrinters = await discoverUSBPrinters();
    allPrinters.addAll(usbPrinters);

    return allPrinters;
  }

  // ==================== TEST CONNECTION ====================

  Future<bool> testPrinterConnection(PrinterConfig config) async {
    if (!_isPrinterEnabled) {
      AppLogger.log(
        AppEnvironment.current.disabledFeatureMessage(AppFeature.printer),
      );
      return false;
    }

    try {
      switch (config.connectionType) {
        case PrinterConnectionType.network:
          return await _testNetworkConnection(config.ipAddress!, config.port);

        case PrinterConnectionType.bluetooth:
          return await _testBluetoothConnection(config.bluetoothAddress!);

        case PrinterConnectionType.usb:
          return await _testUSBConnection(config.usbDeviceId!);

        case PrinterConnectionType.serial:
          return await _testSerialConnection(config.serialPort!);
      }
    } catch (e) {
      AppLogger.log('Test connection failed: $e');
      return false;
    }
  }

  static bool get _isPrinterEnabled =>
      FeatureRegistry.isEnabled(AppFeature.printer);

  static bool get _isScannerEnabled =>
      FeatureRegistry.isEnabled(AppFeature.scanner);

  Future<bool> _testNetworkConnection(String ipAddress, int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        ipAddress,
        port,
        timeout: const Duration(seconds: 3),
      );

      final bytes = _buildTestReceipt();
      socket.add(bytes);
      await socket.flush();

      return true;
    } catch (e) {
      AppLogger.log('Network test failed: $e');
      return false;
    } finally {
      socket?.destroy();
    }
  }

  Future<bool> _testBluetoothConnection(String bluetoothAddress) async {
    // Implement Bluetooth test
    AppLogger.log('Bluetooth test not yet implemented');
    return false;
  }

  Future<bool> _testUSBConnection(String usbDeviceId) async {
    // Implement USB test
    AppLogger.log('USB test not yet implemented');
    return false;
  }

  Future<bool> _testSerialConnection(String serialPort) async {
    // Implement Serial test
    AppLogger.log('Serial test not yet implemented');
    return false;
  }

  // ==================== ESC/POS RECEIPT BUILDING ====================

  Uint8List _buildESCPOSReceipt(PosOrderResponseModel order) {
    final List<int> bytes = [];

    // ESC/POS Commands
    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;

    // Initialize printer
    bytes.addAll([ESC, 0x40]);

    // Set character set to UTF-8 if supported
    bytes.addAll([ESC, 0x74, 0x00]);

    // Center align
    bytes.addAll([ESC, 0x61, 0x01]);

    // Double height + width + bold for header
    bytes.addAll([ESC, 0x21, 0x38]);
    bytes.addAll(utf8.encode('KITCHEN ORDER'));
    bytes.add(LF);
    bytes.add(LF);

    // Reset font
    bytes.addAll([ESC, 0x21, 0x00]);

    // Left align
    bytes.addAll([ESC, 0x61, 0x00]);

    // Order number - large and bold
    bytes.addAll([ESC, 0x21, 0x30]);
    bytes.addAll(utf8.encode('Order #: ${order.orderNumber}'));
    bytes.add(LF);
    bytes.add(LF);

    // Reset font
    bytes.addAll([ESC, 0x21, 0x00]);

    // Order details
    bytes.addAll(utf8.encode('Type: ${order.orderType}'));
    bytes.add(LF);

    if (order.tableNumber != null && order.tableNumber!.isNotEmpty) {
      bytes.addAll(utf8.encode('Table: ${order.tableNumber}'));
      bytes.add(LF);
    }

    if (order.customerName != null && order.customerName!.isNotEmpty) {
      bytes.addAll(utf8.encode('Customer: ${order.customerName}'));
      bytes.add(LF);
    }

    bytes.addAll(utf8.encode('Time: ${_formatDateTime(order.createdAt)}'));
    bytes.add(LF);

    // Horizontal line
    bytes.addAll(utf8.encode('-' * 48));
    bytes.add(LF);
    bytes.add(LF);

    // Center align for items header
    bytes.addAll([ESC, 0x61, 0x01]);
    bytes.addAll([ESC, 0x21, 0x08]);
    bytes.addAll(utf8.encode('ITEMS'));
    bytes.add(LF);
    bytes.add(LF);

    // Left align
    bytes.addAll([ESC, 0x61, 0x00]);
    bytes.addAll([ESC, 0x21, 0x00]);

    // Print items
    for (final item in order.items) {
      bytes.addAll([ESC, 0x21, 0x08]);
      final itemName = item.menuItem?.dishName ?? 'Unknown Item';
      bytes.addAll(utf8.encode('${item.quantity}x $itemName'));
      bytes.add(LF);
      bytes.addAll([ESC, 0x21, 0x00]);

      if (item.specialRequest != null && item.specialRequest!.isNotEmpty) {
        bytes.addAll([ESC, 0x21, 0x08]);
        bytes.addAll(utf8.encode('  Note: ${item.specialRequest}'));
        bytes.add(LF);
        bytes.addAll([ESC, 0x21, 0x00]);
      }

      bytes.add(LF);
    }

    // Special instructions
    if (order.specialInstructions != null &&
        order.specialInstructions!.isNotEmpty) {
      bytes.addAll(utf8.encode('-' * 48));
      bytes.add(LF);
      bytes.addAll([ESC, 0x21, 0x08]);
      bytes.addAll(utf8.encode('SPECIAL INSTRUCTIONS:'));
      bytes.add(LF);
      bytes.addAll([ESC, 0x21, 0x10]);
      bytes.addAll(utf8.encode(order.specialInstructions!));
      bytes.add(LF);
      bytes.addAll([ESC, 0x21, 0x00]);
    }

    bytes.add(LF);
    bytes.add(LF);

    // Footer line
    bytes.addAll(utf8.encode('=' * 48));
    bytes.add(LF);
    bytes.add(LF);

    // Center align
    bytes.addAll([ESC, 0x61, 0x01]);
    bytes.addAll(utf8.encode('Prepared by: ${order.takenBy}'));
    bytes.add(LF);
    bytes.add(LF);
    bytes.add(LF);

    // Cut paper
    bytes.addAll([GS, 0x56, 0x00]);

    return Uint8List.fromList(bytes);
  }

  Uint8List _buildTestReceipt() {
    final List<int> bytes = [];
    const ESC = 0x1B;
    const GS = 0x1D;
    const LF = 0x0A;

    bytes.addAll([ESC, 0x40]);
    bytes.addAll([ESC, 0x61, 0x01]);
    bytes.addAll([ESC, 0x21, 0x30]);
    bytes.addAll(utf8.encode('TEST PRINT'));
    bytes.add(LF);
    bytes.add(LF);
    bytes.addAll([ESC, 0x21, 0x00]);
    bytes.addAll(utf8.encode('Printer connected successfully!'));
    bytes.add(LF);
    bytes.add(LF);
    bytes.add(LF);
    bytes.addAll([GS, 0x56, 0x00]);

    return Uint8List.fromList(bytes);
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'N/A';
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

// ==================== MODELS ====================

class PrinterConfig {
  final String id;
  final String name;
  final PrinterConnectionType connectionType;
  final bool isKitchenPrinter;
  final bool isReceiptPrinter;

  // Network printer fields
  final String? ipAddress;
  final int port;

  // Bluetooth printer fields
  final String? bluetoothAddress;
  final String? bluetoothName;

  // USB printer fields
  final String? usbDeviceId;
  final int? vendorId;
  final int? productId;

  // Serial printer fields
  final String? serialPort;
  final int? baudRate;

  PrinterConfig({
    required this.id,
    required this.name,
    required this.connectionType,
    this.isKitchenPrinter = true,
    this.isReceiptPrinter = false,
    this.ipAddress,
    this.port = 9100,
    this.bluetoothAddress,
    this.bluetoothName,
    this.usbDeviceId,
    this.vendorId,
    this.productId,
    this.serialPort,
    this.baudRate = 9600,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'connectionType': connectionType.name,
    'isKitchenPrinter': isKitchenPrinter,
    'isReceiptPrinter': isReceiptPrinter,
    'ipAddress': ipAddress,
    'port': port,
    'bluetoothAddress': bluetoothAddress,
    'bluetoothName': bluetoothName,
    'usbDeviceId': usbDeviceId,
    'vendorId': vendorId,
    'productId': productId,
    'serialPort': serialPort,
    'baudRate': baudRate,
  };

  factory PrinterConfig.fromJson(Map<String, dynamic> json) => PrinterConfig(
    id: json['id'],
    name: json['name'],
    connectionType: PrinterConnectionType.values.firstWhere(
      (e) => e.name == json['connectionType'],
      orElse: () => PrinterConnectionType.network,
    ),
    isKitchenPrinter: json['isKitchenPrinter'] ?? true,
    isReceiptPrinter: json['isReceiptPrinter'] ?? false,
    ipAddress: json['ipAddress'],
    port: json['port'] ?? 9100,
    bluetoothAddress: json['bluetoothAddress'],
    bluetoothName: json['bluetoothName'],
    usbDeviceId: json['usbDeviceId'],
    vendorId: json['vendorId'],
    productId: json['productId'],
    serialPort: json['serialPort'],
    baudRate: json['baudRate'] ?? 9600,
  );

  String get connectionInfo {
    switch (connectionType) {
      case PrinterConnectionType.network:
        return '$ipAddress:$port';
      case PrinterConnectionType.bluetooth:
        return bluetoothName ?? bluetoothAddress ?? 'Unknown';
      case PrinterConnectionType.usb:
        return 'USB Device $usbDeviceId';
      case PrinterConnectionType.serial:
        return '$serialPort @ $baudRate bps';
    }
  }
}

class PrinterDiscoveryResult {
  final String name;
  final String address;
  final PrinterConnectionType connectionType;
  final int? port;
  final int? rssi; // For Bluetooth
  final String? manufacturer;
  final int? vendorId;
  final int? productId;

  PrinterDiscoveryResult({
    required this.name,
    required this.address,
    required this.connectionType,
    this.port,
    this.rssi,
    this.manufacturer,
    this.vendorId,
    this.productId,
  });
}
