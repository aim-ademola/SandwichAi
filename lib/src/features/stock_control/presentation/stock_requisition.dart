// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
// import 'package:sandwich_ai/src/core/constant/textstyle.dart';
// import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/bloc.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/event.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/branch_stock_bloc/state.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/bloc.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/event.dart';
// import 'package:sandwich_ai/src/features/stock_control/bloc/processing_transfrer_bloc/state.dart';

// import 'package:sandwich_ai/src/features/stock_control/data/model/branch_stock_model.dart';
// import 'package:sandwich_ai/src/features/stock_control/data/model/processing_transfer_model.dart';
// import 'package:intl/intl.dart';
// import 'package:sandwich_ai/src/features/stock_control/presentation/shimmer_card.dart';

// class RequisitionItem {
//   String itemId;
//   String itemName;
//   int quantity;

//   RequisitionItem({
//     required this.itemId,
//     required this.itemName,
//     required this.quantity,
//   });
// }

// class StockRequisitionScreen extends StatefulWidget {
//   const StockRequisitionScreen({super.key});

//   @override
//   State<StockRequisitionScreen> createState() => _StockRequisitionScreenState();
// }

// class _StockRequisitionScreenState extends State<StockRequisitionScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _batchCodeController = TextEditingController();
//   final TextEditingController _notesController = TextEditingController();
//   final TextEditingController _searchController = TextEditingController();
//   final TextEditingController _quantityController = TextEditingController();

//   String? _selectedItemId;
//   String? _selectedItemName;
//   String branchId = '';
//   String employeeId = '';
//   bool _isSearching = false;
//   bool _isOpened = false;

//   final List<RequisitionItem> _requisitionItems = [];
//   List<CatalogItem> _filteredItems = [];
//   List<CatalogItem> _allItems = [];

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 3, vsync: this);
//     _getBranchAndEmployeeData();
//     _searchController.addListener(_onSearchChanged);

//     // Load transfers when screen initializes
//     Future.delayed(Duration.zero, () {
//       context.read<ProcessingTransferBloc>().add(
//         LoadProcessingTransfers(branchId: branchId),
//       );
//       context.read<BranchStockBloc>().add(LoadBranchStock(branchId: branchId));
//     });
//   }

//   void _getBranchAndEmployeeData() async {
//     final bId = await AuthCacheHelper.instance.getBranchID() ?? '';
//     final empId = await AuthCacheHelper.instance.getEmpID() ?? '';

//     setState(() {
//       branchId = bId;
//       employeeId = empId;
//     });
//   }

//   void _onSearchChanged() {
//     setState(() {
//       if (_searchController.text.isEmpty) {
//         _filteredItems = _allItems;
//       } else {
//         _filteredItems = _allItems
//             .where(
//               (item) => item.name.toLowerCase().contains(
//                 _searchController.text.toLowerCase(),
//               ),
//             )
//             .toList();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _batchCodeController.dispose();
//     _notesController.dispose();
//     _searchController.dispose();
//     _quantityController.dispose();
//     super.dispose();
//   }

//   // void _addItemToList() {
//   //   if (_selectedItemId == null ||
//   //       _selectedItemName == null ||
//   //       _quantityController.text.trim().isEmpty) {
//   //     _showSnackBar('Please select an item and enter quantity', isError: true);
//   //     return;
//   //   }

//   //   final quantity = int.tryParse(_quantityController.text.trim());
//   //   if (quantity == null || quantity <= 0) {
//   //     _showSnackBar('Please enter a valid quantity', isError: true);
//   //     return;
//   //   }

//   //   setState(() {
//   //     _requisitionItems.add(
//   //       RequisitionItem(
//   //         itemId: _selectedItemId!,
//   //         itemName: _selectedItemName!,
//   //         quantity: quantity,
//   //       ),
//   //     );
//   //     _selectedItemId = null;
//   //     _selectedItemName = null;
//   //     _quantityController.clear();
//   //     _isSearching = false;
//   //     _isOpened = false;
//   //   });

//   //   _showSnackBar(
//   //     'Item added to requisition list',
//   //     backgroundColor: Colors.green,
//   //   );
//   // }

//   void _removeItem(int index) {
//     setState(() {
//       _requisitionItems.removeAt(index);
//     });
//   }

