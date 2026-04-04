import 'package:equatable/equatable.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

//  Room list states

class ChatRoomsLoading extends ChatState {
  const ChatRoomsLoading();
}

class ChatRoomsLoaded extends ChatState {
  final List<ChatRoomModel> rooms;
  final List<UnreadCountModel> unreadCounts;

  const ChatRoomsLoaded({required this.rooms, this.unreadCounts = const []});

  ChatRoomsLoaded copyWith({
    List<ChatRoomModel>? rooms,
    List<UnreadCountModel>? unreadCounts,
  }) {
    return ChatRoomsLoaded(
      rooms: rooms ?? this.rooms,
      unreadCounts: unreadCounts ?? this.unreadCounts,
    );
  }

  @override
  List<Object?> get props => [rooms, unreadCounts];
}

class ChatRoomsError extends ChatState {
  final String error;
  const ChatRoomsError({required this.error});

  @override
  List<Object?> get props => [error];
}

//  Messages states ─

class ChatMessagesLoading extends ChatState {
  final String chatRoomId;
  const ChatMessagesLoading({required this.chatRoomId});

  @override
  List<Object?> get props => [chatRoomId];
}

class ChatMessagesLoaded extends ChatState {
  final String chatRoomId;
  final ChatRoomModel? room;
  final List<ChatMessageModel> messages;
  final bool hasMore;
  final String? oldestCursor; // oldest message id for pagination
  final bool isLoadingMore;
  final ChatMessageModel? sendingMessage; // optimistic local message
  final String? sendError;

  const ChatMessagesLoaded({
    required this.chatRoomId,
    this.room,
    required this.messages,
    this.hasMore = true,
    this.oldestCursor,
    this.isLoadingMore = false,
    this.sendingMessage,
    this.sendError,
  });

  ChatMessagesLoaded copyWith({
    String? chatRoomId,
    ChatRoomModel? room,
    List<ChatMessageModel>? messages,
    bool? hasMore,
    String? oldestCursor,
    bool? isLoadingMore,
    ChatMessageModel? sendingMessage,
    bool clearSendingMessage = false,
    String? sendError,
    bool clearSendError = false,
  }) {
    return ChatMessagesLoaded(
      chatRoomId: chatRoomId ?? this.chatRoomId,
      room: room ?? this.room,
      messages: messages ?? this.messages,
      hasMore: hasMore ?? this.hasMore,
      oldestCursor: oldestCursor ?? this.oldestCursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      sendError: clearSendError ? null : (sendError ?? this.sendError),

      sendingMessage: clearSendingMessage
          ? null
          : (sendingMessage ?? this.sendingMessage),
    );
  }

  @override
  List<Object?> get props => [
    chatRoomId,
    room,
    messages,
    hasMore,
    oldestCursor,
    isLoadingMore,
    sendingMessage,
  ];
}

class ChatMessagesError extends ChatState {
  final String chatRoomId;
  final String error;

  const ChatMessagesError({required this.chatRoomId, required this.error});

  @override
  List<Object?> get props => [chatRoomId, error];
}

//  Search states

class ChatSearchLoading extends ChatState {
  const ChatSearchLoading();
}

class ChatSearchResults extends ChatState {
  final List<ChatMessageModel> results;
  final String query;

  const ChatSearchResults({required this.results, required this.query});

  @override
  List<Object?> get props => [results, query];
}

class ChatSearchEmpty extends ChatState {
  const ChatSearchEmpty();
}

class ChatSearchError extends ChatState {
  final String error;
  const ChatSearchError({required this.error});

  @override
  List<Object?> get props => [error];
}

//  Settings / Presence

class ChatSettingsUpdating extends ChatState {
  const ChatSettingsUpdating();
}

class ChatSettingsUpdated extends ChatState {
  const ChatSettingsUpdated();
}

class ChatSettingsError extends ChatState {
  final String error;
  const ChatSettingsError({required this.error});

  @override
  List<Object?> get props => [error];
}

//  Message send states

class MessageSendError extends ChatState {
  final String error;
  final String chatRoomId;

  const MessageSendError({required this.error, required this.chatRoomId});

  @override
  List<Object?> get props => [error, chatRoomId];
}
