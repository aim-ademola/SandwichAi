// lib/src/core/globals/chat/chat_rooms_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sandwich_ai/src/core/globals/app_icon.dart';
import 'package:sandwich_ai/src/core/globals/drawer_toggle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/theme/app_theme_extension.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:sandwich_ai/src/core/globals/chat/chat.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/event.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/state.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';
import 'package:intl/intl.dart';
import 'package:sandwich_ai/src/core/local_sandbox/cache_manager.dart';

class ChatRoomsScreen extends StatefulWidget {
  final VoidCallback? showNavBarCallback;

  const ChatRoomsScreen({super.key, this.showNavBarCallback});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  // When non-null, we're "inside" a room
  ChatRoomModel? _openRoom;
  String _currentUserId = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatBloc>().add(const LoadChatRooms());
      context.read<ChatBloc>().add(const LoadUnreadCounts());
    });
    _startRealtimeRefresh();
    _loadCurrentUserId();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startRealtimeRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _openRoom != null) return;

      context.read<ChatBloc>().add(const LoadChatRooms(showLoading: false));
      context.read<ChatBloc>().add(const LoadUnreadCounts());
    });
  }

  // In _ChatRoomsScreenState
  Future<void> _loadCurrentUserId() async {
    final userData = await AuthCacheHelper.instance.getUserData();
    if (mounted) setState(() => _currentUserId = userData?.id ?? '');
  }

  void _openChatRoom(ChatRoomModel room) {
    setState(() => _openRoom = room);
  }

  void _backToRoomList() {
    setState(() => _openRoom = null);
    // Reload rooms to refresh unread counts
    context.read<ChatBloc>().add(const LoadChatRooms(showLoading: false));
    context.read<ChatBloc>().add(const LoadUnreadCounts());
  }

  @override
  Widget build(BuildContext context) {
    // If a room is selected, show DepartmentChatScreen inline
    if (_openRoom != null) {
      return DepartmentChatScreen(
        department: _departmentFromRoom(_openRoom!),
        roomId: _openRoom!.id,
        customTitle: _openRoom!.name,
        showNavBarCallback: _backToRoomList,
        currentUserId: _currentUserId,
      );
    }

    return Scaffold(
      backgroundColor: context.modeBackground,
      appBar: AppBar(
        backgroundColor: context.modeSurface,
        elevation: 1,
        surfaceTintColor: Colors.transparent,

        centerTitle: true,
        leading: const DrawerToggleButton(),
        title: Text(
          'Chat Rooms',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.modeTextPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: AppIcon(Icons.refresh, color: context.modeTextPrimary),
            onPressed: () =>
                context.read<ChatBloc>().add(const LoadChatRooms()),
          ),
        ],
      ),
      body: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatRoomsLoading) {
            return Center(
              child: CircularProgressIndicator(color: context.modePrimary),
            );
          }

          if (state is ChatRoomsError) {
            return _buildError(state.error);
          }

          if (state is ChatRoomsLoaded) {
            if (state.rooms.isEmpty) return _buildEmpty();
            return _buildRoomList(state.rooms);
          }

          return Center(
            child: CircularProgressIndicator(color: context.modePrimary),
          );
        },
      ),
    );
  }

  Widget _buildRoomList(List<ChatRoomModel> rooms) {
    // Sort: pinned first, then starred, then by last activity
    final sorted = [...rooms]
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        if (a.isStarred && !b.isStarred) return -1;
        if (!a.isStarred && b.isStarred) return 1;
        final aTime = a.lastMessageAt ?? DateTime(0);
        final bTime = b.lastMessageAt ?? DateTime(0);
        return bTime.compareTo(aTime);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => Divider(
        height: 0,
        indent: 72,
        endIndent: 16,
        color: context.modeDivider,
      ),
      itemBuilder: (context, index) => _buildRoomTile(sorted[index]),
    );
  }

  Widget _buildRoomTile(ChatRoomModel room) {
    final dept = _departmentFromRoom(room);
    final hasUnread = room.unreadCount > 0;

    return InkWell(
      onTap: () => _openChatRoom(room),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.modePrimary.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: AppIcon(
                      dept.icon,
                      color: context.modePrimary,
                      size: 22,
                    ),
                  ),
                ),
                if (room.isPinned)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: context.modePrimary,
                        shape: BoxShape.circle,
                      ),
                      child: AppIcon(
                        Icons.push_pin,
                        size: 10,
                        color: context.modeTextInverse,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.name,
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 15,
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: context.modeTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (room.lastMessageAt != null)
                        Text(
                          _formatTime(room.lastMessageAt!),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 11,
                            color: hasUnread
                                ? context.modePrimary
                                : context.modeTextSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room.lastMessageText ?? _roomSubtitle(room),
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 13,
                            color: hasUnread
                                ? context.modeTextPrimary
                                : context.modeTextSecondary,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (room.isStarred)
                            AppIcon(
                              Icons.star,
                              size: 14,
                              color: context.modeWarning,
                            ),
                          if (room.isMuted)
                            AppIcon(
                              Icons.notifications_off,
                              size: 14,
                              color: context.modeTextSecondary,
                            ),
                          if (hasUnread) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: context.modePrimary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${room.unreadCount}',
                                style: TextStyle(
                                  color: context.modeTextInverse,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Room type badge
                  _buildTypeBadge(room),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(ChatRoomModel room) {
    String label;
    Color color;

    switch (room.type) {
      case 'BRANCH':
        label = 'Branch Chat';
        color = context.modePrimary;
        break;
      case 'GENERAL':
        label = 'General Org Chat';
        color = context.modePrimary;
        break;
      case 'DEPARTMENT':
        label = '${room.department ?? 'Departmental'} Departmental Chat';
        color = context.modePrimary;
        break;
      default:
        label = room.type;
        color = context.modeTextSecondary;
    }

    return Text(
      label,
      style: WorkSansAppTextStyles.medium.copyWith(
        fontSize: 11,
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon(
            Icons.chat_bubble_outline,
            size: 64,
            color: context.modeTextMuted.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 16),
          Text(
            'No chats yet',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.modeTextPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your chat rooms will appear here',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: context.modeTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              Icons.error_outline_outlined,
              size: 56,
              color: context.modeError,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: context.modeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.modePrimary,
                foregroundColor: context.modeTextInverse,
              ),
              onPressed: () =>
                  context.read<ChatBloc>().add(const LoadChatRooms()),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  //  Helpers

  /// Map a room back to the closest Department enum for icon/color
  Department _departmentFromRoom(ChatRoomModel room) {
    if (room.type == 'BRANCH') return Department.all;
    if (room.type == 'GENERAL') return Department.management;

    switch (room.department?.toUpperCase()) {
      case 'KITCHEN':
        return Department.kitchen;
      case 'CUSTOMER_SERVICE':
        return Department.pos;
      case 'INVENTORY':
      case 'STOCK_CONTROL':
      case 'STOCK':
      case 'PROCUREMENT':
        return Department.inventory;
      case 'DELIVERY':
        return Department.delivery;
      case 'PROCESSING':
        return Department.frontOfHouse;
      default:
        return Department.all;
    }
  }

  String _roomSubtitle(ChatRoomModel room) {
    return '${room.memberCount} member${room.memberCount == 1 ? '' : 's'}';
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat('h:mm a').format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat('EEE').format(dt);
    return DateFormat('MMM d').format(dt);
  }
}