//   void _submitRequisition() {
//     // if (_requisitionItems.isEmpty) {
//     //   _showSnackBar(
//     //     'Please add at least one item to the requisition',
//     //     isError: true,
//     //   );
//     //   return;
//     // }

//     if (_batchCodeController.text.trim().isEmpty) {
//       _showSnackBar('Please enter a batch code', isError: true);
//       return;
//     }

//     final request = ProcessingTransferRequest(
//       branchId: branchId,
//       batchCode: _batchCodeController.text.trim(),
//       sentBy: employeeId,
//       items: _requisitionItems
//           .map(
//             (item) => TransferItem(itemId: item.itemId, qtySent: item.quantity),
//           )
//           .toList(),
//       notes: _notesController.text.trim().isEmpty
//           ? null
//           : _notesController.text.trim(),
//     );

//     context.read<ProcessingTransferBloc>().add(
//       CreateProcessingTransfer(request: request),
//     );
//   }

//   void _showSnackBar(
//     String message, {
//     bool isError = false,
//     Color? backgroundColor,
//   }) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           message,
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 14,
//             color: Colors.white,
//           ),
//         ),
//         backgroundColor: backgroundColor ?? (isError ? Colors.red : kPrimary),
//         behavior: SnackBarBehavior.floating,
//         duration: Duration(seconds: isError ? 3 : 2),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocListener(
//       listeners: [
//         BlocListener<ProcessingTransferBloc, ProcessingTransferState>(
//           listener: (context, state) {
//             if (state is ProcessingTransferCreated) {
//               _showSnackBar(
//                 'Requisition submitted successfully!',
//                 backgroundColor: Colors.green,
//               );

//               // Clear form
//               setState(() {
//                 _requisitionItems.clear();
//                 _batchCodeController.clear();
//                 _notesController.clear();
//               });

//               // Switch to pending tab
//               _tabController.animateTo(1);
//             } else if (state is ProcessingTransferError) {
//               _showSnackBar(state.error, isError: true);
//             }
//           },
//         ),
//       ],
//       child: BlocBuilder<BranchStockBloc, BranchStockState>(
//         builder: (context, stockState) {
//           if (stockState is BranchStockLoaded && _allItems.isEmpty) {
//             _allItems = stockState.filteredItems;
//             _filteredItems = stockState.filteredItems;
//           }

//           return DefaultTextStyle.merge(
//             style: WorkSansAppTextStyles.medium,
//             child: Scaffold(
//               backgroundColor: const Color(0xFFF8F6F6),
//               appBar: AppBar(
//                 backgroundColor: Colors.white,
//                 elevation: 0,
//                 leading: IconButton(
//                   icon: const AppIcon(Icons.arrow_back, color: Colors.black),
//                   onPressed: () => Navigator.pop(context),
//                 ),
//                 title: Text(
//                   'Requisition',
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 18,
//                     fontWeight: FontWeight.w600,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//                 centerTitle: true,
//               ),
//               body: Column(
//                 children: [
//                   Container(
//                     color: Colors.white,
//                     child: TabBar(
//                       controller: _tabController,
//                       labelColor: kPrimary,
//                       unselectedLabelColor: kprimaryTextColor2,
//                       indicatorColor: kPrimary,
//                       indicatorWeight: 3,
//                       labelStyle: WorkSansAppTextStyles.medium.copyWith(
//                         fontSize: 15,
//                         fontWeight: FontWeight.w600,
//                       ),
//                       unselectedLabelStyle: WorkSansAppTextStyles.medium
//                           .copyWith(fontSize: 15, fontWeight: FontWeight.w500),
//                       tabs: const [
//                         Tab(text: 'Create Requisition'),
//                         Tab(text: 'Pending'),
//                         Tab(text: 'Completed'),
//                       ],
//                     ),
//                   ),
//                   Expanded(
//                     child: TabBarView(
//                       controller: _tabController,
//                       children: [
//                         _buildCreateRequisitionTab(),
//                         _buildPendingTab(),
//                         _buildCompletedTab(),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Widget _buildCreateRequisitionTab() {
//     return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
//       builder: (context, state) {
//         final isLoading = state is ProcessingTransferCreating;

