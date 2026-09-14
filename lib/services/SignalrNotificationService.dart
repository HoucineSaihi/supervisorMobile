import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:supervisormobile/services/DioService.dart';

typedef NotificationReceivedCallback = void Function(Map<String, dynamic> payload);

/// Wraps a single SignalR hub connection to the backend's NotificationHub so
/// the app receives execution-review events in real time while it is open.
/// Firebase (PushNotificationService) covers the closed/backgrounded case.
class SignalrNotificationService {
  SignalrNotificationService._();

  static final SignalrNotificationService instance = SignalrNotificationService._();

  final _storage = const FlutterSecureStorage();

  HubConnection? _connection;
  NotificationReceivedCallback? onNotificationReceived;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect() async {
    print('🔌 SignalrNotificationService.connect() called');
    if (_connection != null) {
      print('🔌 SignalrNotificationService: already have a connection, skipping');
      return;
    }

    final token = await _storage.read(key: 'token');
    if (token == null || token.isEmpty) {
      print('🔌 SignalrNotificationService: no token in secure storage, aborting');
      return;
    }

    final hubUrl = '${DioService.assetsBaseUrl}/hubs/notifications?access_token=$token';
    print('🔌 SignalrNotificationService: connecting to $hubUrl');

    final connection = HubConnectionBuilder()
        .withUrl(
          hubUrl,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => token,
          ),
        )
        .withAutomaticReconnect()
        .build();

    connection.on('notificationReceived', (arguments) {
      print('🔔 SignalrNotificationService: notificationReceived event: $arguments');
      if (arguments == null || arguments.isEmpty) return;
      final payload = arguments.first;
      if (payload is Map) {
        onNotificationReceived?.call(Map<String, dynamic>.from(payload));
      }
    });

    connection.onclose(({error}) {
      print('🔌 SignalrNotificationService: connection closed. error=$error');
    });

    connection.onreconnecting(({error}) {
      print('🔌 SignalrNotificationService: reconnecting. error=$error');
    });

    connection.onreconnected(({connectionId}) {
      print('🔌 SignalrNotificationService: reconnected. connectionId=$connectionId');
    });

    _connection = connection;

    try {
      await connection.start();
      print('✅ SignalrNotificationService: connected! state=${connection.state}');
    } catch (e, stack) {
      print('❌ SignalrNotificationService: failed to connect: $e');
      print(stack);
      _connection = null;
    }
  }

  Future<void> disconnect() async {
    try {
      await _connection?.stop();
    } catch (_) {
      // Ignore errors while tearing down the connection.
    } finally {
      _connection = null;
    }
  }
}
