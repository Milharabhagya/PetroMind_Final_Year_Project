import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/area_message_model.dart';
import '../../../data/services/area_chat_service.dart';

class AreaChatScreen extends StatefulWidget {
  final double userLat;
  final double userLng;
  final String locationLabel;

  const AreaChatScreen({
    super.key,
    required this.userLat,
    required this.userLng,
    required this.locationLabel,
  });

  @override
  State<AreaChatScreen> createState() =>
      _AreaChatScreenState();
}

class _AreaChatScreenState
    extends State<AreaChatScreen> {
  final TextEditingController _msgController =
      TextEditingController();
  final ScrollController _scrollController =
      ScrollController();
  final AreaChatService _chatService =
      AreaChatService();

  AreaMessage? _replyingTo;
  bool _isSending = false;

  final List<String> _quickMessages = [
    '⛽ 92 Petrol available here!',
    '❌ 92 Petrol out of stock',
    '✅ Diesel available',
    '❌ Diesel out of stock',
    '🚗 Short queue (~5 min)',
    '⏳ Long queue (30+ min)',
    '🔒 Station closed',
  ];

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(
        const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController
              .position.maxScrollExtent,
          duration:
              const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    setState(() => _isSending = true);

    await _chatService.sendMessage(
      userLat: widget.userLat,
      userLng: widget.userLng,
      message: text.trim(),
      replyToId: _replyingTo?.id,
      replyToMessage: _replyingTo?.message,
    );

    _msgController.clear();
    setState(() {
      _replyingTo = null;
      _isSending = false;
    });
    _scrollToBottom();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60)
      return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)
      return '${diff.inHours}h ago';
    return 'yesterday';
  }

  bool _isMe(AreaMessage msg) {
    final uid =
        FirebaseAuth.instance.currentUser?.uid ?? '';
    return msg.senderId == uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0EB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: Colors.white, size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'Nearby Drivers Chat',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15),
            ),
            Text(
              widget.locationLabel,
              style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline,
                color: Colors.white),
            onPressed: () =>
                _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Notice banner
          Container(
            width: double.infinity,
            color: Colors.amber[100],
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 6),
            child: Row(children: [
              const Icon(Icons.location_on,
                  size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Only drivers within ~1km of you can see these messages',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange[800]),
                ),
              ),
            ]),
          ),

          // ✅ Messages list
          Expanded(
            child: StreamBuilder<List<AreaMessage>>(
              stream: _chatService.getMessages(
                userLat: widget.userLat,
                userLng: widget.userLng,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF8B0000)),
                  );
                }

                final messages =
                    snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                            Icons
                                .chat_bubble_outline,
                            size: 48,
                            color:
                                Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No messages yet in your area',
                          style: TextStyle(
                              color:
                                  Colors.grey[600],
                              fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Be the first to share fuel info!',
                          style: TextStyle(
                              color:
                                  Colors.grey[400],
                              fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = _isMe(msg);
                    final showName = i == 0 ||
                        messages[i - 1].senderId !=
                            msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showName: showName,
                      timeAgo: _timeAgo(msg.sentAt),
                      onReply: () => setState(
                          () => _replyingTo = msg),
                    );
                  },
                );
              },
            ),
          ),

          // ✅ Quick message chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    _quickMessages.map((msg) {
                  return GestureDetector(
                    onTap: () => _sendMessage(msg),
                    child: Container(
                      margin: const EdgeInsets.only(
                          right: 6),
                      padding:
                          const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(
                                0xFF8B0000)
                            .withValues(alpha: 0.08),
                        borderRadius:
                            BorderRadius.circular(
                                16),
                        border: Border.all(
                          color: const Color(
                                  0xFF8B0000)
                              .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        msg,
                        style: const TextStyle(
                            fontSize: 11,
                            color:
                                Color(0xFF8B0000)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ✅ Reply preview
          if (_replyingTo != null)
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              child: Row(children: [
                const Icon(Icons.reply,
                    color: Color(0xFF8B0000),
                    size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _replyingTo!.senderName,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF8B0000),
                            fontWeight:
                                FontWeight.bold),
                      ),
                      Text(
                        _replyingTo!.message,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16),
                  onPressed: () => setState(
                      () => _replyingTo = null),
                ),
              ]),
            ),

          // ✅ Message input
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(
                12, 8, 12, 12),
            child: Row(children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius:
                        BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _msgController,
                    maxLines: 3,
                    minLines: 1,
                    decoration:
                        const InputDecoration(
                      hintText:
                          'Ask about fuel availability...',
                      hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 13),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10),
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _isSending
                    ? null
                    : () => _sendMessage(
                        _msgController.text),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSending
                        ? Colors.grey
                        : const Color(0xFF8B0000),
                    shape: BoxShape.circle,
                  ),
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ))
                      : const Icon(Icons.send,
                          color: Colors.white,
                          size: 20),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.people,
              color: Color(0xFF8B0000)),
          SizedBox(width: 8),
          Text('About Nearby Chat'),
        ]),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              '🔒 All users are anonymous — shown as "Nearby Driver #XXXX"',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '📍 Only drivers within ~1km of you can see your messages',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '⏱️ Messages disappear after 24 hours automatically',
              style: TextStyle(fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              '🔔 You\'ll get a notification when someone replies in your area',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child: const Text('Got it',
                style: TextStyle(
                    color: Color(0xFF8B0000))),
          ),
        ],
      ),
    );
  }
}

