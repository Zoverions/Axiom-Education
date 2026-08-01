import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// Defines the roles in the development-only LAN mesh.
enum MeshRole { teacherNode, studentNode }

/// Development-only LAN transport retained while AXIOM admitted-node causal
/// synchronization is implemented.
///
/// This transport is disabled by default. Enabling it never makes it a trusted
/// authority layer: learner-record access and governed effects must still pass
/// through AXIOM policy, consent, grants, execution, and evidence.
class MeshNetworkService {
  static const int _discoveryPort = 4545;
  static const int _dataPort = 4546;
  static const String _multicastGroup = '224.0.0.1';
  static const int _maxEncryptedMessageBytes = 512 * 1024;
  static const int _maxReceiveBufferBytes = 1024 * 1024;
  static const int _maxCanvasStrokes = 10000;

  final MeshRole role;
  final String classroomPin;

  /// Must be opted into explicitly by development code. Release and governed
  /// builds leave this false and therefore cannot start the legacy transport.
  final bool allowLegacyMesh;

  final String? _meshSecret;
  encrypt.Encrypter? _encrypter;

  @visibleForTesting
  bool isConnected = false;

  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServerSocket;
  Socket? _teacherTcpSocket;
  final List<Socket> _studentSockets = [];
  final Map<Socket, String> _receiveBuffers = {};
  final Map<String, int> _seenNonces = {};

  MeshNetworkService({
    this.role = MeshRole.studentNode,
    required this.classroomPin,
    this.allowLegacyMesh = false,
    String? meshSecret,
  }) : _meshSecret = _normalizeSecret(
         meshSecret ??
             const String.fromEnvironment('MESH_SECRET_KEY', defaultValue: ''),
       );

  static String? _normalizeSecret(String value) {
    final normalized = value.trim();
    return normalized.isEmpty ? null : normalized;
  }

  bool get hasConfiguredTransportKey => _meshSecret != null;

  encrypt.Encrypter _requireEncrypter() {
    final secret = _meshSecret;
    if (secret == null) {
      throw StateError(
        'MESH_SECRET_KEY is required for the development LAN mesh.',
      );
    }

    return _encrypter ??= encrypt.Encrypter(
      encrypt.AES(
        encrypt.Key.fromBase64(
          base64.encode(sha256.convert(utf8.encode(secret)).bytes),
        ),
        mode: encrypt.AESMode.gcm,
      ),
    );
  }

  @visibleForTesting
  String generateDiscoveryPayload() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    const message = 'TEACHER_NODE_HERE';
    final nonce = encrypt.IV.fromSecureRandom(16).base64;
    final dataToSign = '${timestamp}_${message}_$nonce';
    final hmac = Hmac(sha256, utf8.encode(classroomPin));
    final signature = hmac.convert(utf8.encode(dataToSign)).toString();

