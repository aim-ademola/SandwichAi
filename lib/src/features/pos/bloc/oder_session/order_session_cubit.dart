import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';
import 'package:sandwich_ai/src/features/pos/presentation/pos_order_dtls_dialoge.dart';
import 'package:uuid/uuid.dart';

import 'order_session_state.dart';

class OrderSessionCubit extends Cubit<OrderSessionState> {
  static const int _maxSessions = 10;
  final _uuid = const Uuid();

  OrderSessionCubit() : super(const OrderSessionState());

  // ─── Session lifecycle ────────────────────────────────────────────────────

  String createSession({String? label}) {
    if (state.sessions.length >= _maxSessions) {
      throw StateError('Maximum of $_maxSessions concurrent sessions reached.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();
    final session = OrderSession(
      sessionId: id,
      label: label ?? _generateLabel(),
      createdAt: now,
      lastUpdatedAt: now,
    );

    emit(
      state.copyWith(
        sessions: [...state.sessions, session],
        activeSessionId: id,
      ),
    );

    return id;
  }

  void switchToSession(String sessionId) {
    assert(state.sessions.any((s) => s.sessionId == sessionId));
    emit(state.copyWith(activeSessionId: sessionId));
  }

  void closeSession(String sessionId) {
    final remaining = state.sessions
        .where((s) => s.sessionId != sessionId)
        .toList();

    String? nextActiveId = state.activeSessionId;
    if (state.activeSessionId == sessionId) {
      if (remaining.isNotEmpty) {
        remaining.sort((a, b) => b.lastUpdatedAt.compareTo(a.lastUpdatedAt));
        nextActiveId = remaining.first.sessionId;
      } else {
        nextActiveId = null;
      }
    }

    emit(state.copyWith(sessions: remaining, activeSessionId: nextActiveId));
  }

  void discardSession(String sessionId) {
    closeSession(sessionId);
    if (state.sessions.isEmpty) {
      createSession();
    }
  }

  void renameSession(String sessionId, String newLabel) {
    _updateSession(sessionId, (s) => s.copyWith(label: newLabel));
  }

  // ─── Minimize / resume ────────────────────────────────────────────────────

  /// Called when the cashier taps the minimize button on any mid-flow screen.
  /// Records which screen they minimized from so we can navigate back to it.
  void minimizeSession({
    required String sessionId,
    required MinimizedScreen screen,
  }) {
    _updateSession(sessionId, (s) => s.copyWith(minimizedScreen: screen));
  }

  /// Called by OrderScreen after it navigates the user back to the minimized
  /// screen. Clears the minimizedScreen so it doesn't trigger again.
  void clearMinimizedScreen(String sessionId) {
    _updateSession(sessionId, (s) => s.copyWith(clearMinimizedScreen: true));
  }

  // ─── State snapshot updates ───────────────────────────────────────────────

  void updateActiveSessionItems({
    required Map<String, int> orderItems,
    required Map<String, String> specialRequests,
    String? orderNote,
    bool clearOrderNote = false,
  }) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        orderItems: Map.from(orderItems),
        specialRequests: Map.from(specialRequests),
        orderNote: clearOrderNote ? null : (orderNote ?? s.orderNote),
        status: orderItems.isEmpty && s.status == SessionStatus.building
            ? SessionStatus.building
            : s.status,
      ),
    );
  }

  void updateActiveSessionNote(String? note) {
    final id = state.activeSessionId;
    if (id == null) return;

    final trimmed = note?.trim();
    _updateSession(
      id,
      (s) => s.copyWith(
        orderNote: trimmed == null || trimmed.isEmpty ? null : trimmed,
        clearOrderNote: trimmed == null || trimmed.isEmpty,
      ),
    );
  }

  void parkActiveSession() {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(id, (s) => s.copyWith(status: SessionStatus.parked));
    if (state.sessions.length < _maxSessions) {
      createSession();
    } else {
      emit(state.copyWith(activeSessionId: null));
    }
  }

  void confirmActiveSessionDetails(PosOrderDetails details) {
    final id = state.activeSessionId;
    if (id == null) return;

    String? newLabel;
    if (details.orderType == 'DINE_IN' && details.tableNumber != null) {
      newLabel = 'Table ${details.tableNumber}';
    } else if (details.customerName != null) {
      newLabel = details.customerName;
    }

    _updateSession(
      id,
      (s) => s.copyWith(
        orderDetails: details,
        label: newLabel ?? s.label,
        status: SessionStatus.detailsConfirmed,
      ),
    );
  }

  void markPaymentStarted({required PaymentMethod method}) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        paymentState: SessionPaymentState(method: method, isProcessing: true),
        status: SessionStatus.paymentInProgress,
      ),
    );
  }

  void markOrderCreated(String orderId) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        paymentState: s.paymentState.copyWith(
          createdOrderId: orderId,
          isProcessing: false,
        ),
      ),
    );
  }

  void markCashPendingApproval({required dynamic transaction}) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        paymentState: s.paymentState.copyWith(
          cashTransaction: transaction,
          isProcessing: false,
        ),
      ),
    );
  }

  void markOnlinePaymentInitialized({required dynamic initData}) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        paymentState: s.paymentState.copyWith(
          onlinePaymentInitData: initData,
          isProcessing: false,
        ),
      ),
    );
  }

  void markSessionCompleted(String sessionId) {
    _updateSession(
      sessionId,
      (s) => s.copyWith(
        status: SessionStatus.completed,
        paymentState: s.paymentState.copyWith(isProcessing: false),
        clearMinimizedScreen: true,
      ),
    );
  }

  void markPaymentError(String errorMessage) {
    final id = state.activeSessionId;
    if (id == null) return;

    _updateSession(
      id,
      (s) => s.copyWith(
        paymentState: s.paymentState.copyWith(
          isProcessing: false,
          errorMessage: errorMessage,
        ),
        status: SessionStatus.detailsConfirmed,
      ),
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _updateSession(
    String sessionId,
    OrderSession Function(OrderSession) updater,
  ) {
    final updated = state.sessions.map((s) {
      if (s.sessionId == sessionId) return updater(s);
      return s;
    }).toList();

    emit(state.copyWith(sessions: updated));
  }

  String _generateLabel() {
    final count = state.sessions.length + 1;
    return 'Customer $count';
  }
}
