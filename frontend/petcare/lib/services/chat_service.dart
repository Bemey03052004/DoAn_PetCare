import 'dart:async';
import 'dart:convert';
import 'package:signalr_core/signalr_core.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ChatService {
  final AuthService _authService;
  HubConnection? _connection;

  ChatService(this._authService);

  Future<void> connect() async {
    final token = await _authService.getToken();
    // Build hub url from API base
    final url = ApiConfig.baseUrl.replaceFirst('/api', '/hubs/chat');
    _connection = HubConnectionBuilder()
        .withUrl(url, HttpConnectionOptions(
          accessTokenFactory: token != null ? () async => token : null,
          // Let SignalR negotiate the best transport (WS/LongPolling)
          transport: HttpTransportType.webSockets,
          skipNegotiation: false,
        ))
        .withAutomaticReconnect()
        .build();
    _connection!.onclose((error) {
      // ignore: avoid_print
      if (error != null) print('SignalR closed: $error');
    });
    await _connection!.start();
  }

  bool get isConnected => _connection?.state == HubConnectionState.connected;

  Stream<Map<String, dynamic>> subscribeMessages() {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _connection?.on('ReceiveMessage', (args) {
      if (args != null && args.isNotEmpty && args.first is Map<String, dynamic>) {
        controller.add(args.first as Map<String, dynamic>);
      }
    });
    return controller.stream;
  }

  Future<int> startDirectChat(int otherUserId) async {
    final roomId = await _connection!.invoke('StartDirectChat', args: [otherUserId]);
    return (roomId as int);
  }

  Future<void> joinRoom(int roomId) async {
    await _connection!.invoke('JoinRoom', args: [roomId]);
  }

  Future<void> sendMessage(int roomId, String content) async {
    await _connection!.invoke('SendMessage', args: [roomId, content]);
  }

  Future<void> dispose() async {
    await _connection?.stop();
  }

  // REST history
  Future<List<Map<String, dynamic>>> getMessages(int roomId, {int? take = 50, int? beforeId}) async {
    final headers = await _authService.authHeaders();
    final base = ApiConfig.baseUrl.replaceFirst('/api', '');
    final qp = <String, String>{
      'take': (take ?? 50).toString(),
      if (beforeId != null) 'beforeId': beforeId.toString(),
    };
    final uri = Uri.parse('$base/api/chat/rooms/$roomId/messages').replace(queryParameters: qp);
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      if (res.body.isEmpty) return <Map<String, dynamic>>[];
      try {
        final body = jsonDecode(res.body) as Map<String, dynamic>;
        if (body['success'] == true && body['data'] is List) {
          final List list = body['data'] as List;
          return list.cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }
    throw Exception('Failed to load messages: ${res.statusCode}');
  }

  Future<Map<String, dynamic>> getUserInfo(int userId) async {
    final headers = await _authService.authHeaders();
    final uri = Uri.parse('${ApiConfig.baseUrl}/users/$userId/basic');
    
    final res = await http.get(uri, headers: headers);
    if (res.statusCode == 200) {
      final responseBody = jsonDecode(res.body) as Map<String, dynamic>;
      if (responseBody['success'] == true) {
        return responseBody['data'] as Map<String, dynamic>;
      }
    }
    throw Exception('Failed to load user info: ${res.statusCode}');
  }
}


