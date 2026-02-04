// lib/src/features/chat/data/models/chat_models.dart

import 'package:flutter/material.dart';

enum MessageType { text, image, file, voice }

enum MessageStatus { sending, sent, delivered, read, failed }

enum ChatType {
  direct, // One-on-one chat
  group, // Group chat
  department, // Department-wide chat
  announcement, // Announcement channel
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final String? replyToMessageId;
  final ChatMessage? replyToMessage;
  final List<String>? attachmentUrls;
  final bool isEdited;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.replyToMessageId,
    this.replyToMessage,
    this.attachmentUrls,
    this.isEdited = false,
  });

  ChatMessage copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    MessageStatus? status,
    DateTime? timestamp,
    String? replyToMessageId,
    ChatMessage? replyToMessage,
    List<String>? attachmentUrls,
    bool? isEdited,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      replyToMessage: replyToMessage ?? this.replyToMessage,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isEdited: isEdited ?? this.isEdited,
    );
  }
}

class ChatConversation {
  final String id;
  final String name;
  final String? avatar;
  final ChatType type;
  final String? department;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final List<String> participantIds;
  final List<ChatParticipant> participants;
  final DateTime? lastActivity;
  final bool isPinned;
  final bool isMuted;

  ChatConversation({
    required this.id,
    required this.name,
    this.avatar,
    required this.type,
    this.department,
    this.lastMessage,
    this.unreadCount = 0,
    required this.participantIds,
    this.participants = const [],
    this.lastActivity,
    this.isPinned = false,
    this.isMuted = false,
  });

  ChatConversation copyWith({
    String? id,
    String? name,
    String? avatar,
    ChatType? type,
    String? department,
    ChatMessage? lastMessage,
    int? unreadCount,
    List<String>? participantIds,
    List<ChatParticipant>? participants,
    DateTime? lastActivity,
    bool? isPinned,
    bool? isMuted,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      type: type ?? this.type,
      department: department ?? this.department,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      participantIds: participantIds ?? this.participantIds,
      participants: participants ?? this.participants,
      lastActivity: lastActivity ?? this.lastActivity,
      isPinned: isPinned ?? this.isPinned,
      isMuted: isMuted ?? this.isMuted,
    );
  }
}

class ChatParticipant {
  final String id;
  final String name;
  final String? avatar;
  final String? role;
  final String? department;
  final bool isOnline;
  final DateTime? lastSeen;

  ChatParticipant({
    required this.id,
    required this.name,
    this.avatar,
    this.role,
    this.department,
    this.isOnline = false,
    this.lastSeen,
  });
}

enum Department {
  kitchen,
  frontOfHouse,
  management,
  delivery,
  inventory,
  all,
  pos,
}

extension DepartmentExtension on Department {
  String get displayName {
    switch (this) {
      case Department.kitchen:
        return 'Kitchen';
      case Department.pos:
        return 'pos';
      case Department.frontOfHouse:
        return 'Front of House';
      case Department.management:
        return 'Management';
      case Department.delivery:
        return 'Delivery';
      case Department.inventory:
        return 'Inventory';
      case Department.all:
        return 'All Departments';
    }
  }

  IconData get icon {
    switch (this) {
      case Department.kitchen:
        return Icons.restaurant;
      case Department.pos:
        return Icons.shopping_basket;
      case Department.frontOfHouse:
        return Icons.people;
      case Department.management:
        return Icons.business_center;
      case Department.delivery:
        return Icons.delivery_dining;
      case Department.inventory:
        return Icons.inventory_2;
      case Department.all:
        return Icons.groups;
    }
  }

  Color get color {
    switch (this) {
      case Department.kitchen:
        return const Color(0xFFFF6B6B);
      case Department.pos:
        return const Color(0xFF95E1D3);
      case Department.frontOfHouse:
        return const Color(0xFF4ECDC4);
      case Department.management:
        return const Color(0xFF95E1D3);
      case Department.delivery:
        return const Color(0xFFFFA07A);
      case Department.inventory:
        return const Color(0xFFDDA15E);
      case Department.all:
        return const Color(0xFF9B59B6);
    }
  }
}
