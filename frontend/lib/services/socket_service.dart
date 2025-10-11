import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_constants.dart';
import 'token_manager.dart';
import 'dart:async';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  final ValueNotifier<List<String>> _onlineUsers = ValueNotifier([]);
  ValueNotifier<List<String>> get onlineUsers => _onlineUsers;

  final StreamController<Map<String, dynamic>> _notificationController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;

  final StreamController<Map<String, dynamic>> _demandUpdateController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get demandUpdates => _demandUpdateController.stream;

  final StreamController<Map<String, dynamic>> _messageStatusUpdateController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get messageStatusUpdates => _messageStatusUpdateController.stream;

  void connect() async {
    final token = await TokenManager().getToken();
    final userId = await TokenManager().getUserId();

    if (token == null || userId == null) {
      return;
    }

    _socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token,
      }
    });

    _socket!.onConnect((_) {
      print('Socket connected');
      _socket!.emit('user connected', {'userId': userId});
    });

    _socket!.on('update online users', (data) {
      if (data is List) {
        _onlineUsers.value = data.map((e) => e.toString()).toList();
        notifyListeners();
      }
    });

    _socket!.on('new-message-notification', (data) {
      _notificationController.add(data);
    });

    _socket!.on('demand-status-updated', (data) {
      if (data is Map<String, dynamic>) {
        _demandUpdateController.add(data);
      }
    });

    _socket!.on('new-demand', (data) {
      if (data is Map<String, dynamic>) {
        _demandUpdateController.add(data);
      }
    });

    _socket!.on('message-status-updated', (data) {
      if (data is Map<String, dynamic>) {
        _messageStatusUpdateController.add(data);
      }
    });

    _socket!.onDisconnect((_) => print('Socket disconnected'));
  }

  void disconnect() {
    _socket?.disconnect();
  }

  IO.Socket? get socket => _socket;

  @override
  void dispose() {
    _notificationController.close();
    _demandUpdateController.close();
    _messageStatusUpdateController.close(); // Close the new stream controller
    super.dispose();
  }
}
