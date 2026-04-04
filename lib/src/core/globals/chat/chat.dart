// lib/src/features/chat/presentation/department_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sandwich_ai/src/core/config/prod_print.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/bloc.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/event.dart';
import 'package:sandwich_ai/src/core/globals/chat/chatroom_bloc/state.dart';
import 'package:sandwich_ai/src/core/globals/chat/data/model/cht_model.dart';

class DepartmentChatScreen extends StatefulWidget {
  final Department department;
  final String roomId; // real chat room id from API
  final String? customTitle;
  final VoidCallback? showNavBarCallback;
  final String currentUserId;

  const DepartmentChatScreen({
    super.key,
    required this.department,
    required this.roomId,
    this.customTitle,
    this.showNavBarCallback,
    required this.currentUserId,
  });

  @override
  State<DepartmentChatScreen> createState() => _DepartmentChatScreenState();
}

class _DepartmentChatScreenState extends State<DepartmentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();

  ChatMessageModel? _replyToMessage;
  bool _isTyping = false;
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartTime;

  // Search overlay
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _checkMicrophonePermission();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  void _loadInitialData() {
    context.read<ChatBloc>().add(LoadMessages(chatRoomId: widget.roomId));

    // Mark presence as online
    context.read<ChatBloc>().add(
      const UpdatePresence(request: UpdatePresenceRequest(status: 'ONLINE')),
    );
  }

  void _onScroll() {
    // Infinite scroll – load older messages when user scrolls to the very top
    if (_scrollController.position.pixels <=
        _scrollController.position.minScrollExtent + 80) {
      final current = context.read<ChatBloc>().state;
      if (current is ChatMessagesLoaded &&
          current.hasMore &&
          !current.isLoadingMore &&
          current.oldestCursor != null) {
        context.read<ChatBloc>().add(
          LoadMoreMessages(
            chatRoomId: widget.roomId,
            cursor: current.oldestCursor!,
          ),
        );
      }
    }
  }

  Future<void> _checkMicrophonePermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      AppLogger.log('Microphone permission not granted');
    }
  }

  void _onTextChanged() {
    final isTyping = _messageController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() => _isTyping = isTyping);
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _searchController.dispose();
    _audioRecorder.dispose();

    // Mark presence as offline on leave
    context.read<ChatBloc>().add(
      const UpdatePresence(request: UpdatePresenceRequest(status: 'OFFLINE')),
    );

    super.dispose();
  }

  //  Send text ──

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatBloc>().add(
      SendMessage(
        request: SendMessageRequest(
          chatRoomId: widget.roomId,
          content: text,
          messageType: 'TEXT',
          parentMessageId: _replyToMessage?.messageId,
          mentions: _extractMentions(text),
        ),
      ),
    );

    setState(() {
      _messageController.clear();
      _replyToMessage = null;
    });

    _scrollToBottom();
  }

  List<String> _extractMentions(String text) {
    final regex = RegExp(r'@(\w+)');
    return regex
        .allMatches(text)
        .map((m) => m.group(1) ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  //  Send image ─

  Future<void> _sendImageMessage(File imageFile) async {
    // TODO: upload file first, get URL back, then send attachment URL in request
    context.read<ChatBloc>().add(
      SendMessage(
        request: SendMessageRequest(
          chatRoomId: widget.roomId,
          content: '📷 Photo',
          messageType: 'IMAGE',
          attachments: [imageFile.path],
        ),
      ),
    );
    _scrollToBottom();
  }

  Future<void> _sendFileMessage(File file, String fileName) async {
    context.read<ChatBloc>().add(
      SendMessage(
        request: SendMessageRequest(
          chatRoomId: widget.roomId,
          content: '📎 $fileName',
          messageType: 'FILE',
          attachments: [file.path],
        ),
      ),
    );
    _scrollToBottom();
  }

  Future<void> _sendVoiceMessage(String filePath, Duration duration) async {
    context.read<ChatBloc>().add(
      SendMessage(
        request: SendMessageRequest(
          chatRoomId: widget.roomId,
          content: '🎤 Voice message ${_formatDuration(duration)}',
          messageType: 'VOICE',
          attachments: [filePath],
        ),
      ),
    );
    _scrollToBottom();
  }

  //  Mark read ──

  void _markRoomAsRead(List<ChatMessageModel> messages) {
    if (messages.isEmpty) return;

    // Find last REAL message — skip optimistic temp ones
    final lastReal = messages.lastWhere(
      (m) => !m.id.startsWith('temp_') && !m.messageId.startsWith('temp_'),
      orElse: () => messages.last,
    );

    // Don't mark read if only temp messages exist
    if (lastReal.id.startsWith('temp_') ||
        lastReal.messageId.startsWith('temp_'))
      return;

    context.read<ChatBloc>().add(
      MarkRoomAsRead(
        request: MarkReadRequest(
          chatRoomId: widget.roomId,
          lastReadMessageId: lastReal.messageId,
        ),
      ),
    );
  }

  //  Scroll

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  //  Reply ─

  void _cancelReply() => setState(() => _replyToMessage = null);

  //  Message options

  void _showMessageOptions(ChatMessageModel message) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: kPrimary),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _replyToMessage = message);
                  _messageFocusNode.requestFocus();
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy, color: kPrimary),
                title: const Text('Copy'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message copied')),
                  );
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  //  Attachment pickers

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (image != null) await _sendImageMessage(File(image.path));
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) await _sendImageMessage(File(image.path));
    } catch (e) {
      _showErrorSnackBar('Failed to take photo: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      );
      if (result != null && result.files.single.path != null) {
        await _sendFileMessage(
          File(result.files.single.path!),
          result.files.single.name,
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

  //  Recording

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final filePath =
            '${directory.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: filePath,
        );

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
          _recordingStartTime = DateTime.now();
        });
      } else {
        _showErrorSnackBar('Microphone permission required');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      if (path != null && _recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!);
        await _sendVoiceMessage(path, duration);
      }
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _cancelRecording() async {
    try {
      await _audioRecorder.stop();
      if (_recordingPath != null) {
        final file = File(_recordingPath!);
        if (await file.exists()) await file.delete();
      }
      setState(() {
        _isRecording = false;
        _recordingPath = null;
        _recordingStartTime = null;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to cancel recording: $e');
    }
  }

  //  Search

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        context.read<ChatBloc>().add(const ClearSearch());
      }
    });
  }

  void _runSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<ChatBloc>().add(const ClearSearch());
      return;
    }
    context.read<ChatBloc>().add(
      SearchMessages(query: query.trim(), chatRoomId: widget.roomId),
    );
  }

  //  Room settings

  void _showChatOptions(ChatRoomModel? room) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  room?.isMuted == true
                      ? Icons.notifications_active_outlined
                      : Icons.notifications_off_outlined,
                  color: kPrimary,
                ),
                title: Text(
                  room?.isMuted == true
                      ? 'Unmute notifications'
                      : 'Mute notifications',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatBloc>().add(
                    UpdateRoomSettings(
                      roomId: widget.roomId,
                      request: UpdateRoomSettingsRequest(
                        isMuted: !(room?.isMuted ?? false),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  room?.isStarred == true ? Icons.star : Icons.star_border,
                  color: kPrimary,
                ),
                title: Text(
                  room?.isStarred == true ? 'Unstar chat' : 'Star chat',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatBloc>().add(
                    UpdateRoomSettings(
                      roomId: widget.roomId,
                      request: UpdateRoomSettingsRequest(
                        isStarred: !(room?.isStarred ?? false),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  room?.isPinned == true
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: kPrimary,
                ),
                title: Text(room?.isPinned == true ? 'Unpin chat' : 'Pin chat'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.read<ChatBloc>().add(
                    UpdateRoomSettings(
                      roomId: widget.roomId,
                      request: UpdateRoomSettingsRequest(
                        isPinned: !(room?.isPinned ?? false),
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: kPrimary),
                title: const Text('Search messages'),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleSearch();
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  //  Helpers ──

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Send Attachment',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                ),
              ),
              const Divider(height: 0),
              _attachmentOption(
                icon: Icons.photo_library,
                label: 'Photo Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _attachmentOption(
                icon: Icons.camera_alt,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              _attachmentOption(
                icon: Icons.insert_drive_file,
                label: 'Document',
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _attachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kPrimary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: kPrimary),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }

  //  Build ──

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is MessageSendError && state.chatRoomId == widget.roomId) {
            _showErrorSnackBar(state.error);
          }
          // In listener
          if (state is ChatMessagesLoaded &&
              state.chatRoomId == widget.roomId) {
            if (!state.isLoadingMore && state.sendingMessage == null) {
              _markRoomAsRead(state.messages); // only on real loads
            }
            _scrollToBottom();
          }

          if (state is ChatSettingsUpdated) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Settings updated')));
            // Reload to reflect changes
            context.read<ChatBloc>().add(LoadChatRoom(roomId: widget.roomId));
          }
          if (state is ChatMessagesLoaded &&
              state.chatRoomId == widget.roomId) {
            _markRoomAsRead(state.messages);
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          ChatRoomModel? room;
          List<ChatMessageModel> messages = [];
          bool isLoadingMore = false;

          if (state is ChatMessagesLoaded &&
              state.chatRoomId == widget.roomId) {
            room = state.room;
            messages = state.messages;
            isLoadingMore = state.isLoadingMore;
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF8F6F6),
            appBar: _buildAppBar(room),
            body: Column(
              children: [
                // Search bar (toggled)
                if (_isSearching) _buildSearchBar(),
                // Search results overlay
                if (_isSearching && state is ChatSearchResults)
                  _buildSearchResults(state.results),
                if (_isSearching && state is ChatSearchLoading)
                  const LinearProgressIndicator(color: kPrimary),
                if (_isSearching && state is ChatSearchEmpty)
                  _buildSearchEmpty(),
                // Load-more indicator at top
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kPrimary,
                        ),
                      ),
                    ),
                  ),
                // Messages list
                Expanded(child: _buildBody(state, messages)),
                // Reply preview
                if (_replyToMessage != null) _buildReplyPreview(),
                // Recording indicator
                if (_isRecording) _buildRecordingIndicator(),
                // Message input
                if (!_isRecording) _buildMessageInput(),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatRoomModel? room) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kprimaryTextColor1),
        onPressed: () {
          widget.showNavBarCallback?.call();
        },
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: widget.department.color,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.department.icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.customTitle ??
                      room?.name ??
                      widget.department.displayName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  room != null
                      ? '${room.memberCount} members'
                      : 'Department Chat',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    color: kprimaryTextColor2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        if (room?.unreadCount != null && room!.unreadCount > 0)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '${room.unreadCount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(
            _isSearching ? Icons.search_off : Icons.search,
            color: kprimaryTextColor1,
          ),
          onPressed: _toggleSearch,
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: kprimaryTextColor1),
          onPressed: () => _showChatOptions(room),
        ),
      ],
    );
  }

  //  Body states ─

  Widget _buildBody(ChatState state, List<ChatMessageModel> messages) {
    if (state is ChatMessagesLoading && state.chatRoomId == widget.roomId) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (state is ChatMessagesError && state.chatRoomId == widget.roomId) {
      return _buildErrorState(state.error);
    }

    if (messages.isEmpty) return _buildEmptyState();

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final showDateHeader =
            index == 0 ||
            !_isSameDay(message.sentAt, messages[index - 1].sentAt);
        return Column(
          children: [
            if (showDateHeader) _buildDateHeader(message.sentAt),
            _buildMessageBubble(message, messages),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: widget.department.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.department.icon,
              size: 50,
              color: widget.department.color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No messages yet',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: kprimaryTextColor1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation with your team',
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 14,
              color: kprimaryTextColor2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              error,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: _loadInitialData,
              child: const Text('Retry', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  //  Search overlay ─

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _runSearch,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 14,
                color: kprimaryTextColor1,
              ),
              decoration: InputDecoration(
                hintText: 'Search messages...',
                hintStyle: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  color: kprimaryTextColor2,
                ),
                prefixIcon: const Icon(Icons.search, color: kPrimary, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8F6F6),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _toggleSearch,
            child: Text(
              'Cancel',
              style: WorkSansAppTextStyles.medium.copyWith(
                color: kPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<ChatMessageModel> results) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      color: Colors.white,
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: results.length,
        separatorBuilder: (_, __) => const Divider(height: 0, indent: 16),
        itemBuilder: (context, index) {
          final msg = results[index];
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              backgroundColor: widget.department.color.withOpacity(0.2),
              child: Text(
                msg.senderName.isNotEmpty
                    ? msg.senderName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: widget.department.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              msg.senderName,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kprimaryTextColor1,
              ),
            ),
            subtitle: Text(
              msg.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 12,
                color: kprimaryTextColor2,
              ),
            ),
            trailing: Text(
              DateFormat('h:mm a').format(msg.sentAt),
              style: WorkSansAppTextStyles.medium.copyWith(
                fontSize: 11,
                color: kprimaryTextColor2,
              ),
            ),
            onTap: () {
              // TODO: scroll to message in list
              _toggleSearch();
            },
          );
        },
      ),
    );
  }

  Widget _buildSearchEmpty() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'No messages found',
          style: WorkSansAppTextStyles.medium.copyWith(
            color: kprimaryTextColor2,
          ),
        ),
      ),
    );
  }

  //  Date header ─

  Widget _buildDateHeader(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _formatDate(date),
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 12,
            color: kprimaryTextColor2,
          ),
        ),
      ),
    );
  }

  //  Message bubble ─

  Widget _buildMessageBubble(
    ChatMessageModel message,
    List<ChatMessageModel> allMessages,
  ) {
    final isMe =
        message.senderId == 'me' || // optimistic temp
        message.id.startsWith('temp_') || // optimistic temp
        message.senderId == widget.currentUserId; // confirmed from server

    // Find parent message for thread/reply display
    ChatMessageModel? parentMessage;
    if (message.parentMessageId != null) {
      parentMessage = allMessages.firstWhere(
        (m) => m.messageId == message.parentMessageId,
        orElse: () => message,
      );
    }

    return GestureDetector(
      onLongPress: () => _showMessageOptions(message),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: isMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[_buildAvatar(message), const SizedBox(width: 8)],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 12),
                      child: Text(
                        message.senderName,
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kprimaryTextColor2,
                        ),
                      ),
                    ),
                  // Reply/thread context
                  if (parentMessage != null && parentMessage != message)
                    _buildReplyContent(parentMessage, isMe),
                  // Bubble
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe
                          ? (message.id.startsWith('temp_')
                                ? kPrimary.withOpacity(0.6)
                                : kPrimary)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildMessageContent(message, isMe),
                  ),
                  const SizedBox(height: 4),
                  // Timestamp + status row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(message.sentAt),
                        style: WorkSansAppTextStyles.medium.copyWith(
                          fontSize: 11,
                          color: kprimaryTextColor2,
                        ),
                      ),
                      if (message.isEdited) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• edited',
                          style: WorkSansAppTextStyles.medium.copyWith(
                            fontSize: 10,
                            color: kprimaryTextColor2,
                          ),
                        ),
                      ],
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        _buildSendStatus(message),
                      ],
                      if (message.replyCount > 0) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            context.read<ChatBloc>().add(
                              LoadMessages(
                                chatRoomId: widget.roomId,
                                parentMessageId: message.messageId,
                              ),
                            );
                          },
                          child: Text(
                            '${message.replyCount} repl${message.replyCount == 1 ? 'y' : 'ies'}',
                            style: WorkSansAppTextStyles.medium.copyWith(
                              fontSize: 11,
                              color: kPrimary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendStatus(ChatMessageModel message) {
    if (message.id.startsWith('temp_')) {
      return const Icon(Icons.access_time, size: 14, color: Colors.grey);
    }
    return Icon(Icons.done_all, size: 14, color: Colors.grey[600]);
  }

  Widget _buildAvatar(ChatMessageModel message) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.department.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          message.senderName.isNotEmpty
              ? message.senderName[0].toUpperCase()
              : '?',
          style: WorkSansAppTextStyles.medium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: widget.department.color,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyContent(ChatMessageModel parent, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe ? Colors.transparent : const Color(0xFFF8F6F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe
              ? kPrimary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.reply,
                size: 14,
                color: isMe
                    ? Colors.black.withOpacity(0.7)
                    : kprimaryTextColor2,
              ),
              const SizedBox(width: 4),
              Text(
                parent.senderName,
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isMe ? Colors.black.withOpacity(0.9) : kPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            parent.content,
            style: WorkSansAppTextStyles.medium.copyWith(
              fontSize: 12,
              color: isMe ? Colors.black.withOpacity(0.7) : kprimaryTextColor2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessageModel message, bool isMe) {
    switch (message.messageType) {
      case 'IMAGE':
        if (message.attachments.isNotEmpty || message.hasAttachments) {
          final path = message.attachments.isNotEmpty
              ? message.attachments.first['url']?.toString() ?? ''
              : '';
          if (path.startsWith('/')) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(path),
                width: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imagePlaceholder(isMe),
              ),
            );
          }
          return _imagePlaceholder(isMe);
        }
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : kprimaryTextColor1,
            fontSize: 14,
          ),
        );

      case 'FILE':
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: isMe ? Colors.white : kPrimary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message.content.replaceFirst('📎 ', ''),
                style: TextStyle(
                  color: isMe ? Colors.white : kprimaryTextColor1,
                ),
              ),
            ),
          ],
        );

      case 'VOICE':
        return _buildVoiceContent(message.content, isMe);

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: isMe ? Colors.white : kprimaryTextColor1,
            fontSize: 14,
          ),
        );
    }
  }

  Widget _imagePlaceholder(bool isMe) {
    return Container(
      width: 180,
      height: 180,
      color: isMe ? Colors.white.withOpacity(0.2) : Colors.grey[200],
      child: Icon(
        Icons.image,
        size: 60,
        color: isMe ? Colors.white : kprimaryTextColor2,
      ),
    );
  }

  Widget _buildVoiceContent(String content, bool isMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.play_circle_filled,
          color: isMe ? Colors.white : kPrimary,
          size: 32,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 3,
                width: 100,
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.white.withOpacity(0.3)
                      : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white : kPrimary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: TextStyle(
                  fontSize: 12,
                  color: isMe ? Colors.white.withOpacity(0.8) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  //  Reply preview bar ──

  Widget _buildReplyPreview() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: kPrimary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.senderName}',
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _replyToMessage!.content,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 13,
                    color: kprimaryTextColor2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: kprimaryTextColor2),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  //  Recording indicator

  Widget _buildRecordingIndicator() {
    final duration = _recordingStartTime != null
        ? DateTime.now().difference(_recordingStartTime!)
        : Duration.zero;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording...',
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDuration(duration),
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 13,
                      color: kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _cancelRecording,
            ),
            IconButton(
              icon: const Icon(Icons.send, color: kPrimary),
              onPressed: _stopRecording,
            ),
          ],
        ),
      ),
    );
  }

  //  Message input bar ──

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // IconButton(
            //   icon: const Icon(Icons.add_circle_outline, color: kPrimary),
            //   onPressed: _showAttachmentOptions,
            //   padding: const EdgeInsets.all(8),
            // ),
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 40,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F6F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _messageFocusNode,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 14,
                    color: kprimaryTextColor1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 14,
                      color: kprimaryTextColor2,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendMessage,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //  Utils ──

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'Today';
    if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      return 'Yesterday';
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
