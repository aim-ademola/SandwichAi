// transfer_service.dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';

class TransferService {
  static final TransferService _instance = TransferService._internal();
  factory TransferService() => _instance;
  TransferService._internal();

  Timer? _transferTimer;
  final List<TransferItem> _pendingTransfers = [];
  final List<TransferItem> _processedTransfers = [];

  BuildContext? _context;

  List<TransferItem> get pendingTransfers => _pendingTransfers;
  List<TransferItem> get processedTransfers => _processedTransfers;

  // Sample items that can be transferred
  final List<Map<String, dynamic>> _availableItems = [
    {
      'name': 'Fresh Tomatoes',
      'sku': '54321',
      'expectedQty': 50.0,
      'unit': 'KG',
      'image': '🍅',
      'fromDept': 'Warehouse',
    },
    {
      'name': 'Potatoes',
      'sku': '65432',
      'expectedQty': 75.0,
      'unit': 'KG',
      'image': '🥔',
      'fromDept': 'Storage',
    },
    {
      'name': 'Carrots',
      'sku': '98765',
      'expectedQty': 30.0,
      'unit': 'KG',
      'image': '🥕',
      'fromDept': 'Warehouse',
    },
    {
      'name': 'Ground Beef',
      'sku': '11223',
      'expectedQty': 100.0,
      'unit': 'KG',
      'image': '🥩',
      'fromDept': 'Cold Storage',
    },
    {
      'name': 'Lettuce',
      'sku': '33445',
      'expectedQty': 25.0,
      'unit': 'KG',
      'image': '🥬',
      'fromDept': 'Warehouse',
    },
  ];

  void initialize(BuildContext context) {
    _context = context;
    startTransferSimulation();
  }

  void updateContext(BuildContext context) {
    _context = context;
  }

  void dispose() {
    _transferTimer?.cancel();
    _context = null;
  }

  void startTransferSimulation() {
    _transferTimer?.cancel();
    _transferTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_context != null && _context!.mounted) {
        _simulateTransfer();
      }
    });
  }

  void stopTransferSimulation() {
    _transferTimer?.cancel();
  }

  void _simulateTransfer() {
    if (_context == null || !_context!.mounted) return;

    // Randomly select 1-3 items to transfer
    final random = DateTime.now().millisecondsSinceEpoch;
    final itemCount = (random % 3) + 1;

    final List<TransferItem> newTransfers = [];
    for (int i = 0; i < itemCount; i++) {
      final itemData = _availableItems[random % _availableItems.length];
      newTransfers.add(
        TransferItem(
          id: 'TRANS_${DateTime.now().millisecondsSinceEpoch}_$i',
          name: itemData['name'],
          sku: itemData['sku'],
          expectedQty: itemData['expectedQty'],
          unit: itemData['unit'],
          image: itemData['image'],
          fromDepartment: itemData['fromDept'],
          transferDate: DateTime.now(),
        ),
      );
    }

    _showTransferAlert(newTransfers);
  }

  void _showTransferAlert(List<TransferItem> transfers) {
    if (_context == null || !_context!.mounted) return;

    showDialog(
      context: _context!,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_shipping, color: kPrimary, size: 32),
              ),
              const SizedBox(height: 20),
              Text(
                'New Transfer Received',
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kprimaryTextColor1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${transfers.length} item${transfers.length > 1 ? 's' : ''} transferred from ${transfers.first.fromDepartment}',
                textAlign: TextAlign.center,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: transfers.take(3).map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text(
                            item.image,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.name,
                              style: WorkSansAppTextStyles.medium.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kprimaryTextColor1,
                              ),
                            ),
                          ),
                          Text(
                            '${item.expectedQty.toStringAsFixed(0)} ${item.unit}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (transfers.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '+${transfers.length - 3} more items',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Later',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kprimaryTextColor1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pendingTransfers.addAll(transfers);
                        // Navigate to delivery validation screen
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) =>
                                const DeliveryValidationScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Review Now',
                          textAlign: TextAlign.center,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }

  void handleAccept(TransferItem item) {
    item.status = TransferStatus.accepted;
    _pendingTransfers.remove(item);
    _processedTransfers.insert(0, item);
  }

  void handleReject(TransferItem item) {
    item.status = TransferStatus.rejected;
    _pendingTransfers.remove(item);
    _processedTransfers.insert(0, item);
  }

  void handleAddToInventory(TransferItem item) {
    item.addedToInventory = true;
  }
}

// transfer_item.dart
enum TransferStatus { pending, accepted, rejected }

class TransferItem {
  final String id;
  final String name;
  final String sku;
  final double expectedQty;
  final String unit;
  final String image;
  final String fromDepartment;
  final DateTime transferDate;

