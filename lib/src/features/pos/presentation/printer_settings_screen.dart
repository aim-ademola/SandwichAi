import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/features/pos/data/repository/service/printer_service.dart';
import 'package:sandwich_ai/src/features/pos/helpers/printer_config_helper.dart';

import '../../../core/config/prod_print.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen>
    with SingleTickerProviderStateMixin {
  final _printerService = PrinterService();
  bool _isScanning = false;
  bool _isLoading = true;
  List<PrinterDiscoveryResult> _discoveredPrinters = [];
  final Map<String, bool> _testingPrinters = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadSavedPrinters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load saved printer configurations
  Future<void> _loadSavedPrinters() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PrinterConfigHelper.loadIntoPrinterService(_printerService);
    } catch (e) {
      AppLogger.log('Error loading printers: $e');
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Save current printer configurations
  Future<void> _savePrinters() async {
    try {
      await PrinterConfigHelper.syncPrinterService(_printerService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Printer settings saved',
              style: WorkSansAppTextStyles.medium,
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.log('Error saving printers: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save printer settings',
              style: WorkSansAppTextStyles.medium,
            ),
            backgroundColor: const Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildScanSection(),
              const SizedBox(height: 28),
              if (_discoveredPrinters.isNotEmpty) ...[
                _buildDiscoveredPrintersSection(),
                const SizedBox(height: 28),
              ],
              _buildConfiguredPrintersSection(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () {
          // Auto-save when leaving the screen
          _savePrinters();
          Navigator.pop(context);
        },
      ),
      title: Text(
        'Printer Settings',
        style: WorkSansAppTextStyles.medium.copyWith(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.black,
        ),
      ),
      centerTitle: false,
      actions: [
        // Save button
        IconButton(
          icon: const Icon(Icons.save, color: Colors.black),
          onPressed: _savePrinters,
          tooltip: 'Save Settings',
        ),
        // Add manually button
        IconButton(
          icon: const Icon(Icons.add, color: Colors.black),
          onPressed: _showAddPrinterDialog,
          tooltip: 'Add Manually',
        ),
        // More options
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onSelected: (value) {
            switch (value) {
              case 'clear':
                _confirmClearAll();
                break;
              case 'summary':
                _showSummary();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'summary',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 12),
                  Text('Printer Summary'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Clear All', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScanSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search, color: kPrimary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Printer Scanner',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find printers via Network, Bluetooth, USB',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scan type tabs
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F6F6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              controller: _tabController,
              indicator: BoxDecoration(
                color: kPrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF757575),
              labelStyle: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Network'),
                Tab(text: 'Bluetooth'),
                Tab(text: 'USB'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScanning ? null : _scanForPrinters,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isScanning
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scanning...',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.radar, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _getScanButtonText(),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getScanButtonText() {
    switch (_tabController.index) {
      case 1:
        return 'Scan Network';
      case 2:
        return 'Scan Bluetooth';
      case 3:
        return 'Scan USB';
      default:
        return 'Scan All';
    }
  }

  Widget _buildDiscoveredPrintersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discovered Printers',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_discoveredPrinters.length} printer(s) found',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () {
                  setState(() {
                    _discoveredPrinters.clear();
                  });
                },
                tooltip: 'Clear',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _discoveredPrinters.length,
            separatorBuilder: (context, index) => const Divider(
              height: 24,
              color: Color(0xFFF5F5F5),
              thickness: 1,
            ),
            itemBuilder: (context, index) {
              final printer = _discoveredPrinters[index];
              return _buildDiscoveredPrinterItem(printer);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveredPrinterItem(PrinterDiscoveryResult printer) {
    final connectionIcon = _getConnectionIcon(printer.connectionType);
    final connectionColor = _getConnectionColor(printer.connectionType);

    return InkWell(
      onTap: () => _addDiscoveredPrinter(printer),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: connectionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(connectionIcon, color: connectionColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: connectionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getConnectionTypeLabel(printer.connectionType),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: connectionColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getConnectionInfo(printer),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguredPrintersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configured Printers',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_printerService.printers.length}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_printerService.printers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.print_disabled,
                      size: 48,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No printers configured',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan or add manually',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _printerService.printers.length,
              separatorBuilder: (context, index) => const Divider(
                height: 24,
                color: Color(0xFFF5F5F5),
                thickness: 1,
              ),
              itemBuilder: (context, index) {
                final printer = _printerService.printers[index];
                return _buildConfiguredPrinterItem(printer);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildConfiguredPrinterItem(PrinterConfig printer) {
    final isTesting = _testingPrinters[printer.id] ?? false;
    final statusColor = const Color(0xFF4CAF50);
    final connectionIcon = _getConnectionIcon(printer.connectionType);
    final connectionColor = _getConnectionColor(printer.connectionType);

    return InkWell(
      onTap: () => _showPrinterOptions(printer),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(connectionIcon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    printer.name,
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: connectionColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getConnectionTypeLabel(printer.connectionType),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: connectionColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          printer.connectionInfo,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 12,
                            color: const Color(0xFF9E9E9E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isTesting)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  printer.isKitchenPrinter ? 'Kitchen' : 'Receipt',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: const Color(0xFF9E9E9E),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  IconData _getConnectionIcon(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return Icons.wifi;
      case PrinterConnectionType.bluetooth:
        return Icons.bluetooth;
      case PrinterConnectionType.usb:
        return Icons.usb;
      case PrinterConnectionType.serial:
        return Icons.cable;
    }
  }

  Color _getConnectionColor(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return const Color(0xFF2196F3);
      case PrinterConnectionType.bluetooth:
        return const Color(0xFF3F51B5);
      case PrinterConnectionType.usb:
        return const Color(0xFF9C27B0);
      case PrinterConnectionType.serial:
        return const Color(0xFFFF9800);
    }
  }

  String _getConnectionTypeLabel(PrinterConnectionType type) {
    switch (type) {
      case PrinterConnectionType.network:
        return 'NETWORK';
      case PrinterConnectionType.bluetooth:
        return 'BLUETOOTH';
      case PrinterConnectionType.usb:
        return 'USB';
      case PrinterConnectionType.serial:
        return 'SERIAL';
    }
  }

  String _getConnectionInfo(PrinterDiscoveryResult printer) {
    switch (printer.connectionType) {
      case PrinterConnectionType.network:
        return '${printer.address}${printer.port != null ? ':${printer.port}' : ''}';
      case PrinterConnectionType.bluetooth:
        return printer.rssi != null ? '${printer.rssi} dBm' : printer.address;
      case PrinterConnectionType.usb:
        return printer.manufacturer ?? 'USB Device';
      case PrinterConnectionType.serial:
        return printer.address;
    }
  }

  // Actions
  Future<void> _scanForPrinters() async {
    setState(() {
      _isScanning = true;
      _discoveredPrinters = [];
    });

    List<PrinterDiscoveryResult> printers = [];

    try {
      switch (_tabController.index) {
        case 0: // All
          printers = await PrinterService.discoverAllPrinters();
          break;
        case 1: // Network
          printers = await PrinterService.discoverPrintersOnNetwork();
          break;
        case 2: // Bluetooth
          printers = await PrinterService.discoverBluetoothPrinters();
          break;
        case 3: // USB
          printers = await PrinterService.discoverUSBPrinters();
          break;
      }
    } catch (e) {
      AppLogger.log('Error scanning: $e');
    }

    if (mounted) {
      setState(() {
        _discoveredPrinters = printers;
        _isScanning = false;
      });

      if (printers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No printers found',
              style: WorkSansAppTextStyles.medium,
            ),
            backgroundColor: const Color(0xFFFF9800),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _addDiscoveredPrinter(PrinterDiscoveryResult discovered) {
    final nameController = TextEditingController(
      text: '${discovered.name} ${_printerService.printers.length + 1}',
    );
    bool isKitchen = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Printer',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: WorkSansAppTextStyles.medium,
                  decoration: InputDecoration(
                    labelText: 'Printer Name',
                    labelStyle: WorkSansAppTextStyles.medium.copyWith(
                      color: const Color(0xFF9E9E9E),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: kPrimary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F6F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Kitchen Printer',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Orders will be printed automatically',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: const Color(0xFF9E9E9E),
                      ),
                    ),
                    value: isKitchen,
                    activeThumbColor: kPrimary,
                    onChanged: (value) {
                      setDialogState(() {
                        isKitchen = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final config = _createConfigFromDiscovery(
                            discovered,
                            nameController.text.trim(),
                            isKitchen,
                          );

                          setState(() {
                            _printerService.addPrinter(config);
                          });

                          // Auto-save when adding
                          _savePrinters();

                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${config.name} added successfully',
                                style: WorkSansAppTextStyles.medium,
                              ),
                              backgroundColor: const Color(0xFF4CAF50),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Add Printer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PrinterConfig _createConfigFromDiscovery(
    PrinterDiscoveryResult discovered,
    String name,
    bool isKitchen,
  ) {
    return PrinterConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      connectionType: discovered.connectionType,
      isKitchenPrinter: isKitchen,
      isReceiptPrinter: !isKitchen,
      ipAddress: discovered.connectionType == PrinterConnectionType.network
          ? discovered.address
          : null,
      port: discovered.port ?? 9100,
      bluetoothAddress:
          discovered.connectionType == PrinterConnectionType.bluetooth
          ? discovered.address
          : null,
      bluetoothName:
          discovered.connectionType == PrinterConnectionType.bluetooth
          ? discovered.name
          : null,
      usbDeviceId: discovered.connectionType == PrinterConnectionType.usb
          ? discovered.address
          : null,
      vendorId: discovered.vendorId,
      productId: discovered.productId,
    );
  }

  void _showAddPrinterDialog() {
    final nameController = TextEditingController(
      text: 'Printer ${_printerService.printers.length + 1}',
    );
    final ipController = TextEditingController();
    final portController = TextEditingController(text: '9100');
    final bluetoothAddressController = TextEditingController();
    final usbDeviceIdController = TextEditingController();
    final serialPortController = TextEditingController();
    final baudRateController = TextEditingController(text: '9600');

    PrinterConnectionType selectedType = PrinterConnectionType.network;
    bool isKitchen = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Printer Manually',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Printer Name
                  TextField(
                    controller: nameController,
                    style: WorkSansAppTextStyles.medium,
                    decoration: InputDecoration(
                      labelText: 'Printer Name',
                      labelStyle: WorkSansAppTextStyles.medium.copyWith(
                        color: const Color(0xFF9E9E9E),
                      ),
                      hintText: 'e.g., Kitchen Printer 1',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Connection Type Selector
                  Text(
                    'Connection Type',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        RadioListTile<PrinterConnectionType>(
                          title: Row(
                            children: [
                              Icon(
                                Icons.wifi,
                                size: 20,
                                color: Color(0xFF2196F3),
                              ),
                              const SizedBox(width: 12),
                              const Text('Network (Wi-Fi/Ethernet)'),
                            ],
                          ),
                          value: PrinterConnectionType.network,
                          groupValue: selectedType,
                          activeColor: kPrimary,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                        RadioListTile<PrinterConnectionType>(
                          title: Row(
                            children: [
                              Icon(
                                Icons.bluetooth,
                                size: 20,
                                color: Color(0xFF3F51B5),
                              ),
                              const SizedBox(width: 12),
                              const Text('Bluetooth'),
                            ],
                          ),
                          value: PrinterConnectionType.bluetooth,
                          groupValue: selectedType,
                          activeColor: kPrimary,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                        RadioListTile<PrinterConnectionType>(
                          title: Row(
                            children: [
                              Icon(
                                Icons.usb,
                                size: 20,
                                color: Color(0xFF9C27B0),
                              ),
                              const SizedBox(width: 12),
                              const Text('USB'),
                            ],
                          ),
                          value: PrinterConnectionType.usb,
                          groupValue: selectedType,
                          activeColor: kPrimary,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                        RadioListTile<PrinterConnectionType>(
                          title: Row(
                            children: [
                              Icon(
                                Icons.cable,
                                size: 20,
                                color: Color(0xFFFF9800),
                              ),
                              const SizedBox(width: 12),
                              const Text('Serial Port'),
                            ],
                          ),
                          value: PrinterConnectionType.serial,
                          groupValue: selectedType,
                          activeColor: kPrimary,
                          onChanged: (value) {
                            setDialogState(() {
                              selectedType = value!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Connection-specific fields
                  if (selectedType == PrinterConnectionType.network) ...[
                    TextField(
                      controller: ipController,
                      style: WorkSansAppTextStyles.medium,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'IP Address',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: '192.168.1.100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: portController,
                      style: WorkSansAppTextStyles.medium,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Port',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: '9100',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.bluetooth) ...[
                    TextField(
                      controller: bluetoothAddressController,
                      style: WorkSansAppTextStyles.medium,
                      decoration: InputDecoration(
                        labelText: 'Bluetooth Address',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: 'XX:XX:XX:XX:XX:XX',
                        helperText: 'Use scanner to find address automatically',
                        helperStyle: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.usb) ...[
                    TextField(
                      controller: usbDeviceIdController,
                      style: WorkSansAppTextStyles.medium,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'USB Device ID',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: 'Device identifier',
                        helperText: 'Use scanner to find device automatically',
                        helperStyle: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF9E9E9E),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.serial) ...[
                    TextField(
                      controller: serialPortController,
                      style: WorkSansAppTextStyles.medium,
                      decoration: InputDecoration(
                        labelText: 'Serial Port',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: 'COM1 or /dev/ttyUSB0',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: baudRateController,
                      style: WorkSansAppTextStyles.medium,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Baud Rate',
                        labelStyle: WorkSansAppTextStyles.medium.copyWith(
                          color: const Color(0xFF9E9E9E),
                        ),
                        hintText: '9600',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: kPrimary),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Kitchen/Receipt toggle
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Kitchen Printer',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'Orders will be printed automatically',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF9E9E9E),
                        ),
                      ),
                      value: isKitchen,
                      activeThumbColor: kPrimary,
                      onChanged: (value) {
                        setDialogState(() {
                          isKitchen = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: Color(0xFFE0E0E0)),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Validate required fields
                            String? validationError;

                            if (nameController.text.trim().isEmpty) {
                              validationError = 'Please enter printer name';
                            } else if (selectedType ==
                                    PrinterConnectionType.network &&
                                ipController.text.trim().isEmpty) {
                              validationError = 'Please enter IP address';
                            } else if (selectedType ==
                                    PrinterConnectionType.bluetooth &&
                                bluetoothAddressController.text
                                    .trim()
                                    .isEmpty) {
                              validationError =
                                  'Please enter Bluetooth address';
                            } else if (selectedType ==
                                    PrinterConnectionType.usb &&
                                usbDeviceIdController.text.trim().isEmpty) {
                              validationError = 'Please enter USB device ID';
                            } else if (selectedType ==
                                    PrinterConnectionType.serial &&
                                serialPortController.text.trim().isEmpty) {
                              validationError = 'Please enter serial port';
                            }

                            if (validationError != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    validationError,
                                    style: WorkSansAppTextStyles.medium,
                                  ),
                                  backgroundColor: const Color(0xFFF44336),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }

                            // Create printer config
                            final config = PrinterConfig(
                              id: DateTime.now().millisecondsSinceEpoch
                                  .toString(),
                              name: nameController.text.trim(),
                              connectionType: selectedType,
                              isKitchenPrinter: isKitchen,
                              isReceiptPrinter: !isKitchen,
                              ipAddress:
                                  selectedType == PrinterConnectionType.network
                                  ? ipController.text.trim()
                                  : null,
                              port:
                                  selectedType == PrinterConnectionType.network
                                  ? int.tryParse(portController.text) ?? 9100
                                  : 9100,
                              bluetoothAddress:
                                  selectedType ==
                                      PrinterConnectionType.bluetooth
                                  ? bluetoothAddressController.text.trim()
                                  : null,
                              bluetoothName:
                                  selectedType ==
                                      PrinterConnectionType.bluetooth
                                  ? nameController.text.trim()
                                  : null,
                              usbDeviceId:
                                  selectedType == PrinterConnectionType.usb
                                  ? usbDeviceIdController.text.trim()
                                  : null,
                              serialPort:
                                  selectedType == PrinterConnectionType.serial
                                  ? serialPortController.text.trim()
                                  : null,
                              baudRate:
                                  selectedType == PrinterConnectionType.serial
                                  ? int.tryParse(baudRateController.text) ??
                                        9600
                                  : 9600,
                            );

                            setState(() {
                              _printerService.addPrinter(config);
                            });

                            // Auto-save when adding
                            _savePrinters();

                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${config.name} added successfully',
                                  style: WorkSansAppTextStyles.medium,
                                ),
                                backgroundColor: const Color(0xFF4CAF50),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Add Printer',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPrinterOptions(PrinterConfig printer) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              printer.name,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              printer.connectionInfo,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: const Color(0xFF9E9E9E),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.print, color: Color(0xFF2196F3)),
              title: const Text('Test Print'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _testPrinter(printer);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Color(0xFFF44336)),
              title: const Text('Remove Printer'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(printer);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testPrinter(PrinterConfig printer) async {
    setState(() {
      _testingPrinters[printer.id] = true;
    });

    final success = await _printerService.testPrinterConnection(printer);

    if (mounted) {
      setState(() {
        _testingPrinters[printer.id] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Test successful!' : 'Connection failed',
            style: WorkSansAppTextStyles.medium,
          ),
          backgroundColor: success
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
        ),
      );
    }
  }

  void _confirmDelete(PrinterConfig printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Printer'),
        content: Text('Remove "${printer.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _printerService.removePrinter(printer.id);
              });

              // Auto-save when removing
              _savePrinters();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${printer.name} removed')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Printers'),
        content: const Text(
          'Remove all configured printers? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() {
                _printerService.clearPrinters();
              });

              await PrinterConfigHelper.clearPrinterConfigs();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All printers cleared')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF44336),
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSummary() async {
    final summary = await PrinterConfigHelper.getPrinterSummary();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Printer Summary'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${summary['total']}'),
            const SizedBox(height: 8),
            Text('Network: ${summary['network']}'),
            Text('Bluetooth: ${summary['bluetooth']}'),
            Text('USB: ${summary['usb']}'),
            Text('Serial: ${summary['serial']}'),
            const Divider(),
            Text('Kitchen: ${summary['kitchen']}'),
            Text('Receipt: ${summary['receipt']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
