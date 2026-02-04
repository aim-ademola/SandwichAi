// lib/src/features/chat/presentation/department_chat_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:sandwich_ai/src/core/constant/appcolors.dart';
import 'package:sandwich_ai/src/core/constant/textstyle.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sandwich_ai/src/core/globals/navbars/pos_navbar.dart';
import 'package:sandwich_ai/src/features/pos/data/model/chat_models.dart';

class DepartmentChatScreen extends StatefulWidget {
  final Department department;
  final String? customTitle;
  final VoidCallback? showNavBarCallback;

  const DepartmentChatScreen({
    super.key,
    required this.department,
    this.customTitle,
    this.showNavBarCallback,
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

  ChatMessage? _replyToMessage;
  bool _isTyping = false;
  bool _isRecording = false;
  String? _recordingPath;
  DateTime? _recordingStartTime;

  // Mock current user
  final String _currentUserId = 'u1';
  final String _currentUserName = 'You';

  // Mock messages
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _messageController.addListener(_onTextChanged);
    _checkMicrophonePermission();
  }

  Future<void> _checkMicrophonePermission() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      print('Microphone permission not granted');
    }
  }

  void _loadMessages() {
    setState(() {
      _messages.addAll([
        ChatMessage(
          id: 'm1',
          chatId: widget.department.name,
          senderId: 'u2',
          senderName: 'Chef John',
          senderAvatar: null,
          content: 'Good morning team! Ready for today\'s service?',
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm2',
          chatId: widget.department.name,
          senderId: 'u3',
          senderName: 'Maria Lopez',
          senderAvatar: null,
          content: 'Yes! All prep work is done.',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 55),
          ),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm3',
          chatId: widget.department.name,
          senderId: _currentUserId,
          senderName: _currentUserName,
          content:
              'Inventory check complete. We need to order more chicken stock.',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 50),
          ),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm4',
          chatId: widget.department.name,
          senderId: 'u2',
          senderName: 'Chef John',
          senderAvatar: null,
          content: 'Perfect timing! Can you order 10 liters?',
          timestamp: DateTime.now().subtract(
            const Duration(hours: 2, minutes: 45),
          ),
          status: MessageStatus.read,
        ),
        ChatMessage(
          id: 'm5',
          chatId: widget.department.name,
          senderId: _currentUserId,
          senderName: _currentUserName,
          content: 'Will do right away! 👍',
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
          status: MessageStatus.delivered,
        ),
      ]);
    });
  }

  void _onTextChanged() {
    final isTyping = _messageController.text.trim().isNotEmpty;
    if (isTyping != _isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final newMessage = ChatMessage(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.department.name,
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: text,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      replyToMessage: _replyToMessage,
    );

    setState(() {
      _messages.add(newMessage);
      _messageController.clear();
      _replyToMessage = null;
    });

    _scrollToBottom();

    // Simulate message delivery
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(status: MessageStatus.sent);
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(
              status: MessageStatus.delivered,
            );
          }
        });
      }
    });
  }

  Future<void> _sendImage(File imageFile) async {
    final newMessage = ChatMessage(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.department.name,
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: '📷 Photo',
      type: MessageType.image,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachmentUrls: [imageFile.path],
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate upload
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(status: MessageStatus.sent);
          }
        });
      }
    });
  }

  Future<void> _sendFile(File file, String fileName) async {
    final newMessage = ChatMessage(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.department.name,
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: '📎 $fileName',
      type: MessageType.file,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachmentUrls: [file.path],
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate upload
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(status: MessageStatus.sent);
          }
        });
      }
    });
  }

  Future<void> _sendVoiceNote(String filePath, Duration duration) async {
    final newMessage = ChatMessage(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      chatId: widget.department.name,
      senderId: _currentUserId,
      senderName: _currentUserName,
      content: '🎤 Voice message ${_formatDuration(duration)}',
      type: MessageType.voice,
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
      attachmentUrls: [filePath],
    );

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate upload
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          final index = _messages.indexWhere((m) => m.id == newMessage.id);
          if (index != -1) {
            _messages[index] = newMessage.copyWith(status: MessageStatus.sent);
          }
        });
      }
    });
  }

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

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  void _showMessageOptions(ChatMessage message) {
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
                  setState(() {
                    _replyToMessage = message;
                  });
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
              if (message.senderId == _currentUserId) ...[
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.edit, color: kPrimary),
                  title: const Text('Edit'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _messageController.text = message.content;
                      _messageFocusNode.requestFocus();
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _messages.remove(message);
                    });
                  },
                ),
              ],
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

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        await _sendImage(File(image.path));
      }
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

      if (image != null) {
        await _sendImage(File(image.path));
      }
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
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        await _sendFile(file, fileName);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick file: $e');
    }
  }

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
        await _sendVoiceNote(path, duration);
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
        if (await file.exists()) {
          await file.delete();
        }
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
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: kPrimary),
                ),
                title: const Text('Photo Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: kPrimary),
                ),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.insert_drive_file, color: kPrimary),
                ),
                title: const Text('Document'),
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

  @override
  Widget build(BuildContext context) {
    final posNavBarState = context
        .findAncestorStateOfType<PosBottomNavBarState>();

    return DefaultTextStyle.merge(
      style: WorkSansAppTextStyles.medium,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        appBar: _buildAppBar(posNavBarState),
        body: Column(
          children: [
            // Messages list
            Expanded(
              child: _messages.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final showDateHeader =
                            index == 0 ||
                            !_isSameDay(
                              message.timestamp,
                              _messages[index - 1].timestamp,
                            );
                        return Column(
                          children: [
                            if (showDateHeader)
                              _buildDateHeader(message.timestamp),
                            _buildMessageBubble(message),
                          ],
                        );
                      },
                    ),
            ),
            // Reply preview
            if (_replyToMessage != null) _buildReplyPreview(),
            // Recording indicator
            if (_isRecording) _buildRecordingIndicator(),
            // Message input
            if (!_isRecording) _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(PosBottomNavBarState? posNavBarState) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: kprimaryTextColor1),
        onPressed: () {
          print('ji');
          widget.showNavBarCallback?.call();
          // Navigator.pop(context);
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
                  widget.customTitle ?? widget.department.displayName,
                  style: WorkSansAppTextStyles.medium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: kprimaryTextColor1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Department Chat',
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
        IconButton(
          icon: const Icon(Icons.search, color: kprimaryTextColor1),
          onPressed: () {
            // Implement search in messages
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: kprimaryTextColor1),
          onPressed: _showChatOptions,
        ),
      ],
    );
  }

  void _showChatOptions() {
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
                leading: const Icon(
                  Icons.notifications_outlined,
                  color: kPrimary,
                ),
                title: const Text('Mute notifications'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('Chat muted')));
                },
              ),
              ListTile(
                leading: const Icon(Icons.search, color: kPrimary),
                title: const Text('Search messages'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.group_outlined, color: kPrimary),
                title: const Text('View members'),
                onTap: () {
                  Navigator.pop(context);
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

  Widget _buildMessageBubble(ChatMessage message) {
    final isMe = message.senderId == _currentUserId;

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
            if (!isMe) ...[
              _buildMessageAvatar(message),
              const SizedBox(width: 8),
            ],
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
                  if (message.replyToMessage != null)
                    _buildReplyContent(message.replyToMessage!, isMe),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? kPrimary : Colors.white,
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
                  Text(
                    message.content.split(' ').last, // Extract duration
                    style: WorkSansAppTextStyles.medium.copyWith(
                      fontSize: 11,
                      color: isMe
                          ? Colors.white.withOpacity(0.7)
                          : kprimaryTextColor2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageAvatar(ChatMessage message) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: widget.department.color.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: message.senderAvatar != null
          ? ClipOval(
              child: Image.asset(message.senderAvatar!, fit: BoxFit.cover),
            )
          : Center(
              child: Text(
                message.senderName[0].toUpperCase(),
                style: WorkSansAppTextStyles.medium.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.department.color,
                ),
              ),
            ),
    );
  }

  Widget _buildMessageStatus(MessageStatus status) {
    IconData icon;
    Color color;

    switch (status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white.withOpacity(0.7);
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.white;
        break;
      case MessageStatus.failed:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
    }

    return Icon(icon, size: 14, color: color);
  }

  Widget _buildReplyContent(ChatMessage replyMessage, bool isMe) {
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
                replyMessage.senderName,
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
            replyMessage.content,
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
            // Recording animation
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
            // Recording time
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
            // Cancel button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _cancelRecording,
            ),
            // Send button
            IconButton(
              icon: const Icon(Icons.send, color: kPrimary),
              onPressed: _stopRecording,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: kPrimary),
              onPressed: _showAttachmentOptions,
              padding: const EdgeInsets.all(8),
            ),
            // Text field
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
            // Send or Mic button
            if (_isTyping)
              // Send button
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
              )
            else
              // Mic button
              GestureDetector(
                onLongPressStart: (_) => _startRecording(),
                onLongPressEnd: (_) => _stopRecording(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: kPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return "Today";
    if (_isSameDay(date, now.subtract(const Duration(days: 1))))
      return "Yesterday";
    return DateFormat('EEE, MMM d').format(date);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
//                 Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       DateFormat('h:mm a').format(message.timestamp),
//                       style: WorkSansAppTextStyles.medium.copyWith(
//                         fontSize: 11,
//                         color: kprimaryTextColor2,
//                       ),
//                     ),
//                     if (isMe) ...[
//                       const SizedBox(width: 4),
//                       _buildMessageStatus(message.status),
//                     ],
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }

Widget _buildMessageContent(ChatMessage message, bool isMe) {
  switch (message.type) {
    case MessageType.text:
      return Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : kprimaryTextColor1,
          fontSize: 14,
        ),
      );

    case MessageType.image:
      if (message.attachmentUrls != null &&
          message.attachmentUrls!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            File(message.attachmentUrls!.first),
            width: 180,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
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
            },
          ),
        );
      }
      return Text(
        message.content,
        style: TextStyle(color: isMe ? Colors.white : kprimaryTextColor1),
      );

    case MessageType.file:
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: isMe ? Colors.white : kPrimary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message.content.replaceFirst("📎 ", ""),
              style: TextStyle(color: isMe ? Colors.white : kprimaryTextColor1),
            ),
          ),
        ],
      );

    case MessageType.voice:
      return _buildVoiceContent(message.content, isMe);

    default:
      return Text(
        "Unsupported message",
        style: TextStyle(color: isMe ? Colors.white : Colors.black),
      );
  }
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
                color: isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.3, // progress %
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
              content, // e.g. "0:12"
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
