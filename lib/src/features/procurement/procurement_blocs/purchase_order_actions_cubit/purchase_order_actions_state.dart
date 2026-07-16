import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/features/procurement/data/model/purchase_order_action_model.dart';

enum PurchaseOrderActionStatus { initial, loading, loaded, empty, error }

class PurchaseOrderActionsState extends Equatable {
  final PurchaseOrderActionStatus approvalStatusState;
  final PurchaseOrderActionStatus timelineStatus;
  final PurchaseOrderActionStatus actionStatus;
  final PurchaseOrderApprovalStatus? approvalStatus;
  final PurchaseOrderTimelineResponse? timeline;
  final String? approvalError;
  final String? timelineError;
  final String? actionError;
  final String? actionMessage;

  const PurchaseOrderActionsState({
    this.approvalStatusState = PurchaseOrderActionStatus.initial,
    this.timelineStatus = PurchaseOrderActionStatus.initial,
    this.actionStatus = PurchaseOrderActionStatus.initial,
    this.approvalStatus,
    this.timeline,
    this.approvalError,
    this.timelineError,
    this.actionError,
    this.actionMessage,
  });

  PurchaseOrderActionsState copyWith({
    PurchaseOrderActionStatus? approvalStatusState,
    PurchaseOrderActionStatus? timelineStatus,
    PurchaseOrderActionStatus? actionStatus,
    PurchaseOrderApprovalStatus? approvalStatus,
    PurchaseOrderTimelineResponse? timeline,
    String? approvalError,
    String? timelineError,
    String? actionError,
    String? actionMessage,
    bool clearApprovalError = false,
    bool clearTimelineError = false,
    bool clearAction = false,
  }) {
    return PurchaseOrderActionsState(
      approvalStatusState: approvalStatusState ?? this.approvalStatusState,
      timelineStatus: timelineStatus ?? this.timelineStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      timeline: timeline ?? this.timeline,
      approvalError: clearApprovalError
          ? null
          : (approvalError ?? this.approvalError),
      timelineError: clearTimelineError
          ? null
          : (timelineError ?? this.timelineError),
      actionError: clearAction ? null : (actionError ?? this.actionError),
      actionMessage: clearAction ? null : (actionMessage ?? this.actionMessage),
    );
  }

  @override
  List<Object?> get props => [
    approvalStatusState,
    timelineStatus,
    actionStatus,
    approvalStatus,
    timeline,
    approvalError,
    timelineError,
    actionError,
    actionMessage,
  ];
}