    return jsonEncode({
      'msg': message,
      'timestamp': timestamp,
      'nonce': nonce,
      'signature': signature,
    });
  }

  @visibleForTesting
  bool verifyDiscoveryPayload(String jsonPayload) {
    try {
      final decoded = jsonDecode(jsonPayload);
      if (decoded is! Map<String, dynamic>) return false;

      final msg = decoded['msg'];
      final timestamp = decoded['timestamp'];
      final nonce = decoded['nonce'];
      final signature = decoded['signature'];

      if (msg != 'TEACHER_NODE_HERE' ||
          timestamp is! int ||
          nonce is! String ||
          signature is! String ||
          nonce.length > 128 ||
          signature.length != 64) {
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      _seenNonces.removeWhere((key, time) => now > time + 30000);

      if (_seenNonces.containsKey(nonce) || (now - timestamp).abs() > 30000) {
        return false;
      }

      final dataToSign = '${timestamp}_${msg}_$nonce';
      final expectedSignature = Hmac(
        sha256,
        utf8.encode(classroomPin),
      ).convert(utf8.encode(dataToSign)).toString();

      if (!_constantTimeEquals(expectedSignature, signature)) return false;

      _seenNonces[nonce] = timestamp;
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool _constantTimeEquals(String left, String right) {
    final leftBytes = utf8.encode(left);
    final rightBytes = utf8.encode(right);
    if (leftBytes.length != rightBytes.length) return false;

    var difference = 0;
    for (var index = 0; index < leftBytes.length; index++) {
      difference |= leftBytes[index] ^ rightBytes[index];
    }
    return difference == 0;
  }

  /// Starts the legacy LAN transport only after explicit development opt-in and
  /// key configuration. Local failure remains a visible offline failure; no
  /// synthetic satellite or global-network success is produced.
  Future<void> startDiscovery() async {
    if (!allowLegacyMesh) {
      throw StateError(
        'Legacy classroom mesh is disabled. Use the AXIOM classroom-sync adapter.',
      );
    }
    if (!hasConfiguredTransportKey) {
      throw StateError(
        'MESH_SECRET_KEY is required before legacy mesh discovery can start.',
      );
    }

    debugPrint('Starting development LAN mesh as ${role.name}...');
    try {
      if (role == MeshRole.teacherNode) {
        await _startTeacherNode();
      } else {
        await _startStudentNode();
      }
      isConnected = true;
    } catch (error) {
      disconnect();
      debugPrint('Development LAN mesh unavailable; remaining offline: $error');
      rethrow;
    }
  }

  Future<InternetAddress> _getLocalIpAddress() async {
    final interfaces = await NetworkInterface.list(
      includeLinkLocal: false,
      type: InternetAddressType.IPv4,
    );
    for (final interface in interfaces) {
      for (final address in interface.addresses) {
        if (!address.isLoopback) return address;
      }
    }
    throw const SocketException('No non-loopback IPv4 interface is available.');
  }

  Future<void> _startTeacherNode() async {
    final localIp = await _getLocalIpAddress();
    _tcpServerSocket = await ServerSocket.bind(localIp, _dataPort);
    _tcpServerSocket!.listen((clientSocket) {
      debugPrint('Development student socket connected.');
      _studentSockets.add(clientSocket);
      _handleIncomingData(clientSocket);
    });

    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      final message = utf8.encode(generateDiscoveryPayload());
      _udpSocket!.send(
        message,
        InternetAddress(_multicastGroup),
        _discoveryPort,
      );
    });

    debugPrint('Development teacher node bound to local interface.');
  }

  Future<void> _startStudentNode() async {
    _udpSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      _discoveryPort,
    );
    _udpSocket!.joinMulticast(InternetAddress(_multicastGroup));

    await for (final event in _udpSocket!) {
      if (event != RawSocketEvent.read) continue;
      final datagram = _udpSocket!.receive();
      if (datagram == null) continue;

      final message = utf8.decode(datagram.data, allowMalformed: false);
      if (!verifyDiscoveryPayload(message)) {
        debugPrint('Ignored unauthenticated or malformed teacher broadcast.');
        continue;
      }

      await _connectToTeacher(datagram.address.address);
      return;
    }

    throw const SocketException('Teacher discovery socket closed.');
  }

  Future<void> _connectToTeacher(String teacherIp) async {
    _teacherTcpSocket = await Socket.connect(teacherIp, _dataPort);
    _handleIncomingData(_teacherTcpSocket!);
    debugPrint('Connected to development teacher TCP channel.');
  }

  @visibleForTesting
  void handleIncomingDataForTest(Socket socket) => _handleIncomingData(socket);

  void _handleIncomingData(Socket socket) {
    _receiveBuffers[socket] = '';
    socket.listen(
      (data) {
        try {
          final chunk = utf8.decode(data, allowMalformed: false);
          var buffer = '${_receiveBuffers[socket] ?? ''}$chunk';
          if (utf8.encode(buffer).length > _maxReceiveBufferBytes) {
            throw const FormatException('Mesh receive buffer limit exceeded.');
          }

          while (true) {
            final newline = buffer.indexOf('\n');
            if (newline < 0) break;

            final message = buffer.substring(0, newline).trim();
            buffer = buffer.substring(newline + 1);
            if (message.isEmpty) continue;
            if (utf8.encode(message).length > _maxEncryptedMessageBytes) {
              throw const FormatException(
                'Encrypted mesh message is too large.',
              );
            }

            try {
              _routePayload(_decodePayload(message));
            } catch (error) {
              debugPrint('Rejected development mesh message: $error');
            }
          }

          _receiveBuffers[socket] = buffer;
        } catch (error) {
          debugPrint('Closing invalid development mesh stream: $error');
          _receiveBuffers.remove(socket);
          socket.destroy();
        }
      },
      onError: (error) {
        debugPrint('Development mesh socket error: $error');
        _receiveBuffers.remove(socket);
        socket.destroy();
      },
      onDone: () {
        _receiveBuffers.remove(socket);
        socket.destroy();
      },
      cancelOnError: true,
    );
  }

  Map<String, dynamic> _decodePayload(String message) {
    final parts = message.split(':');
    if (parts.length != 2) {
      throw const FormatException('Invalid encrypted payload framing.');
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    if (iv.bytes.length != 12) {
      throw const FormatException('AES-GCM nonce must be 12 bytes.');
    }

    final plaintext = _requireEncrypter().decrypt64(parts[1], iv: iv);
    final decoded = jsonDecode(plaintext);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Mesh payload must be a JSON object.');
    }

    _validatePayload(decoded);
    return decoded;
  }

  void _validatePayload(Map<String, dynamic> payload) {
    final type = payload['type'];
    if (type == 'CANVAS_SYNC') {
      final strokes = payload['strokes'];
      if (strokes is! List || strokes.length > _maxCanvasStrokes) {
        throw const FormatException('Invalid CANVAS_SYNC payload.');
      }
      return;
    }

    if (type == 'CREDENTIAL_GOSSIP') {
      if (payload['id'] is! String || payload['payload'] is! Map) {
        throw const FormatException('Invalid CREDENTIAL_GOSSIP payload.');
      }
      return;
    }

    throw const FormatException('Unsupported development mesh message type.');
  }

  void _routePayload(Map<String, dynamic> payload) {
    switch (payload['type']) {
      case 'CANVAS_SYNC':
        debugPrint('Accepted bounded CANVAS_SYNC development message.');
        break;
      case 'CREDENTIAL_GOSSIP':
        debugPrint('Accepted bounded CREDENTIAL_GOSSIP development message.');
        break;
    }
  }

  String _encodePayload(Map<String, dynamic> payload) {
    _validatePayload(payload);
    final plaintext = jsonEncode(payload);
    if (utf8.encode(plaintext).length > _maxEncryptedMessageBytes) {
      throw const FormatException('Mesh payload is too large.');
    }

    final iv = encrypt.IV.fromSecureRandom(12);
    final encrypted = _requireEncrypter().encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}\n';
  }

  @visibleForTesting
  String encodePayloadForTest(Map<String, dynamic> payload) =>
      _encodePayload(payload);

  @visibleForTesting
  Map<String, dynamic> decodePayloadForTest(String message) =>
      _decodePayload(message.trim());

  @visibleForTesting
  void sendOverTcp(Map<String, dynamic> payload) => _sendOverTcp(payload);

  void _sendOverTcp(Map<String, dynamic> payload) {
    final message = _encodePayload(payload);

    if (role == MeshRole.studentNode) {
      _teacherTcpSocket?.write(message);
      return;
    }

    for (final socket in List<Socket>.from(_studentSockets)) {
      try {
        socket.write(message);
      } catch (error) {
        debugPrint('Dropping failed development student socket: $error');
        _studentSockets.remove(socket);
        _receiveBuffers.remove(socket);
        socket.destroy();
      }
    }
  }

  Future<void> gossipCredential(
    String credentialId,
    Map<String, dynamic> data,
  ) async {
    if (!isConnected) throw StateError('Not connected to mesh.');
    sendOverTcp({
      'type': 'CREDENTIAL_GOSSIP',
      'id': credentialId,
      'payload': data,
    });
  }

  Future<void> syncCanvasState(List<Map<String, dynamic>> strokes) async {
    if (!isConnected) return;
    if (strokes.length > _maxCanvasStrokes) {
      throw const FormatException('Canvas stroke limit exceeded.');
    }
    sendOverTcp({'type': 'CANVAS_SYNC', 'strokes': strokes});
  }

  void disconnect() {
    isConnected = false;
    _udpSocket?.close();
    _udpSocket = null;
    _tcpServerSocket?.close();
    _tcpServerSocket = null;
    _teacherTcpSocket?.destroy();
    _teacherTcpSocket = null;
    for (final socket in _studentSockets) {
      socket.destroy();
    }
    _studentSockets.clear();
    _receiveBuffers.clear();
  }
}
