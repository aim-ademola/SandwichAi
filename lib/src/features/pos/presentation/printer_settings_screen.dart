import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
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
            backgroundColor: context.modeSuccess,
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
            backgroundColor: context.modeError,
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
        backgroundColor: context.modeBackground,
        appBar: _buildAppBar(),
        body: Center(
          child: CircularProgressIndicator(color: context.modePrimary),
        ),
      );
    }

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: context.modeBackground,
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
      backgroundColor: context.modeSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: context.modeTextPrimary),
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
          color: context.modeTextPrimary,
        ),
      ),
      centerTitle: false,
      actions: [
        // Save button
        IconButton(
          icon: Icon(Icons.save, color: context.modeTextPrimary),
          onPressed: _savePrinters,
          tooltip: 'Save Settings',
        ),
        // Add manually button
        IconButton(
          icon: Icon(Icons.add, color: context.modeTextPrimary),
          onPressed: _showAddPrinterDialog,
          tooltip: 'Add Manually',
        ),
        // More options
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: context.modeTextPrimary),
          color: context.modeSurface,
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
            PopupMenuItem(
              value: 'summary',
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: context.modeTextSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Printer Summary',
                    style: TextStyle(color: context.modeTextPrimary),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20, color: context.modeError),
                  const SizedBox(width: 12),
                  Text('Clear All', style: TextStyle(color: context.modeError)),
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
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
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
                  color: context.modePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.search, color: context.modePrimary, size: 22),
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
                        color: context.modeTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Find printers via Network, Bluetooth, USB',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: context.modeTextSecondary,
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
              color: context.modeSurfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              controller: _tabController,
              indicator: BoxDecoration(
                color: context.modePrimary,
                borderRadius: BorderRadius.circular(8),
              ),
              labelColor: context.modeTextInverse,
              unselectedLabelColor: context.modeTextSecondary,
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
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
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
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              context.modeTextInverse,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Scanning...',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: context.modeTextInverse,
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
                            color: context.modeTextInverse,
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
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
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
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_discoveredPrinters.length} printer(s) found',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: context.modeTextSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20,
                  color: context.modeTextSecondary,
                ),
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
            separatorBuilder: (context, index) =>
                Divider(height: 24, color: context.modeDivider, thickness: 1),
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
                      color: context.modeTextPrimary,
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
                            color: context.modeTextSecondary,
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
              color: context.modeTextMuted,
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
        color: context.modeSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.modeBorder, width: 1),
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
                  color: context.modeTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: context.modePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_printerService.printers.length}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.modePrimary,
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
                      color: context.modeTextMuted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No printers configured',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: context.modeTextMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan or add manually',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: context.modeTextSecondary,
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
              separatorBuilder: (context, index) =>
                  Divider(height: 24, color: context.modeDivider, thickness: 1),
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
    final statusColor = context.modeSuccess;
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
                      color: context.modeTextPrimary,
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
                            color: context.modeTextSecondary,
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
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.modePrimary,
                ),
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
              color: context.modeTextMuted,
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

  InputDecoration _printerInputDecoration({
    required String label,
    String? hint,
    String? helper,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: WorkSansAppTextStyles.medium.copyWith(
        color: context.modeTextSecondary,
      ),
      hintText: hint,
      hintStyle: WorkSansAppTextStyles.medium.copyWith(
        color: context.modeTextMuted,
      ),
      helperText: helper,
      helperStyle: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 11,
        color: context.modeTextMuted,
      ),
      filled: true,
      fillColor: context.modeSurfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.modeBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.modeBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.modePrimary),
      ),
    );
  }

  TextStyle get _dialogTitleStyle => WorkSansAppTextStyles.medium.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: context.modeTextPrimary,
  );

  TextStyle get _dialogBodyStyle =>
      WorkSansAppTextStyles.medium.copyWith(color: context.modeTextPrimary);

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
          backgroundColor: context.modeSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Add Printer', style: _dialogTitleStyle),
                const SizedBox(height: 24),
                TextField(
                  controller: nameController,
                  style: _dialogBodyStyle,
                  decoration: _printerInputDecoration(label: 'Printer Name'),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: context.modeSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.modeBorder),
                  ),
                  child: SwitchListTile(
                    title: Text(
                      'Kitchen Printer',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: context.modeTextPrimary,
                      ),
                    ),
                    subtitle: Text(
                      'Orders will be printed automatically',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 13,
                        color: context.modeTextSecondary,
                      ),
                    ),
                    value: isKitchen,
                    activeThumbColor: context.modePrimary,
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
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: context.modeTextSecondary),
                        ),
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
                              backgroundColor: context.modeSuccess,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.modePrimary,
                          foregroundColor: context.modeTextInverse,
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
          backgroundColor: context.modeSurface,
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
                  Text('Add Printer Manually', style: _dialogTitleStyle),
                  const SizedBox(height: 24),

                  // Printer Name
                  TextField(
                    controller: nameController,
                    style: _dialogBodyStyle,
                    decoration: _printerInputDecoration(
                      label: 'Printer Name',
                      hint: 'e.g., Kitchen Printer 1',
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Connection Type Selector
                  Text(
                    'Connection Type',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.modeTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: context.modeSurfaceAlt,
                      border: Border.all(color: context.modeBorder),
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
                              Text(
                                'Network (Wi-Fi/Ethernet)',
                                style: TextStyle(
                                  color: context.modeTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          value: PrinterConnectionType.network,
                          groupValue: selectedType,
                          activeColor: context.modePrimary,
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
                              Text(
                                'Bluetooth',
                                style: TextStyle(
                                  color: context.modeTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          value: PrinterConnectionType.bluetooth,
                          groupValue: selectedType,
                          activeColor: context.modePrimary,
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
                              Text(
                                'USB',
                                style: TextStyle(
                                  color: context.modeTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          value: PrinterConnectionType.usb,
                          groupValue: selectedType,
                          activeColor: context.modePrimary,
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
                              Text(
                                'Serial Port',
                                style: TextStyle(
                                  color: context.modeTextPrimary,
                                ),
                              ),
                            ],
                          ),
                          value: PrinterConnectionType.serial,
                          groupValue: selectedType,
                          activeColor: context.modePrimary,
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
                      style: _dialogBodyStyle,
                      keyboardType: TextInputType.number,
                      decoration: _printerInputDecoration(
                        label: 'IP Address',
                        hint: '192.168.1.100',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: portController,
                      style: _dialogBodyStyle,
                      keyboardType: TextInputType.number,
                      decoration: _printerInputDecoration(
                        label: 'Port',
                        hint: '9100',
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.bluetooth) ...[
                    TextField(
                      controller: bluetoothAddressController,
                      style: _dialogBodyStyle,
                      decoration: _printerInputDecoration(
                        label: 'Bluetooth Address',
                        hint: 'XX:XX:XX:XX:XX:XX',
                        helper: 'Use scanner to find address automatically',
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.usb) ...[
                    TextField(
                      controller: usbDeviceIdController,
                      style: _dialogBodyStyle,
                      keyboardType: TextInputType.number,
                      decoration: _printerInputDecoration(
                        label: 'USB Device ID',
                        hint: 'Device identifier',
                        helper: 'Use scanner to find device automatically',
                      ),
                    ),
                  ],

                  if (selectedType == PrinterConnectionType.serial) ...[
                    TextField(
                      controller: serialPortController,
                      style: _dialogBodyStyle,
                      decoration: _printerInputDecoration(
                        label: 'Serial Port',
                        hint: 'COM1 or /dev/ttyUSB0',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: baudRateController,
                      style: _dialogBodyStyle,
                      keyboardType: TextInputType.number,
                      decoration: _printerInputDecoration(
                        label: 'Baud Rate',
                        hint: '9600',
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Kitchen/Receipt toggle
                  Container(
                    decoration: BoxDecoration(
                      color: context.modeSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.modeBorder),
                    ),
                    child: SwitchListTile(
                      title: Text(
                        'Kitchen Printer',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: context.modeTextPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'Orders will be printed automatically',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 13,
                          color: context.modeTextSecondary,
                        ),
                      ),
                      value: isKitchen,
                      activeThumbColor: context.modePrimary,
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
                              side: BorderSide(color: context.modeBorder),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: context.modeTextSecondary,
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
                                  backgroundColor: context.modeError,
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
                                backgroundColor: context.modeSuccess,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.modePrimary,
                            foregroundColor: context.modeTextInverse,
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
                              color: context.modeTextInverse,
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
      backgroundColor: context.modeSurface,
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
                color: context.modeBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              printer.name,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.modeTextPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              printer.connectionInfo,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.print, color: Color(0xFF2196F3)),
              title: Text(
                'Test Print',
                style: TextStyle(color: context.modeTextPrimary),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.modeTextMuted,
              ),
              onTap: () {
                Navigator.pop(context);
                _testPrinter(printer);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: context.modeError),
              title: Text(
                'Remove Printer',
                style: TextStyle(color: context.modeError),
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: context.modeTextMuted,
              ),
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
          backgroundColor: success ? context.modeSuccess : context.modeError,
        ),
      );
    }
  }

  void _confirmDelete(PrinterConfig printer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.modeSurface,
        title: Text('Remove Printer', style: _dialogTitleStyle),
        content: Text(
          'Remove "${printer.name}"?',
          style: TextStyle(color: context.modeTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.modeTextSecondary),
            ),
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
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
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
        backgroundColor: context.modeSurface,
        title: Text('Clear All Printers', style: _dialogTitleStyle),
        content: Text(
          'Remove all configured printers? This cannot be undone.',
          style: TextStyle(color: context.modeTextPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: context.modeTextSecondary),
            ),
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
              backgroundColor: context.modeError,
              foregroundColor: context.modeTextInverse,
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
        backgroundColor: context.modeSurface,
        title: Text('Printer Summary', style: _dialogTitleStyle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total: ${summary['total']}', style: _dialogBodyStyle),
            const SizedBox(height: 8),
            Text('Network: ${summary['network']}', style: _dialogBodyStyle),
            Text('Bluetooth: ${summary['bluetooth']}', style: _dialogBodyStyle),
            Text('USB: ${summary['usb']}', style: _dialogBodyStyle),
            Text('Serial: ${summary['serial']}', style: _dialogBodyStyle),
            Divider(color: context.modeDivider),
            Text('Kitchen: ${summary['kitchen']}', style: _dialogBodyStyle),
            Text('Receipt: ${summary['receipt']}', style: _dialogBodyStyle),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: context.modePrimary)),
          ),
        ],
      ),
    );
  }
}
