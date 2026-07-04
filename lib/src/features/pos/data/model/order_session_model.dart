import 'package:sandwich_ai/src/features/pos/data/model/api_menu_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_order_dtls_dialoge.dart';

enum SessionStatus {
  building,
  parked,
  detailsConfirmed,
  paymentInProgress,
  paid,
  sentToKitchen,
  completed,
  cancelled,
}

enum MinimizedScreen { orderSummary, paymentMethod, cashWaiting, onlineQr }

class OrderSession {
  final String sessionId;
  final String label;
  final Map<String, int> orderItems;
  final Map<String, String> specialRequests;
  final String? orderNote;
  final String? supportNotes;
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
    this.orderNote,
    this.supportNotes,
    this.orderDetails,
    this.paymentState = const SessionPaymentState.none(),
    this.status = SessionStatus.building,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.minimizedScreen,
  });

  factory OrderSession.fromJson(Map<String, dynamic> json) {
    return OrderSession(
      sessionId: json['sessionId']?.toString() ?? '',
      label: json['label']?.toString() ?? 'Customer',
      orderItems:
          (json['orderItems'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), (value as num).toInt()),
          ) ??
          const {},
      specialRequests:
          (json['specialRequests'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          const {},
      orderNote: json['orderNote']?.toString(),
      supportNotes: json['supportNotes']?.toString(),
      orderDetails: json['orderDetails'] is Map
          ? PosOrderDetails.fromJson(
              Map<String, dynamic>.from(json['orderDetails'] as Map),
            )
          : null,
      paymentState: json['paymentState'] is Map
          ? SessionPaymentState.fromJson(
              Map<String, dynamic>.from(json['paymentState'] as Map),
            )
          : const SessionPaymentState.none(),
      status: _enumValue(
        SessionStatus.values,
        json['status']?.toString(),
        SessionStatus.building,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      lastUpdatedAt:
          DateTime.tryParse(json['lastUpdatedAt']?.toString() ?? '') ??
          DateTime.now(),
      minimizedScreen: json['minimizedScreen'] == null
          ? null
          : _enumValue(
              MinimizedScreen.values,
              json['minimizedScreen']?.toString(),
              MinimizedScreen.orderSummary,
            ),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'label': label,
      'orderItems': orderItems,
      'specialRequests': specialRequests,
      'orderNote': orderNote,
      'supportNotes': supportNotes,
      'orderDetails': orderDetails?.toJson(),
      'paymentState': paymentState.toJson(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'minimizedScreen': minimizedScreen?.name,
    };
  }

  OrderSession copyWith({
    String? label,
    Map<String, int>? orderItems,
    Map<String, String>? specialRequests,
    String? orderNote,
    bool clearOrderNote = false,
    String? supportNotes,
    bool clearSupportNotes = false,
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
      orderNote: clearOrderNote ? null : (orderNote ?? this.orderNote),
      supportNotes: clearSupportNotes
          ? null
          : (supportNotes ?? this.supportNotes),
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
      other is OrderSession &&
          other.sessionId == sessionId &&
          other.label == label &&
          _mapEquals(other.orderItems, orderItems) &&
          _mapEquals(other.specialRequests, specialRequests) &&
          other.orderNote == orderNote &&
          other.supportNotes == supportNotes &&
          other.orderDetails == orderDetails &&
          other.paymentState == paymentState &&
          other.status == status &&
          other.createdAt == createdAt &&
          other.lastUpdatedAt == lastUpdatedAt &&
          other.minimizedScreen == minimizedScreen;

  @override
  int get hashCode => Object.hash(
    sessionId,
    label,
    Object.hashAll(orderItems.entries),
    Object.hashAll(specialRequests.entries),
    orderNote,
    supportNotes,
    orderDetails,
    paymentState,
    status,
    createdAt,
    lastUpdatedAt,
    minimizedScreen,
  );
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

T _enumValue<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  return values.firstWhere(
    (value) => value.name == name,
    orElse: () => fallback,
  );
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

  factory SessionPaymentState.fromJson(Map<String, dynamic> json) {
    return SessionPaymentState(
      method: _enumValue(
        PaymentMethod.values,
        json['method']?.toString(),
        PaymentMethod.none,
      ),
      createdOrderId: json['createdOrderId']?.toString(),
      isProcessing: json['isProcessing'] == true,
      errorMessage: json['errorMessage']?.toString(),
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'method': method.name,
      'createdOrderId': createdOrderId,
      'isProcessing': isProcessing,
      'errorMessage': errorMessage,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionPaymentState &&
          other.method == method &&
          other.createdOrderId == createdOrderId &&
          other.onlinePaymentInitData == onlinePaymentInitData &&
          other.cashTransaction == cashTransaction &&
          other.isProcessing == isProcessing &&
          other.errorMessage == errorMessage;

  @override
  int get hashCode => Object.hash(
    method,
    createdOrderId,
    onlinePaymentInitData,
    cashTransaction,
    isProcessing,
    errorMessage,
  );
}
