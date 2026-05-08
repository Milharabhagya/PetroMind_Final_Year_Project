// ✅ PREMIUM REDESIGN — ALL LOGIC PRESERVED
// Design: Minimalist Industrial SaaS · Poppins
// Matches HomeScreen & AlertsScreen Design System

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/models/area_message_model.dart';
import '../../../data/services/area_chat_service.dart';

// ─────────────────────────────────────────────
//  DESIGN TOKENS (Shared from Home)
// ─────────────────────────────────────────────
class _T {
  static const primary    = Color(0xFFAD2831);
  static const dark       = Color(0xFF38040E);
  static const accent     = Color(0xFF250902);
  static const bg         = Color(0xFFF8F4F1);
  static const surface    = Color(0xFFFFFFFF);
  static const muted      = Color(0xFFF2EBE7);
  static const textPrimary   = Color(0xFF1A0A0C);
  static const textSecondary = Color(0xFF7A5C60);
  static const border     = Color(0xFFEADDDA);

  static const h1 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    letterSpacing: -0.4,
  );
  static const h2 = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    letterSpacing: -0.2,
  );
  static const label = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    letterSpacing: 0.6,
  );
  static const body = TextStyle(
    fontFamily: 'Poppins',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static BoxDecoration card({Color? color, bool hasBorder = true}) =>
      BoxDecoration(
        color: color ?? surface,
        borderRadius: BorderRadius.circular(16),
        border: hasBorder ? Border.all(color: border, width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: dark.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

// ─────────────────────────────────────────────
//  AREA CHAT SCREEN
// ─────────────────────────────────────────────
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
  State<AreaChatScreen> createState() => _AreaChatScreenState();
}

class _AreaChatScreenState extends State<AreaChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AreaChatService _chatService = AreaChatService();

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
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return 'yesterday';
  }

  bool _isMe(AreaMessage msg) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return msg.senderId == uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      appBar: AppBar(
        backgroundColor: _T.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _T.dark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nearby Chat', style: _T.h2.copyWith(fontSize: 16)),
            Text(
              widget.locationLabel,
              style: _T.label.copyWith(fontSize: 10, color: _T.primary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: _T.dark),
            onPressed: () => _showInfoDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ✅ Notice banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Only drivers within ~1km can see these messages',
                    style: _T.body.copyWith(fontSize: 11, color: const Color(0xFF92400E)),
                  ),
                ),
              ],
            ),
          ),

          // ✅ Messages list
          Expanded(
            child: StreamBuilder<List<AreaMessage>>(
              stream: _chatService.getMessages(
                userLat: widget.userLat,
                userLng: widget.userLng,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _T.primary, strokeWidth: 3),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: _T.muted,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: _T.textSecondary),
                        ),
                        const SizedBox(height: 16),
                        Text('No messages in your area', style: _T.h2),
                        const SizedBox(height: 4),
                        Text('Be the first to share fuel info!', style: _T.body),
                      ],
                    ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  physics: const BouncingScrollPhysics(),
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final msg = messages[i];
                    final isMe = _isMe(msg);
                    final showName = i == 0 || messages[i - 1].senderId != msg.senderId;

                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      showName: showName,
                      timeAgo: _timeAgo(msg.sentAt),
                      onReply: () => setState(() => _replyingTo = msg),
                    );
                  },
                );
              },
            ),
          ),

          // ✅ Quick message chips
          Container(
            color: _T.bg,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _quickMessages.map((msg) {
                  return GestureDetector(
                    onTap: () => _sendMessage(msg),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _T.surface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: _T.border),
                        boxShadow: [
                          BoxShadow(
                            color: _T.dark.withOpacity(0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        msg,
                        style: _T.body.copyWith(fontSize: 11, color: _T.textPrimary),
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
              color: _T.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _T.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Replying to ${_replyingTo!.senderName}',
                          style: _T.label.copyWith(color: _T.primary, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _replyingTo!.message,
                          style: _T.body.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: _T.textSecondary),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),

          // ✅ Message input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).padding.bottom + 12, // Safe area padding
            ),
            decoration: BoxDecoration(
              color: _T.surface, // Kept color here inside decoration
              boxShadow: [
                BoxShadow(
                  color: _T.dark.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _T.bg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _T.border),
                    ),
                    child: TextField(
                      controller: _msgController,
                      maxLines: 4,
                      minLines: 1,
                      style: _T.body.copyWith(color: _T.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ask about fuel availability...',
                        hintStyle: _T.body.copyWith(color: _T.textSecondary.withOpacity(0.6)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isSending ? null : () => _sendMessage(_msgController.text),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isSending ? _T.muted : _T.primary,
                      shape: BoxShape.circle,
                      boxShadow: _isSending ? null : [
                        BoxShadow(
                          color: _T.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _T.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _T.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.people_rounded, color: _T.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Text('About Nearby Chat', style: _T.h2),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('🔒', 'All users are anonymous — shown as "Nearby Driver #XXXX"'),
            _buildInfoRow('📍', 'Only drivers within ~1km of you can see your messages'),
            _buildInfoRow('⏱️', 'Messages disappear after 24 hours automatically'),
            _buildInfoRow('🔔', 'You\'ll get a notification when someone replies'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: _T.label.copyWith(color: _T.primary, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: _T.body.copyWith(fontSize: 12))),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (showName && !isMe)
            Padding(
              padding: const EdgeInsets.only(left: 44, bottom: 4),
              child: Text(
                message.senderName,
                style: _T.label.copyWith(fontSize: 10),
              ),
            ),
          GestureDetector(
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                onReply();
              }
            },
            child: Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _nameColor(message.senderName).withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: _nameColor(message.senderName).withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Text(
                        message.senderName.split('#').last.substring(0, 1),
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _nameColor(message.senderName),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? _T.primary : _T.surface,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isMe ? 16 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 16),
                      ),
                      border: isMe ? null : Border.all(color: _T.border),
                      boxShadow: [
                        BoxShadow(
                          color: _T.dark.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white.withOpacity(0.15) : _T.bg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isMe ? Colors.white : _T.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Text(
                              message.replyToMessage!,
                              style: _T.body.copyWith(
                                fontSize: 11,
                                color: isMe ? Colors.white70 : _T.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        Text(
                          message.message,
                          style: _T.body.copyWith(
                            fontSize: 13,
                            color: isMe ? Colors.white : _T.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              timeAgo,
                              style: _T.label.copyWith(
                                fontSize: 9,
                                color: isMe ? Colors.white60 : _T.textSecondary.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onReply,
                              child: Text(
                                'Reply',
                                style: _T.label.copyWith(
                                  fontSize: 9,
                                  color: isMe ? Colors.white : _T.primary,
                                  fontWeight: FontWeight.bold,
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

  // Refined palette for avatar generation
  Color _nameColor(String name) {
    final colors = [
      const Color(0xFFAD2831), // Primary Red
      const Color(0xFF2563EB), // Royal Blue
      const Color(0xFF16A34A), // Emerald
      const Color(0xFF7C3AED), // Deep Purple
      const Color(0xFF0D9488), // Teal
      const Color(0xFFEA580C), // Orange
    ];
    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }
}