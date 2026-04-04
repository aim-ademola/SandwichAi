// lib/src/features/chat/data/model/chat_models.dart

import 'package:flutter/material.dart';

class ChatRoomModel {
  final String id;
  final String name;
  final String? description;
  final String type; // GENERAL | DEPARTMENT | BRANCH
  final String organizationId;
  final String? branchId;
  final String? department;
  final bool isArchived;
  final DateTime? lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageBy;
  final int messageCount;
  final int memberCount;
  final int unreadCount;
  final bool isStarred;
  final bool isPinned;
  final bool isMuted;
  final bool isAdmin;

  const ChatRoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    required this.organizationId,
    this.branchId,
    this.department,
    required this.isArchived,
    this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageBy,
    required this.messageCount,
    required this.memberCount,
    required this.unreadCount,
    required this.isStarred,
    required this.isPinned,
    required this.isMuted,
    required this.isAdmin,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      type: json['type'] as String? ?? 'GENERAL',
      organizationId: json['organizationId'] as String? ?? '',
      branchId: json['branchId'] as String?,
      department: json['department'] as String?,
      isArchived: json['isArchived'] as bool? ?? false,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
      lastMessageText: json['lastMessageText'] as String?,
      lastMessageBy: json['lastMessageBy'] as String?,
      messageCount: json['messageCount'] as int? ?? 0,
      memberCount: json['memberCount'] as int? ?? 0,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isStarred: json['isStarred'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      isMuted: json['isMuted'] as bool? ?? false,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String messageId;
  final String chatRoomId;
  final String senderId;
  final String senderName;
  final String content;
  final String messageType; // TEXT | IMAGE | FILE | VOICE
  final String? parentMessageId;
  final List<String> mentions;
  final bool hasAttachments;
  final bool hasReactions;
  final bool isEdited;
  final DateTime? editedAt;
  final bool isDeleted;
  final DateTime sentAt;
  final int replyCount;
  final List<Map<String, dynamic>> attachments;
  final List<Map<String, dynamic>> reactions;

  const ChatMessageModel({
    required this.id,
    required this.messageId,
    required this.chatRoomId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.messageType,
    this.parentMessageId,
    required this.mentions,
    required this.hasAttachments,
    required this.hasReactions,
    required this.isEdited,
    this.editedAt,
    required this.isDeleted,
    required this.sentAt,
    required this.replyCount,
    required this.attachments,
    required this.reactions,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String? ?? '',
      messageId: json['messageId'] as String? ?? '',
      chatRoomId: json['chatRoomId'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? 'Unknown',
      content: json['content'] as String? ?? '',
      messageType: json['messageType'] as String? ?? 'TEXT',
      parentMessageId: json['parentMessageId'] as String?,
      mentions:
          (json['mentions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      hasReactions: json['hasReactions'] as bool? ?? false,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.tryParse(json['editedAt'] as String)
          : null,
      isDeleted: json['isDeleted'] as bool? ?? false,
      sentAt: json['sentAt'] != null
          ? DateTime.tryParse(json['sentAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      replyCount: json['replyCount'] as int? ?? 0,
      attachments:
          (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      reactions:
          (json['reactions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'messageId': messageId,
    'chatRoomId': chatRoomId,
    'senderId': senderId,
    'senderName': senderName,
    'content': content,
    'messageType': messageType,
    'parentMessageId': parentMessageId,
    'mentions': mentions,
    'hasAttachments': hasAttachments,
    'hasReactions': hasReactions,
    'isEdited': isEdited,
    'editedAt': editedAt?.toIso8601String(),
    'isDeleted': isDeleted,
    'sentAt': sentAt.toIso8601String(),
    'replyCount': replyCount,
    'attachments': attachments,
    'reactions': reactions,
  };
}

class UnreadCountModel {
  final String chatRoomId;
  final String chatRoomName;
  final int unreadCount;
  final DateTime? lastMessageAt;

  const UnreadCountModel({
    required this.chatRoomId,
    required this.chatRoomName,
    required this.unreadCount,
    this.lastMessageAt,
  });

  factory UnreadCountModel.fromJson(Map<String, dynamic> json) {
    return UnreadCountModel(
      chatRoomId: json['chatRoomId'] as String,
      chatRoomName: json['chatRoomName'] as String,
      unreadCount: json['unreadCount'] as int? ?? 0,
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.tryParse(json['lastMessageAt'] as String)
          : null,
    );
  }
}

//  Request models ─

class SendMessageRequest {
  final String chatRoomId;
  final String content;
  final String messageType; // TEXT | IMAGE | FILE | VOICE
  final String? parentMessageId;
  final List<String> mentions;
  final List<String> attachments;

  const SendMessageRequest({
    required this.chatRoomId,
    required this.content,
    this.messageType = 'TEXT',
    this.parentMessageId,
    this.mentions = const [],
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() => {
    'chatRoomId': chatRoomId,
    'content': content,
    'messageType': messageType,
    if (parentMessageId != null) 'parentMessageId': parentMessageId,
    'mentions': mentions,
    'attachments': attachments,
  };
}

class MarkReadRequest {
  final String chatRoomId;
  final String lastReadMessageId;

  const MarkReadRequest({
    required this.chatRoomId,
    required this.lastReadMessageId,
  });

  Map<String, dynamic> toJson() => {
    'chatRoomId': chatRoomId,
    'lastReadMessageId': lastReadMessageId,
  };
}

class UpdateRoomSettingsRequest {
  final String? notificationPreference; // ALL | MENTIONS | NONE
  final bool? isMuted;
  final bool? isStarred;
  final bool? isPinned;

  const UpdateRoomSettingsRequest({
    this.notificationPreference,
    this.isMuted,
    this.isStarred,
    this.isPinned,
  });

  Map<String, dynamic> toJson() => {
    if (notificationPreference != null)
      'notificationPreference': notificationPreference,
    if (isMuted != null) 'isMuted': isMuted,
    if (isStarred != null) 'isStarred': isStarred,
    if (isPinned != null) 'isPinned': isPinned,
  };
}

class UpdatePresenceRequest {
  final String status; // ONLINE | AWAY | BUSY | OFFLINE
  final String? customStatus;
  final String? statusEmoji;

  const UpdatePresenceRequest({
    required this.status,
    this.customStatus,
    this.statusEmoji,
  });

  Map<String, dynamic> toJson() => {
    'status': status,
    if (customStatus != null) 'customStatus': customStatus,
    if (statusEmoji != null) 'statusEmoji': statusEmoji,
  };
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
