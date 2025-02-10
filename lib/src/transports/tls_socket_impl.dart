import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../logger.dart';
import '../sip_ua_helper.dart';

typedef OnMessageCallback = void Function(dynamic msg);
typedef OnCloseCallback = void Function(int? code, String? reason);
typedef OnOpenCallback = void Function();

class SIPUATlsSocketImpl {
  SIPUATlsSocketImpl(this.messageDelay, this._host, this._port);

  final String _host;
  final String _port;

  /// Use SecureSocket for TLS connections.
  SecureSocket? _socket;
  OnOpenCallback? onOpen;
  OnMessageCallback? onData;
  OnCloseCallback? onClose;
  final int messageDelay;

  /// Establishes a secure TLS connection.
  void connect({
    Iterable<String>? protocols,
    required TcpSocketSettings tcpSocketSettings,
  }) async {
    handleQueue();
    logger.i('connect TLS $_host:$_port');
    try {
      _socket = await SecureSocket.connect(
        _host,
        int.parse(_port),
        onBadCertificate: (X509Certificate certificate) {
          // WARNING: Accepting bad certificates should only be done for testing.
          return tcpSocketSettings.allowBadCertificate;
        },
      );

      // Notify that the connection is open.
      onOpen?.call();

      // Listen for incoming data.
      _socket!.listen(
        (dynamic data) {
          onData?.call(data);
        },
        onDone: () {
          onClose?.call(0, 'Connection closed');
        },
        onError: (dynamic error) {
          onClose?.call(500, error.toString());
        },
      );
    } catch (e) {
      onClose?.call(500, e.toString());
    }
  }

  /// A StreamController queue to delay outgoing messages.
  final StreamController<dynamic> queue = StreamController<dynamic>.broadcast();

  void handleQueue() async {
    queue.stream.asyncMap((dynamic event) async {
      await Future<void>.delayed(Duration(milliseconds: messageDelay));
      return event;
    }).listen((dynamic event) async {
      // Convert the string message to bytes.
      _socket!.add(event.codeUnits);
      logger.d('send: \n\n$event');
    });
  }

  /// Sends data over the secure socket.
  void send(dynamic data) {
    if (_socket != null) {
      queue.add(data);
    }
  }

  /// Closes the secure socket.
  void close() {
    _socket?.close();
  }
}