//         return SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Batch Code
//               Text(
//                 'Batch Code *',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: kprimaryTextColor1,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: TextField(
//                   controller: _batchCodeController,
//                   cursorColor: kPrimary,
//                   decoration: InputDecoration(
//                     hintText: 'e.g., CC2204',
//                     hintStyle: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 14,
//                       color: kprimaryTextColor2,
//                     ),
//                     border: InputBorder.none,
//                   ),
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 14,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Item Selection
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     'Add Items',
//                     style: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 16,
//                       fontWeight: FontWeight.w600,
//                       color: kprimaryTextColor1,
//                     ),
//                   ),
//                   if (_requisitionItems.isNotEmpty)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 8,
//                         vertical: 4,
//                       ),
//                       decoration: BoxDecoration(
//                         color: kPrimary.withValues(alpha: 0.1),
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       child: Text(
//                         '${_requisitionItems.length} item(s)',
//                         style: WorkSansAppTextStyles.medium.copyWith(
//                           fontSize: 12,
//                           fontWeight: FontWeight.w600,
//                           color: kPrimary,
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               const SizedBox(height: 16),

//               _buildItemSearchField(),
//               const SizedBox(height: 12),
//               _buildQuantityField(),

//               if (_requisitionItems.isNotEmpty) ...[
//                 const SizedBox(height: 24),
//                 Text(
//                   'Items in Requisition',
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 ...List.generate(_requisitionItems.length, (index) {
//                   final item = _requisitionItems[index];
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.grey.shade200),
//                     ),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 32,
//                           height: 32,
//                           decoration: BoxDecoration(
//                             color: kPrimary.withValues(alpha: 0.1),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Center(
//                             child: Text(
//                               '${index + 1}',
//                               style: WorkSansAppTextStyles.medium.copyWith(
//                                 fontSize: 14,
//                                 fontWeight: FontWeight.w600,
//                                 color: kPrimary,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item.itemName,
//                                 style: WorkSansAppTextStyles.medium.copyWith(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w600,
//                                   color: kprimaryTextColor1,
//                                 ),
//                               ),
//                               const SizedBox(height: 2),
//                               Text(
//                                 'Qty: ${item.quantity}',
//                                 style: WorkSansAppTextStyles.medium.copyWith(
//                                   fontSize: 13,
//                                   color: kprimaryTextColor2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         IconButton(
//                           icon: const AppIcon(Icons.close, size: 20),
//                           color: Colors.red,
//                           onPressed: () => _removeItem(index),
//                         ),
//                       ],
//                     ),
//                   );
//                 }),
//               ],

//               const SizedBox(height: 20),

//               // Notes
//               Text(
//                 'Note/Instructions',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: kprimaryTextColor1,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: TextField(
//                   controller: _notesController,
//                   cursorColor: kPrimary,
//                   maxLines: 4,
//                   decoration: InputDecoration(
//                     hintText: 'Add any additional notes or instructions...',
//                     hintStyle: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 14,
//                       color: kprimaryTextColor2,
//                     ),
//                     border: InputBorder.none,
//                   ),
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 14,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 32),

//               // Submit button
//               GestureDetector(
//                 onTap: isLoading ? null : _submitRequisition,
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   decoration: BoxDecoration(
//                     color: isLoading ? Colors.grey : kPrimary,
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: isLoading
//                       ? Center(
//                           child: SizedBox(
//                             height: 20,
//                             width: 20,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(
//                                 Colors.white,
//                               ),
//                             ),
//                           ),
//                         )
//                       : Text(
//                           'Submit Requisition',
//                           textAlign: TextAlign.center,
//                           style: WorkSansAppTextStyles.medium.copyWith(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildItemSearchField() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Select Item *',
//           style: WorkSansAppTextStyles.medium.copyWith(
//             fontSize: 14,
//             fontWeight: FontWeight.w600,
//             color: kprimaryTextColor1,
//           ),
//         ),
//         const SizedBox(height: 8),
//         GestureDetector(
//           onTap: () {
//             setState(() {
//               _isOpened = !_isOpened;
//               _isSearching = true;
//             });
//           },
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: _selectedItemId == null && !_isSearching
//                     ? Colors.grey.shade300
//                     : kPrimary.withValues(alpha: 0.3),
//                 width: 1.5,
//               ),
//             ),
//             child: Row(
//               children: [
//                 AppIcon(Icons.search, color: kprimaryTextColor2, size: 20),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _selectedItemName ?? 'Search and select an item',
//                     style: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 14,
//                       color: _selectedItemName != null
//                           ? kprimaryTextColor1
//                           : kprimaryTextColor2,
//                     ),
//                   ),
//                 ),
//                 AppIcon(
//                   _isOpened ? Icons.arrow_drop_down : Icons.arrow_drop_up,
//                   color: kprimaryTextColor2,
//                   size: 24,
//                 ),
//               ],
//             ),
//           ),
//         ),
//         if (_isSearching && _isOpened) ...[
//           const SizedBox(height: 12),
//           _buildSearchDropdown(),
//         ],
//       ],
//     );
//   }

//   Widget _buildSearchDropdown() {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 200),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(12),
//             child: TextField(
//               controller: _searchController,
//               autofocus: true,
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 color: kprimaryTextColor1,
//               ),
//               decoration: InputDecoration(
//                 hintText: 'Type to search...',
//                 hintStyle: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: 14,
//                   color: kprimaryTextColor2,
//                 ),
//                 prefixIcon: AppIconSlot(Icons.search, size: 20),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: Colors.grey.shade300),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: kPrimary, width: 1.5),
//                 ),
//                 contentPadding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 12,
//                 ),
//               ),
//             ),
//           ),
//           Divider(height: 1, color: Colors.grey.shade200),
//           Expanded(
//             child: _filteredItems.isEmpty
//                 ? Center(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Text(
//                         'No items found',
//                         style: WorkSansAppTextStyles.medium.copyWith(
//                           fontSize: 14,
//                           color: kprimaryTextColor2,
//                         ),
//                       ),
//                     ),
//                   )
//                 : ListView.builder(
//                     itemCount: _filteredItems.length,
//                     itemBuilder: (context, index) {
//                       final item = _filteredItems[index];
//                       return InkWell(
//                         onTap: () {
//                           setState(() {
//                             _selectedItemId = item.id;
//                             _selectedItemName = item.name;
//                             _isSearching = false;
//                             _isOpened = false;
//                             _searchController.clear();
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             border: Border(
//                               bottom: BorderSide(
//                                 color: Colors.grey.shade200,
//                                 width: 1,
//                               ),
//                             ),
//                           ),
//                           child: Row(
//                             children: [
//                               Container(
//                                 width: 32,
//                                 height: 32,
//                                 decoration: BoxDecoration(
//                                   color: kPrimary.withValues(alpha: 0.1),
//                                   borderRadius: BorderRadius.circular(6),
//                                 ),
//                                 child: const AppIcon(
//                                   Icons.inventory_2_outlined,
//                                   color: kPrimary,
//                                   size: 18,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       item.name,
//                                       style: WorkSansAppTextStyles.medium
//                                           .copyWith(
//                                             fontSize: 14,
//                                             fontWeight: FontWeight.w600,
//                                             color: kprimaryTextColor1,
//                                           ),
//                                     ),
//                                     const SizedBox(height: 2),
//                                     Text(
//                                       item.category,
//                                       style: WorkSansAppTextStyles.medium
//                                           .copyWith(
//                                             fontSize: 12,
//                                             color: kprimaryTextColor2,
//                                           ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildQuantityField() {
//     return Row(
//       children: [
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 'Quantity *',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w600,
//                   color: kprimaryTextColor1,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: TextField(
//                   controller: _quantityController,
//                   cursorColor: kPrimary,
//                   keyboardType: TextInputType.number,
//                   decoration: InputDecoration(
//                     hintText: 'Enter quantity',
//                     hintStyle: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 14,
//                       color: kprimaryTextColor2,
//                     ),
//                     border: InputBorder.none,
//                   ),
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 14,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 12),
//         // Padding(
//         //   padding: const EdgeInsets.only(top: 28),
//         //   child: GestureDetector(
//         //     onTap: _addItemToList,
//         //     child: Container(
//         //       padding: const EdgeInsets.all(16),
//         //       decoration: BoxDecoration(
//         //         color: kPrimary,
//         //         borderRadius: BorderRadius.circular(8),
//         //       ),
//         //       child: const AppIcon(Icons.add, color: Colors.white, size: 24),
//         //     ),
//         //   ),
//         // ),
//       ],
//     );
//   }

//   Widget _buildPendingTab() {
//     return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
//       builder: (context, state) {
//         if (state is ProcessingTransferLoading) {
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               return shimmerCatalogCard(constraints.maxWidth);
//             },
//           );
//         }

//         if (state is ProcessingTransferError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 AppIcon(Icons.error_outline, size: 60, color: Colors.red.shade300),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Error loading transfers',
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w600,
//                     color: kprimaryTextColor1,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 32),
//                   child: Text(
//                     state.error,
//                     textAlign: TextAlign.center,
//                     style: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 14,
//                       color: kprimaryTextColor2,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () {
//                     context.read<ProcessingTransferBloc>().add(
//                       LoadProcessingTransfers(branchId: branchId),
//                     );
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: kPrimary,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: Text(
//                     'Retry',
//                     style: WorkSansAppTextStyles.medium.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         }

//         if (state is ProcessingTransferListLoaded) {
//           if (state.pendingTransfers.isEmpty) {
//             return _buildEmptyState(
//               icon: Icons.pending_actions_outlined,
//               title: 'No Pending Requisitions',
//               message: 'Your pending requisitions will appear here',
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: () async {
//               context.read<ProcessingTransferBloc>().add(
//                 RefreshProcessingTransfers(branchId: branchId),
//               );
//             },
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: state.pendingTransfers.length,
//               itemBuilder: (context, index) {
//                 final transfer = state.pendingTransfers[index];
//                 return _buildTransferCard(transfer, isPending: true);
//               },
//             ),
//           );
//         }

//         return _buildEmptyState(
//           icon: Icons.pending_actions_outlined,
//           title: 'No Pending Requisitions',
//           message: 'Your pending requisitions will appear here',
//         );
//       },
//     );
//   }

//   Widget _buildCompletedTab() {
//     return BlocBuilder<ProcessingTransferBloc, ProcessingTransferState>(
//       builder: (context, state) {
//         if (state is ProcessingTransferLoading ||
//             state is ProcessingTransferRefreshing) {
//           return LayoutBuilder(
//             builder: (context, constraints) {
//               return shimmerCatalogCard(constraints.maxWidth);
//             },
//           );
//         }

//         if (state is ProcessingTransferListLoaded) {
//           if (state.completedTransfers.isEmpty) {
//             return _buildEmptyState(
//               icon: Icons.check_circle_outline,
//               title: 'No Completed Requisitions',
//               message: 'Your completed requisitions will appear here',
//             );
//           }

//           return RefreshIndicator(
//             onRefresh: () async {
//               context.read<ProcessingTransferBloc>().add(
//                 RefreshProcessingTransfers(branchId: branchId),
//               );
//             },
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: state.completedTransfers.length,
//               itemBuilder: (context, index) {
//                 final transfer = state.completedTransfers[index];
//                 return _buildTransferCard(transfer, isPending: false);
//               },
//             ),
//           );
//         }

//         return _buildEmptyState(
//           icon: Icons.check_circle_outline,
//           title: 'No Completed Requisitions',
//           message: 'Your completed requisitions will appear here',
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState({
//     required IconData icon,
//     required String title,
//     required String message,
//   }) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             AppIcon(icon, size: 80, color: Colors.grey.shade300),
//             const SizedBox(height: 24),
//             Text(
//               title,
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//                 color: kprimaryTextColor1,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               message,
//               textAlign: TextAlign.center,
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 color: kprimaryTextColor2,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildTransferCard(
//     ProcessingTransferResponse transfer, {
//     required bool isPending,
//   }) {
//     final dateFormat = DateFormat('MMM dd, yyyy â€¢ hh:mm a');
//     final formattedDate = dateFormat.format(transfer.createdAt);

//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.grey.shade200),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.04),
//             blurRadius: 8,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Batch: ${transfer.batchCode}',
//                       style: WorkSansAppTextStyles.medium.copyWith(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: kprimaryTextColor1,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       formattedDate,
//                       style: WorkSansAppTextStyles.medium.copyWith(
//                         fontSize: 12,
//                         color: kprimaryTextColor2,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isPending
//                       ? Colors.orange.withValues(alpha: 0.1)
//                       : Colors.green.withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   isPending ? 'Pending' : 'Completed',
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 12,
//                     fontWeight: FontWeight.w600,
//                     color: isPending ? Colors.orange : Colors.green,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           Divider(height: 1, color: Colors.grey.shade200),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               AppIcon(
//                 Icons.inventory_2_outlined,
//                 size: 18,
//                 color: kprimaryTextColor2,
//               ),
//               const SizedBox(width: 8),
//               Text(
//                 '${transfer.items.length} item(s)',
//                 style: WorkSansAppTextStyles.medium.copyWith(
//                   fontSize: 14,
//                   color: kprimaryTextColor1,
//                 ),
//               ),
//             ],
//           ),
//           if (transfer.notes != null && transfer.notes!.isNotEmpty) ...[
//             const SizedBox(height: 8),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 AppIcon(Icons.note_outlined, size: 18, color: kprimaryTextColor2),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   child: Text(
//                     transfer.notes!,
//                     style: WorkSansAppTextStyles.medium.copyWith(
//                       fontSize: 13,
//                       color: kprimaryTextColor2,
//                     ),
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//           const SizedBox(height: 12),
//           InkWell(
//             onTap: () => _showTransferDetails(transfer, isPending),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 Text(
//                   'View Details',
//                   style: WorkSansAppTextStyles.medium.copyWith(
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     color: kPrimary,
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 const AppIcon(Icons.arrow_forward_ios, size: 14, color: kPrimary),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showTransferDetails(
//     ProcessingTransferResponse transfer,
//     bool isPending,
//   ) {
//     final dateFormat = DateFormat('MMMM dd, yyyy â€¢ hh:mm a');
//     final formattedDate = dateFormat.format(transfer.createdAt);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => Container(
//         constraints: BoxConstraints(
//           maxHeight: MediaQuery.of(context).size.height * 0.85,
//         ),
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.only(
//             topLeft: Radius.circular(20),
//             topRight: Radius.circular(20),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
//               ),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Requisition Details',
//                           style: WorkSansAppTextStyles.medium.copyWith(
//                             fontSize: 18,
//                             fontWeight: FontWeight.w600,
//                             color: kprimaryTextColor1,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           'Batch: ${transfer.batchCode}',
//                           style: WorkSansAppTextStyles.medium.copyWith(
//                             fontSize: 14,
//                             color: kprimaryTextColor2,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   IconButton(
//                     icon: const AppIcon(Icons.close),
//                     onPressed: () => Navigator.pop(context),
//                   ),
//                 ],
//               ),
//             ),
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildDetailRow(
//                       'Status',
//                       isPending ? 'Pending' : 'Completed',
//                     ),
//                     _buildDetailRow('Date Created', formattedDate),
//                     if (transfer.notes != null && transfer.notes!.isNotEmpty)
//                       _buildDetailRow('Notes', transfer.notes!),
//                     const SizedBox(height: 20),
//                     Text(
//                       'Items (${transfer.items.length})',
//                       style: WorkSansAppTextStyles.medium.copyWith(
//                         fontSize: 16,
//                         fontWeight: FontWeight.w600,
//                         color: kprimaryTextColor1,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     ...transfer.items.asMap().entries.map((entry) {
//                       final index = entry.key;
//                       final item = entry.value;
//                       return Container(
//                         margin: const EdgeInsets.only(bottom: 8),
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.grey.shade50,
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.grey.shade200),
//                         ),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 32,
//                               height: 32,
//                               decoration: BoxDecoration(
//                                 color: kPrimary.withValues(alpha: 0.1),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   '${index + 1}',
//                                   style: WorkSansAppTextStyles.medium.copyWith(
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.w600,
//                                     color: kPrimary,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 12),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     item.item.itemName,
//                                     style: WorkSansAppTextStyles.medium
//                                         .copyWith(
//                                           fontSize: 14,
//                                           fontWeight: FontWeight.w600,
//                                           color: kprimaryTextColor1,
//                                         ),
//                                   ),
//                                   const SizedBox(height: 2),
//                                   Text(
//                                     'Qty Sent: ${item.qtySent}',
//                                     style: WorkSansAppTextStyles.medium
//                                         .copyWith(
//                                           fontSize: 13,
//                                           color: kprimaryTextColor2,
//                                         ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 120,
//             child: Text(
//               label,
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 fontWeight: FontWeight.w600,
//                 color: kprimaryTextColor2,
//               ),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value,
//               style: WorkSansAppTextStyles.medium.copyWith(
//                 fontSize: 14,
//                 color: kprimaryTextColor1,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
