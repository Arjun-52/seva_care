import 'dart:async';
import '../config/env.dart';
import 'api_service.dart';

/// WebSocket service for real-time updates using Socket.IO protocol.
///
/// Events:
///   vitals:update   — Real-time vitals from IoT devices
///   alert:new       — New emergency alert
///   alert:update    — Alert status change
///   careLog:update  — Care log status change
///   location:update — GPS location from smartwatch
///   device:status   — IoT device online/offline
///
/// Usage:
///   final ws = WebSocketService();
///   ws.connect();
///   ws.onVitalsUpdate((data) => updateUI(data));
///   ws.subscribeSenior('senior-id');
class WebSocketService {
  // ignore: unused_field
  dynamic _socket;
  bool _connected = false;
  final _controllers = <String, StreamController<Map<String, dynamic>>>{};

  bool get isConnected => _connected;

  /// Connect to the WebSocket server
  void connect() {
    // In production, use socket_io_client package:
    //
    // import 'package:socket_io_client/socket_io_client.dart' as IO;
    //
    // _socket = IO.io(Env.wsUrl, IO.OptionBuilder()
    //   .setTransports(['websocket'])
    //   .setAuth({'token': ApiService._accessToken})
    //   .build());
    //
    // _socket.onConnect((_) {
    //   _connected = true;
    //   print('WebSocket connected');
    // });
    //
    // _socket.on('vitals:update', (data) {
    //   _emit('vitals:update', Map<String, dynamic>.from(data));
    // });
    //
    // _socket.on('alert:new', (data) {
    //   _emit('alert:new', Map<String, dynamic>.from(data));
    // });
    //
    // etc...

    _connected = true;
  }

  /// Subscribe to updates for a specific senior
  void subscribeSenior(String seniorId) {
    // _socket?.emit('subscribe:senior', seniorId);
  }

  /// Subscribe to multiple seniors at once
  void subscribeSeniors(List<String> seniorIds) {
    // _socket?.emit('subscribe:seniors', seniorIds);
  }

  /// Unsubscribe from senior updates
  void unsubscribeSenior(String seniorId) {
    // _socket?.emit('unsubscribe:senior', seniorId);
  }

  // ─── Event Streams ─────────────────────────

  Stream<Map<String, dynamic>> on(String event) {
    _controllers[event] ??= StreamController<Map<String, dynamic>>.broadcast();
    return _controllers[event]!.stream;
  }

  Stream<Map<String, dynamic>> get onVitalsUpdate => on('vitals:update');
  Stream<Map<String, dynamic>> get onNewAlert => on('alert:new');
  Stream<Map<String, dynamic>> get onAlertUpdate => on('alert:update');
  Stream<Map<String, dynamic>> get onCareLogUpdate => on('careLog:update');
  Stream<Map<String, dynamic>> get onLocationUpdate => on('location:update');
  Stream<Map<String, dynamic>> get onDeviceStatus => on('device:status');

  void _emit(String event, Map<String, dynamic> data) {
    _controllers[event]?.add(data);
  }

  /// Disconnect from WebSocket server
  void disconnect() {
    // _socket?.disconnect();
    _connected = false;
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Dispose all resources
  void dispose() {
    disconnect();
  }
}