// ── MESSAGE BUBBLE WIDGET ──
class _MessageBubble extends StatelessWidget {
  final AreaMessage message;
  final bool isMe;
  final bool showName;
  final String timeAgo;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.showName,
    required this.timeAgo,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (showName && !isMe)
            Padding(
              padding: const EdgeInsets.only(
                  left: 4, bottom: 2),
              child: Text(
                message.senderName,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold),
              ),
            ),

          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null &&
                  details.primaryVelocity! > 100) {
                onReply();
              }
            },
            child: Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: [
                if (!isMe)
                  Container(
                    margin: const EdgeInsets.only(
                        right: 6),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _nameColor(
                          message.senderName),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        message.senderName
                            .split('#')
                            .last
                            .substring(0, 1),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.bold),
                      ),
                    ),
                  ),

                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth:
                        MediaQuery.of(context)
                                .size
                                .width *
                            0.72,
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? const Color(0xFF8B0000)
                          : Colors.white,
                      borderRadius:
                          BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight:
                            const Radius.circular(16),
                        bottomLeft: Radius.circular(
                            isMe ? 16 : 4),
                        bottomRight: Radius.circular(
                            isMe ? 4 : 16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        if (message.replyToMessage !=
                            null)
                          Container(
                            margin:
                                const EdgeInsets.only(
                                    bottom: 6),
                            padding:
                                const EdgeInsets.all(
                                    8),
                            decoration: BoxDecoration(
                              color: isMe
                                  ? Colors.white
                                      .withValues(
                                          alpha: 0.15)
                                  : Colors.grey[100],
                              borderRadius:
                                  BorderRadius
                                      .circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe
                                      ? Colors.white
                                      : const Color(
                                          0xFF8B0000),
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToMessage!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isMe
                                    ? Colors.white70
                                    : Colors.grey[600],
                              ),
                              maxLines: 2,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                            ),
                          ),

                        Text(
                          message.message,
                          style: TextStyle(
                            fontSize: 13,
                            color: isMe
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Text(
                              timeAgo,
                              style: TextStyle(
                                fontSize: 9,
                                color: isMe
                                    ? Colors.white60
                                    : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onReply,
                              child: Text(
                                'Reply',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isMe
                                      ? Colors.white60
                                      : const Color(
                                          0xFF8B0000),
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _nameColor(String name) {
    final colors = [
      const Color(0xFF8B0000),
      Colors.blue[700]!,
      Colors.green[700]!,
      Colors.purple[700]!,
      Colors.teal[700]!,
      Colors.indigo[700]!,
    ];
    final index =
        name.hashCode.abs() % colors.length;
    return colors[index];
  }
}