  TransferStatus status;
  bool isExpanded;
  bool qualityCheckPassed;
  bool addedToInventory;

  final TextEditingController actualQtyController;
  final TextEditingController qualityNotesController;

  TransferItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.expectedQty,
    required this.unit,
    required this.image,
    required this.fromDepartment,
    required this.transferDate,
    this.status = TransferStatus.pending,
    this.isExpanded = true,
    this.qualityCheckPassed = true,
    this.addedToInventory = false,
  }) : actualQtyController = TextEditingController(),
       qualityNotesController = TextEditingController();

  void dispose() {
    actualQtyController.dispose();
    qualityNotesController.dispose();
  }
}

class DeliveryValidationScreen extends StatefulWidget {
  const DeliveryValidationScreen({super.key});

  @override
  State<DeliveryValidationScreen> createState() =>
      _DeliveryValidationScreenState();
}

class _DeliveryValidationScreenState extends State<DeliveryValidationScreen> {
  final TransferService _transferService = TransferService();

  @override
  void initState() {
    super.initState();
    _transferService.updateContext(context);
  }

  void _handleAccept(TransferItem item) {
    setState(() {
      _transferService.handleAccept(item);
    });
  }

  void _handleReject(TransferItem item) {
    setState(() {
      _transferService.handleReject(item);
    });
  }

  void _handleAddToInventory(TransferItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item.name} added to inventory',
          style: WorkSansAppTextStyles.medium.copyWith(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    setState(() {
      _transferService.handleAddToInventory(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: kprimaryTextColor1),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Delivery Validation',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner Image Area
              Container(
                width: double.infinity,
                height: 150,
                color: const Color(0xFFE8D5C4),
                child: Center(
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Items for Review Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Items for Review',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Pending Items
              if (_transferService.pendingTransfers.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No pending transfers',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: kprimaryTextColor2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'All items have been reviewed',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: kprimaryTextColor2.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _transferService.pendingTransfers.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(
                      _transferService.pendingTransfers[index],
                    );
                  },
                ),

              // Processed Items Section
              if (_transferService.processedTransfers.isNotEmpty) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Processed Items',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _transferService.processedTransfers.length,
                  itemBuilder: (context, index) {
                    return _buildProcessedItemCard(
                      _transferService.processedTransfers[index],
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(TransferItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF6B35), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(item.image, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.name} (SKU: ${item.sku})',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: kprimaryTextColor2,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Expected: ${item.expectedQty.toStringAsFixed(0)} ${item.unit}',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    item.isExpanded = !item.isExpanded;
                  });
                },
                child: Icon(
                  item.isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: kprimaryTextColor2,
                ),
              ),
            ],
          ),
          if (item.isExpanded) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actual Quantity (${item.unit})',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: item.actualQtyController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'e.g., 49.5',
                      hintStyle: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        color: kprimaryTextColor2.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: kPrimary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quality Check',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kprimaryTextColor1,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      item.qualityCheckPassed = !item.qualityCheckPassed;
                    });
                  },
                  child: Icon(
                    item.qualityCheckPassed ? Icons.close : Icons.check,
                    size: 20,
                    color: item.qualityCheckPassed
                        ? Colors.red
                        : const Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: item.qualityNotesController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Packaging Intact, Freshness ok.',
                  hintStyle: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kprimaryTextColor2.withValues(alpha: 0.5),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 13,
                  color: kprimaryTextColor1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleReject(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCDD2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Reject',
                        textAlign: TextAlign.center,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _handleAccept(item),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC8E6C9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Accept',
                        textAlign: TextAlign.center,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF388E3C),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProcessedItemCard(TransferItem item) {
    final isAccepted = item.status == TransferStatus.accepted;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted
              ? const Color(0xFFC8E6C9).withValues(alpha: 0.5)
              : const Color(0xFFFFCDD2).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(item.image, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kprimaryTextColor1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isAccepted ? 'Accepted' : 'Rejected',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: isAccepted
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFD32F2F),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isAccepted && !item.addedToInventory)
                GestureDetector(
                  onTap: () => _handleAddToInventory(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Add to Inventory',
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              if (item.addedToInventory)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Color(0xFF4CAF50),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'In Inventory',
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (item.status == TransferStatus.rejected &&
              item.qualityNotesController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rejection Note',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kprimaryTextColor1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.qualityNotesController.text,
                      style: WorkSansAppTextStyles.medium.copyWith(
                        fontSize: 12,
                        color: kprimaryTextColor2,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 16,
                    color: kprimaryTextColor2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
