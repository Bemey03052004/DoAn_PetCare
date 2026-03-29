import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

class ChatScreen extends StatefulWidget {
  final int? otherUserId;
  final String? roomId;
  final String? title;
  final String? petName;
  final String? chatType; // 'adoption', 'boarding', 'sale'
  
  const ChatScreen({
    super.key, 
    this.otherUserId,
    this.roomId,
    this.title,
    this.petName,
    this.chatType,
  }) : assert(otherUserId != null || (roomId != null && title != null), 
              'Either otherUserId or both roomId and title must be provided');

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatService _chatService;
  final List<Map<String, dynamic>> _messages = [];
  final _textCtrl = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _sub;
  int? _roomId;
  bool _loadingHistory = true;
  String? _otherUserName;
  bool _isLoadingUserInfo = true;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService(AuthService());
    _init();
  }

  Future<void> _init() async {
    await _chatService.connect();
    
    if (widget.otherUserId != null) {
      // Unified chat logic for both adoption and boarding
      final roomId = await _chatService.startDirectChat(widget.otherUserId!);
      await _chatService.joinRoom(roomId);
      setState(() => _roomId = roomId);
      
      // Load other user info
      await _loadOtherUserInfo();
    } else if (widget.roomId != null) {
      // Legacy support for direct room ID (backward compatibility)
      final roomIdInt = int.tryParse(widget.roomId!) ?? 0;
      if (roomIdInt > 0) {
        await _chatService.joinRoom(roomIdInt);
        setState(() => _roomId = roomIdInt);
      } else {
        setState(() => _loadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể kết nối chat. Vui lòng thử lại.')),
        );
        return;
      }
    }
    
    // Load history
    final history = await _chatService.getMessages(_roomId!, take: 50);
    setState(() {
      _messages.addAll(history);
      _loadingHistory = false;
    });
    _sub = _chatService.subscribeMessages().listen((msg) {
      setState(() => _messages.add(msg));
    });
  }

  Future<void> _loadOtherUserInfo() async {
    if (widget.otherUserId == null) return;
    
    try {
      // Get user info from chat service or API
      final userInfo = await _chatService.getUserInfo(widget.otherUserId!);
      setState(() {
        _otherUserName = userInfo['fullName'] ?? 'Người dùng';
        _isLoadingUserInfo = false;
      });
    } catch (e) {
      setState(() {
        _otherUserName = 'Người dùng';
        _isLoadingUserInfo = false;
      });
    }
  }

  String _getChatTitle() {
    if (_isLoadingUserInfo) {
      return 'Đang tải...';
    }
    
    if (widget.petName != null && _otherUserName != null) {
      switch (widget.chatType) {
        case 'adoption':
          return 'Đang chat với $_otherUserName về việc nhận nuôi ${widget.petName}';
        case 'boarding':
          return 'Đang chat với $_otherUserName về việc giữ dùm ${widget.petName}';
        case 'sale':
          return 'Đang chat với $_otherUserName về việc mua bán ${widget.petName}';
        default:
          return 'Đang chat với $_otherUserName về ${widget.petName}';
      }
    }
    
    if (_otherUserName != null) {
      return 'Đang chat với $_otherUserName';
    }
    
    return widget.title ?? 'Chat';
  }

  @override
  void dispose() {
    _sub?.cancel();
    _chatService.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _roomId == null) return;
    await _chatService.sendMessage(_roomId!, text);
    _textCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: Text(_getChatTitle())),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isMine = m['senderId'] == me?.id;
                return Align(
                  alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue : Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m['content'] ?? '',
                      style: TextStyle(color: isMine ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textCtrl,
                      decoration: const InputDecoration(hintText: 'Nhập tin nhắn...'),
                    ),
                  ),
                  IconButton(onPressed: _send, icon: const Icon(Icons.send))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}


