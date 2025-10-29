import 'dart:io';
import 'package:sip_ua/src/transports/tls_socket_impl.dart';

import '../../sip_ua.dart';
import '../logger.dart';
import 'socket_interface.dart';

class SIPUATlsSocket extends SIPUASocketInterface {
  SIPUATlsSocket(String host, String port,
      {required int messageDelay,
      TcpSocketSettings? tcpSocketSettings,
      int? weight})
      : _messageDelay = messageDelay {

    String transportScheme = 'tls';
    _weight = weight;
    _host = host;
    _port = port;

    _sip_uri = '$_tlsSocketProtocol:$host:$port;transport=$transportScheme';
    _via_transport = transportScheme.toUpperCase();
    _tcpSocketSettings = tcpSocketSettings ?? TcpSocketSettings();
  }

  final int _messageDelay;

  String? _host;
  String? _port;
  String? _sip_uri;
  late String _via_transport;
  final String _tlsSocketProtocol = 'sip';
  SIPUATlsSocketImpl? _tlsSocketImpl;
  bool _closed = false;
  bool _connected = false;
  bool _connecting = false;
  int? _weight;
  int? status;
  late TcpSocketSettings _tcpSocketSettings;

  @override
  String get via_transport => _via_transport;

  @override
  set via_transport(String value) {
    _via_transport = value.toUpperCase();
  }

  @override
  int? get weight => _weight;

  @override
  String? get sip_uri => _sip_uri;

  String? get host => _host;

  String? get port => _port;

  @override
  void connect() async {
    print('connect()');

    if (_host == null) {
      throw AssertionError('Invalid argument: _host');
    }
    if (_port == null) {
      throw AssertionError('Invalid argument: _port');
    }

    if (isConnected()) {
      print('TLSSocket $_host:$_port is already connected');
      return;
    } else if (isConnecting()) {
      print('TLSSocket $_host:$_port is connecting');
      return;
    }
    if (_tlsSocketImpl != null) {
      disconnect();
    }
    print('connecting to TLSSocket $_host:$_port');
    _connecting = true;
    try {
      _tlsSocketImpl =
          SIPUATlsSocketImpl(_messageDelay, _host ?? '0.0.0.0', _port ?? '5061');

      _tlsSocketImpl!.onOpen = () {
        _closed = false;
        _connected = true;
        _connecting = false;
        print('TLS Socket is now connected');
        _onOpen();
      };

      _tlsSocketImpl!.onData = (dynamic data) {
        _onMessage(data);
      };

      _tlsSocketImpl!.onClose = (int? closeCode, String? closeReason) {
        print('Closed [$closeCode, $closeReason]!');
        _connected = false;
        _connecting = false;
        _onClose(true, closeCode, closeReason);
      };

      _tlsSocketImpl!.connect(
          protocols: <String>[_tlsSocketProtocol],
          tcpSocketSettings: _tcpSocketSettings);
    } catch (e, s) {
      logger.e(e.toString(), stackTrace: s);
      _connected = false;
      _connecting = false;
      print('TLSSocket error: $e');
    }
  }

  @override
  void disconnect() {
    print('disconnect()');
    if (_closed) return;
    _closed = true;
    _connected = false;
    _connecting = false;
    _onClose(true, 0, 'Client sent disconnect');
    try {
      if (_tlsSocketImpl != null) {
        _tlsSocketImpl!.close();
      }
    } catch (error) {
      logger.e('close() | error closing the TLSSocket: $error');
    }
  }

  @override
  bool send(dynamic message) {
    print('send() $message');
    if (_closed) {
      throw 'transport closed';
    }
    try {
      _tlsSocketImpl!.send(message);
      return true;
    } catch (error) {
      logger.e('send() | error sending message: $error');
      rethrow;
    }
  }

  @override
  bool isConnected() => _connected;

  void _onOpen() {
    print('TLSSocket $_host:$port connected');
    onconnect!();
  }

  void _onClose(bool wasClean, int? code, String? reason) {
    print('TLSSocket $_host:$port closed $reason');
    if (wasClean == false) {
      print('TLSSocket abrupt disconnection');
    }
    ondisconnect!(this, !wasClean, code, reason);
  }

  void _onMessage(dynamic data) {
    print('Received TLSSocket data');
    if (data != null) {
      if (data.toString().trim().isNotEmpty) {
        ondata!(data);
      } else {
        print('Received and ignored empty packet');
      }
    }
  }

  @override
  bool isConnecting() => _connecting;

  @override
  String? get url {
    if (_host == null || _port == null) {
      return null;
    }
    return '$_host:$_port';
  }
}
