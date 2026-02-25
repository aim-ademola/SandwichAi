import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/pos/data/model/order_session_model.dart';

class OrderSessionState extends Equatable {
  /// All active sessions, ordered by creation time.
  final List<OrderSession> sessions;

  /// The session currently being worked on in OrderScreen.
  final String? activeSessionId;

  const OrderSessionState({this.sessions = const [], this.activeSessionId});

  OrderSession? get activeSession {
    if (activeSessionId == null) return null;
    return sessions.where((s) => s.sessionId == activeSessionId).firstOrNull;
  }

  /// Sessions that are not the active one — shown in the switcher.
  List<OrderSession> get inactiveSessions =>
      sessions.where((s) => s.sessionId != activeSessionId).toList();

  bool get hasActiveSession => activeSessionId != null;

  bool get canAddSession => sessions.length < 10;

  OrderSessionState copyWith({
    List<OrderSession>? sessions,
    String? activeSessionId,
    bool clearActiveSession = false,
  }) {
    return OrderSessionState(
      sessions: sessions ?? this.sessions,
      activeSessionId: clearActiveSession
          ? null
          : (activeSessionId ?? this.activeSessionId),
    );
  }

  @override
  List<Object?> get props => [sessions, activeSessionId];
}
