import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/event.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/state.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/repo/chat_repo.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepositoryInterface _repository;

  ChatBloc({required ChatRepositoryInterface repository})
    : _repository = repository,
      super(const ChatInitial()) {
    on<LoadChatRooms>(_onLoadChatRooms);
    on<LoadChatRoom>(_onLoadChatRoom);
    on<UpdateRoomSettings>(_onUpdateRoomSettings);
    on<LoadMessages>(_onLoadMessages);
    on<LoadMoreMessages>(_onLoadMoreMessages);
    on<SendMessage>(_onSendMessage);
    on<SearchMessages>(_onSearchMessages);
    on<ClearSearch>(_onClearSearch);
    on<LoadUnreadCounts>(_onLoadUnreadCounts);
    on<MarkRoomAsRead>(_onMarkRoomAsRead);
    on<UpdatePresence>(_onUpdatePresence);
    on<AppendOptimisticMessage>(_onAppendOptimisticMessage);
    on<ReplaceOptimisticMessage>(_onReplaceOptimisticMessage);
    on<SelectRoom>(_onSelectRoom);
    on<ResetChatState>(_onResetChatState);
  }

  //  Rooms ──

  void _logChat(Object? message) {
    // Chat is intentionally quiet in debug logs because room/message payloads
    // are noisy and can contain user content.
  }

  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    try {
      if (event.showLoading || state is! ChatRoomsLoaded) {
        emit(const ChatRoomsLoading());
      }

      final response = await _repository.getChatRooms(
        type: event.type,
        branchId: event.branchId,
        includeArchived: event.includeArchived,
        starredOnly: event.starredOnly,
      );

      await response.when(
        success: (rooms) async {
          _logChat('Loaded ${rooms.length} chat rooms');
          final current = state;
          final unreadCounts = current is ChatRoomsLoaded
              ? current.unreadCounts
              : const <UnreadCountModel>[];

          emit(
            ChatRoomsLoaded(
              rooms: _roomsWithUnreadCounts(rooms, unreadCounts),
              unreadCounts: unreadCounts,
            ),
          );
        },
        error: (error) async {
          emit(ChatRoomsError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(ChatRoomsError(error: 'Unexpected error: ${e.toString()}'));
    }
  }

  Future<void> _onLoadChatRoom(
    LoadChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.getChatRoom(roomId: event.roomId);

      await response.when(
        success: (room) async {
          // If we already have messages loaded for this room, attach the room
          final current = state;
          if (current is ChatMessagesLoaded &&
              current.chatRoomId == event.roomId) {
            emit(current.copyWith(room: room.copyWith(unreadCount: 0)));
          }
        },
        error: (error) async {
          _logChat('Load room error: $error');
        },
      );
    } catch (e) {
      _logChat('Load room exception: $e');
    }
  }

  Future<void> _onUpdateRoomSettings(
    UpdateRoomSettings event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatSettingsUpdating());

      final response = await _repository.updateRoomSettings(
        roomId: event.roomId,
        request: event.request,
      );

      await response.when(
        success: (_) async {
          emit(const ChatSettingsUpdated());
        },
        error: (error) async {
          emit(ChatSettingsError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(ChatSettingsError(error: 'Unexpected error: ${e.toString()}'));
    }
  }

  //  Messages ──

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatMessagesLoading(chatRoomId: event.chatRoomId));

      final response = await _repository.getMessages(
        chatRoomId: event.chatRoomId,
        limit: event.limit,
        cursor: event.cursor,
        parentMessageId: event.parentMessageId,
      );

      await response.when(
        success: (messages) async {
          _logChat(
            'Loaded ${messages.length} messages for ${event.chatRoomId}',
          );

          // Oldest message id used as cursor for loading older messages
          final oldestCursor = messages.isNotEmpty ? messages.first.id : null;

          emit(
            ChatMessagesLoaded(
              chatRoomId: event.chatRoomId,
              messages: messages,
              hasMore: messages.length >= event.limit,
              oldestCursor: oldestCursor,
            ),
          );

          // Also kick off a room detail fetch
          add(LoadChatRoom(roomId: event.chatRoomId));
        },
        error: (error) async {
          emit(
            ChatMessagesError(
              chatRoomId: event.chatRoomId,
              error: error.toString(),
            ),
          );
        },
      );
    } catch (e) {
      emit(
        ChatMessagesError(
          chatRoomId: event.chatRoomId,
          error: 'Unexpected error: ${e.toString()}',
        ),
      );
    }
  }

  Future<void> _onLoadMoreMessages(
    LoadMoreMessages event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatMessagesLoaded || current.isLoadingMore) return;

    try {
      emit(current.copyWith(isLoadingMore: true));

      final response = await _repository.getMessages(
        chatRoomId: event.chatRoomId,
        cursor: event.cursor,
        limit: 50,
      );

      await response.when(
        success: (olderMessages) async {
          final updated = [...olderMessages, ...current.messages];
          emit(
            current.copyWith(
              messages: updated,
              hasMore: olderMessages.length >= 50,
              oldestCursor: olderMessages.isNotEmpty
                  ? olderMessages.first.id
                  : null,
              isLoadingMore: false,
            ),
          );
        },
        error: (error) async {
          _logChat('Load more messages error (ignored): $error');
          emit(current.copyWith(isLoadingMore: false));
        },
      );
    } catch (e) {
      _logChat('Load more messages exception: $e');
      if (state is ChatMessagesLoaded) {
        emit((state as ChatMessagesLoaded).copyWith(isLoadingMore: false));
      }
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    final current = state;
    if (current is! ChatMessagesLoaded) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final optimistic = ChatMessageModel(
      id: tempId,
      messageId: tempId,
      chatRoomId: event.request.chatRoomId,
      senderId: 'me',
      senderName: 'You',
      content: event.request.content,
      messageType: event.request.messageType,
      parentMessageId: event.request.parentMessageId,
      mentions: event.request.mentions,
      hasAttachments: event.request.attachments.isNotEmpty,
      hasReactions: false,
      isEdited: false,
      isDeleted: false,
      sentAt: DateTime.now(),
      replyCount: 0,
      attachments: const [],
      reactions: const [],
    );

    emit(current.copyWith(messages: [...current.messages, optimistic]));

    try {
      final response = await _repository.sendMessage(request: event.request);

      await response.when(
        success: (serverMsg) async {
          _logChat('Message sent: ${serverMsg.messageId}');
          final updated = state;
          if (updated is ChatMessagesLoaded) {
            final newList = updated.messages
                .map((m) => m.id == tempId ? serverMsg : m)
                .toList();
            emit(updated.copyWith(messages: newList));
          }
        },
        error: (error) async {
          _logChat('Send message error: $error');
          final updated = state;
          if (updated is ChatMessagesLoaded) {
            // Remove optimistic message but STAY in ChatMessagesLoaded
            final newList = updated.messages
                .where((m) => m.id != tempId)
                .toList();
            // ✅ Emit error flag inside ChatMessagesLoaded, not a separate state
            emit(
              updated.copyWith(
                messages: newList,
                sendError: error
                    .toString(), // ADD this field to ChatMessagesLoaded
              ),
            );
          }
        },
      );
    } catch (e) {
      final updated = state;
      if (updated is ChatMessagesLoaded) {
        final newList = updated.messages.where((m) => m.id != tempId).toList();
        emit(
          updated.copyWith(
            messages: newList,
            sendError: 'Unexpected error: ${e.toString()}',
          ),
        );
      }
    }
  }
  //  Search ─

  Future<void> _onSearchMessages(
    SearchMessages event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatSearchLoading());

      final response = await _repository.searchMessages(
        query: event.query,
        chatRoomId: event.chatRoomId,
        senderId: event.senderId,
        limit: event.limit,
      );

      await response.when(
        success: (results) async {
          if (results.isEmpty) {
            emit(const ChatSearchEmpty());
          } else {
            emit(ChatSearchResults(results: results, query: event.query));
          }
        },
        error: (error) async {
          emit(ChatSearchError(error: error.toString()));
        },
      );
    } catch (e) {
      emit(ChatSearchError(error: 'Unexpected error: ${e.toString()}'));
    }
  }

  void _onClearSearch(ClearSearch event, Emitter<ChatState> emit) {
    // DON'T emit ChatInitial — it wipes the messages
    // Only reset if we're in a search state, not if we're in ChatMessagesLoaded
    final current = state;
    if (current is ChatSearchResults ||
        current is ChatSearchLoading ||
        current is ChatSearchEmpty ||
        current is ChatSearchError) {
      // Nothing to do — the search states are overlaid in the UI
      // The messages list is still in the previous ChatMessagesLoaded state
      // Just let the UI hide the search overlay via _isSearching flag
    }
    // Don't emit anything — search overlay is controlled by _isSearching in the widget
  }

  //  Unread / Read

  Future<void> _onLoadUnreadCounts(
    LoadUnreadCounts event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await _repository.getUnreadCounts();

      await response.when(
        success: (counts) async {
          final current = state;
          if (current is ChatRoomsLoaded) {
            emit(
              current.copyWith(
                rooms: _roomsWithUnreadCounts(current.rooms, counts),
                unreadCounts: counts,
              ),
            );
          }
        },
        error: (error) async {
          _logChat('Load unread counts error (ignored): $error');
        },
      );
    } catch (e) {
      _logChat('Load unread counts exception: $e');
    }
  }

  Future<void> _onMarkRoomAsRead(
    MarkRoomAsRead event,
    Emitter<ChatState> emit,
  ) async {
    try {
      _clearUnreadCountForRoom(event.request.chatRoomId, emit);

      _logChat(
        'Marking room as read: room=${event.request.chatRoomId}, lastReadMessage=${event.request.lastReadMessageId}',
      );
      final response = await _repository.markAsRead(request: event.request);

      if (!response.isSuccess) {
        _logChat(
          'Mark as read error (ignored): ${response.error ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      _logChat('Mark as read exception (ignored): $e');
    }
  }

  void _clearUnreadCountForRoom(String roomId, Emitter<ChatState> emit) {
    final current = state;
    if (current is ChatRoomsLoaded) {
      emit(
        current.copyWith(
          rooms: current.rooms.map((room) {
            if (room.id != roomId) return room;
            return room.copyWith(unreadCount: 0);
          }).toList(),
          unreadCounts: current.unreadCounts
              .where((count) => count.chatRoomId != roomId)
              .toList(),
        ),
      );
    } else if (current is ChatMessagesLoaded && current.chatRoomId == roomId) {
      emit(current.copyWith(room: current.room?.copyWith(unreadCount: 0)));
    }
  }

  List<ChatRoomModel> _roomsWithUnreadCounts(
    List<ChatRoomModel> rooms,
    List<UnreadCountModel> unreadCounts,
  ) {
    final unreadByRoom = {
      for (final count in unreadCounts) count.chatRoomId: count.unreadCount,
    };

    return rooms
        .map((room) => room.copyWith(unreadCount: unreadByRoom[room.id] ?? 0))
        .toList();
  }

  //  Presence ──

  Future<void> _onUpdatePresence(
    UpdatePresence event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _repository.updatePresence(request: event.request);
      _logChat('Presence updated: ${event.request.status}');
    } catch (e) {
      _logChat('Update presence exception (ignored): $e');
    }
  }

  //  Optimistic message helpers ──

  void _onAppendOptimisticMessage(
    AppendOptimisticMessage event,
    Emitter<ChatState> emit,
  ) {
    final current = state;
    if (current is ChatMessagesLoaded) {
      emit(current.copyWith(messages: [...current.messages, event.message]));
    }
  }

  void _onReplaceOptimisticMessage(
    ReplaceOptimisticMessage event,
    Emitter<ChatState> emit,
  ) {
    final current = state;
    if (current is ChatMessagesLoaded) {
      List<ChatMessageModel> updated;
      if (event.serverMessage != null) {
        updated = current.messages
            .map((m) => m.id == event.tempId ? event.serverMessage! : m)
            .toList();
      } else {
        updated = current.messages.where((m) => m.id != event.tempId).toList();
      }
      emit(current.copyWith(messages: updated));
    }
  }

  //  Room selection ──

  Future<void> _onSelectRoom(SelectRoom event, Emitter<ChatState> emit) async {
    add(LoadMessages(chatRoomId: event.roomId));
  }

  void _onResetChatState(ResetChatState event, Emitter<ChatState> emit) {
    emit(const ChatInitial());
  }
}
