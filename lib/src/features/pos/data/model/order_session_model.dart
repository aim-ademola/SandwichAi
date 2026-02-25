import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_order_dtls_dialoge.dart';

enum SessionStatus { building, detailsConfirmed, paymentInProgress, completed }

enum MinimizedScreen { orderSummary, paymentMethod, cashWaiting, onlineQr }

class OrderSession {
  final String sessionId;
  final String label;
  final Map<String, int> orderItems;
  final Map<String, String> specialRequests;
  final PosOrderDetails? orderDetails;
  final SessionPaymentState paymentState;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  final MinimizedScreen? minimizedScreen;

  const OrderSession({
    required this.sessionId,
    required this.label,
    this.orderItems = const {},
    this.specialRequests = const {},
    this.orderDetails,
    this.paymentState = const SessionPaymentState.none(),
    this.status = SessionStatus.building,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.minimizedScreen,
  });

  int get totalItemCount => orderItems.values.fold(0, (sum, qty) => sum + qty);

  bool get hasItems => orderItems.isNotEmpty;
  bool get hasOrderDetails => orderDetails != null;

  /// Whether this session was minimized mid-flow and needs to be resumed.
  bool get isMinimized => minimizedScreen != null;

  double computeTotal(List<ApiMenuItem> allMenuItems) {
    double total = 0;
    for (final entry in orderItems.entries) {
      final item = allMenuItems.where((i) => i.id == entry.key).firstOrNull;
      if (item != null) {
        total += (double.tryParse(item.price) ?? 0) * entry.value;
      }
    }
    return total;
  }

  OrderSession copyWith({
    String? label,
    Map<String, int>? orderItems,
    Map<String, String>? specialRequests,
    PosOrderDetails? orderDetails,
    bool clearOrderDetails = false,
    SessionPaymentState? paymentState,
    SessionStatus? status,
    MinimizedScreen? minimizedScreen,
    bool clearMinimizedScreen = false,
  }) {
    return OrderSession(
      sessionId: sessionId,
      label: label ?? this.label,
      orderItems: orderItems ?? Map.from(this.orderItems),
      specialRequests: specialRequests ?? Map.from(this.specialRequests),
      orderDetails: clearOrderDetails
          ? null
          : (orderDetails ?? this.orderDetails),
      paymentState: paymentState ?? this.paymentState,
      status: status ?? this.status,
      createdAt: createdAt,
      lastUpdatedAt: DateTime.now(),
      minimizedScreen: clearMinimizedScreen
          ? null
          : (minimizedScreen ?? this.minimizedScreen),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderSession && other.sessionId == sessionId;

  @override
  int get hashCode => sessionId.hashCode;
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment state snapshot
// ─────────────────────────────────────────────────────────────────────────────

enum PaymentMethod { none, cash, cardOrBankTransfer }

class SessionPaymentState {
  final PaymentMethod method;
  final String? createdOrderId;
  final dynamic onlinePaymentInitData;
  final dynamic cashTransaction;
  final bool isProcessing;
  final String? errorMessage;

  const SessionPaymentState.none()
    : method = PaymentMethod.none,
      createdOrderId = null,
      onlinePaymentInitData = null,
      cashTransaction = null,
      isProcessing = false,
      errorMessage = null;

  const SessionPaymentState({
    required this.method,
    this.createdOrderId,
    this.onlinePaymentInitData,
    this.cashTransaction,
    this.isProcessing = false,
    this.errorMessage,
  });

  bool get hasOrderId => createdOrderId != null;

  SessionPaymentState copyWith({
    PaymentMethod? method,
    String? createdOrderId,
    dynamic onlinePaymentInitData,
    dynamic cashTransaction,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SessionPaymentState(
      method: method ?? this.method,
      createdOrderId: createdOrderId ?? this.createdOrderId,
      onlinePaymentInitData:
          onlinePaymentInitData ?? this.onlinePaymentInitData,
      cashTransaction: cashTransaction ?? this.cashTransaction,
      isProcessing: isProcessing ?? this.isProcessing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
