// lib/src/features/chat/bloc/chat_bloc/event.dart

import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

//  Rooms ─

class LoadChatRooms extends ChatEvent {
  final String? type;
  final String? branchId;
  final bool includeArchived;
  final bool starredOnly;
  final bool showLoading;

  const LoadChatRooms({
    this.type,
    this.branchId,
    this.includeArchived = false,
    this.starredOnly = false,
    this.showLoading = true,
  });

  @override
  List<Object?> get props => [
    type,
    branchId,
    includeArchived,
    starredOnly,
    showLoading,
  ];
}

class LoadChatRoom extends ChatEvent {
  final String roomId;
  const LoadChatRoom({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class UpdateRoomSettings extends ChatEvent {
  final String roomId;
  final UpdateRoomSettingsRequest request;

  const UpdateRoomSettings({required this.roomId, required this.request});

  @override
  List<Object?> get props => [roomId, request];
}

//  Messages ──

class LoadMessages extends ChatEvent {
  final String chatRoomId;
  final int limit;
  final String? cursor;
  final String? parentMessageId;

  const LoadMessages({
    required this.chatRoomId,
    this.limit = 50,
    this.cursor,
    this.parentMessageId,
  });

  @override
  List<Object?> get props => [chatRoomId, limit, cursor, parentMessageId];
}

class LoadMoreMessages extends ChatEvent {
  final String chatRoomId;
  final String cursor;

  const LoadMoreMessages({required this.chatRoomId, required this.cursor});

  @override
  List<Object?> get props => [chatRoomId, cursor];
}

class SendMessage extends ChatEvent {
  final SendMessageRequest request;
  const SendMessage({required this.request});

  @override
  List<Object?> get props => [request];
}

class SearchMessages extends ChatEvent {
  final String query;
  final String? chatRoomId;
  final String? senderId;
  final int limit;

  const SearchMessages({
    required this.query,
    this.chatRoomId,
    this.senderId,
    this.limit = 20,
  });

  @override
  List<Object?> get props => [query, chatRoomId, senderId, limit];
}

class ClearSearch extends ChatEvent {
  const ClearSearch();
}

//  Unread / Read

class LoadUnreadCounts extends ChatEvent {
  const LoadUnreadCounts();
}

class MarkRoomAsRead extends ChatEvent {
  final MarkReadRequest request;
  const MarkRoomAsRead({required this.request});

  @override
  List<Object?> get props => [request];
}

//  Presence ──

class UpdatePresence extends ChatEvent {
  final UpdatePresenceRequest request;
  const UpdatePresence({required this.request});

  @override
  List<Object?> get props => [request];
}

//  Optimistic UI helpers ─

/// Emitted locally when the user taps send, before the API returns.
class AppendOptimisticMessage extends ChatEvent {
  final ChatMessageModel message;
  const AppendOptimisticMessage({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Replace or remove the optimistic message once the server responds.
class ReplaceOptimisticMessage extends ChatEvent {
  final String tempId;
  final ChatMessageModel? serverMessage; // null → failed, remove it
  const ReplaceOptimisticMessage({required this.tempId, this.serverMessage});

  @override
  List<Object?> get props => [tempId, serverMessage];
}

//  Room selection ──

class SelectRoom extends ChatEvent {
  final String roomId;
  const SelectRoom({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class ResetChatState extends ChatEvent {
  const ResetChatState();
}
