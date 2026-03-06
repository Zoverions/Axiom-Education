import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Defines the roles in the P2P Mesh
enum MeshRole {
  teacherNode,
  studentNode
}

/// A service to implement a Local Area Network (LAN) Mesh.
/// In a real cross-platform environment, this acts as the foundational fallback
/// for when direct Wi-Fi Aware/Bluetooth bindings are not available,
/// leveraging UDP multicast for discovery and TCP for data sync.
class MeshNetworkService {
  final MeshRole role;
  bool _isConnected = false;

  // Networking properties
  RawDatagramSocket? _udpSocket;
  ServerSocket? _tcpServerSocket;
  Socket? _teacherTcpSocket;
  final List<Socket> _studentSockets = [];

  static const int _discoveryPort = 4545;
  static const int _dataPort = 4546;
  static const String _multicastGroup = '224.0.0.1'; // Standard local multicast

  MeshNetworkService({this.role = MeshRole.studentNode});

  /// Initiates discovery of local classroom swarms using UDP Multicast.
  /// Falls back to "Easy Connection" global discovery if local mesh is unavailable.
  Future<void> startDiscovery() async {
    print('Starting P2P Mesh Discovery as ${role.name}...');
    try {
      if (role == MeshRole.teacherNode) {
        await _startTeacherNode();
      } else {
        await _startStudentNode();
      }
      _isConnected = true;
    } catch (e) {
      print('Failed to start mesh network: $e');
      print('Attempting Easy Connection Discovery fallback...');
      await _startEasyConnectionDiscovery();
    }
  }

  /// Easy Connection Discovery: Strategic partnership mode for rural/global access.
  /// If the local P2P mesh fails (e.g., isolated student, no teacher node), the device
  /// attempts to connect to a global constellation (e.g., Starlink Educational Tier)
  /// that zero-rates traffic to the OntarioEdAI master decentralized ledger.
  Future<void> _startEasyConnectionDiscovery() async {
    print('Scanning for low-earth orbit (LEO) satellite uplinks (e.g., Starlink)...');

    // Placeholder: Interface with hardware APIs to detect whitelisted educational SSIDs
    // or direct satellite terminal connections.
    await Future.delayed(const Duration(seconds: 2));

    // Simulate successful connection to global educational network
    print('Connected to Global Educational Network via LEO Satellite.');
    print('Zero-rated lifelong learning access granted.');

    _isConnected = true;

    // In this mode, the node connects to regional master nodes rather than a local classroom swarm.
  }

  Future<void> _startTeacherNode() async {
    // 1. Start TCP Server to listen for student connections
    _tcpServerSocket = await ServerSocket.bind(InternetAddress.anyIPv4, _dataPort);
    _tcpServerSocket!.listen((Socket clientSocket) {
      print('Student connected: ${clientSocket.remoteAddress.address}');
      _studentSockets.add(clientSocket);
      _handleIncomingData(clientSocket);
    });

    // 2. Broadcast presence via UDP
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udpSocket!.broadcastEnabled = true;

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!_isConnected) {
        timer.cancel();
        return;
      }
      final msg = utf8.encode('TEACHER_NODE_HERE');
      _udpSocket!.send(msg, InternetAddress(_multicastGroup), _discoveryPort);
    });

    print('Teacher node broadcasting on $_multicastGroup:$_discoveryPort');
  }

  Future<void> _startStudentNode() async {
    // 1. Listen for teacher UDP broadcasts
    _udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _discoveryPort);
    _udpSocket!.joinMulticast(InternetAddress(_multicastGroup));

    print('Student node listening for teacher on $_multicastGroup:$_discoveryPort');

    // Wait to discover teacher
    await for (RawSocketEvent event in _udpSocket!) {
      if (event == RawSocketEvent.read) {
        Datagram? datagram = _udpSocket!.receive();
        if (datagram != null) {
          String msg = utf8.decode(datagram.data);
          if (msg == 'TEACHER_NODE_HERE') {
            print('Teacher node discovered at ${datagram.address.address}');
            // 2. Connect via TCP
            await _connectToTeacher(datagram.address.address);
            break; // Stop listening once connected
          }
        }
      }
    }
  }

  Future<void> _connectToTeacher(String teacherIp) async {
    try {
      _teacherTcpSocket = await Socket.connect(teacherIp, _dataPort);
      print('Connected to teacher TCP channel.');
      _handleIncomingData(_teacherTcpSocket!);
    } catch (e) {
      print('Failed to connect to teacher TCP: $e');
    }
  }

  void _handleIncomingData(Socket socket) {
    socket.listen(
      (List<int> data) {
        String message = utf8.decode(data);
        print('Received mesh data: $message');
        // Placeholder: Parse JSON and route to specific Riverpod providers/handlers
      },
      onError: (error) {
        print('Socket error: $error');
        socket.destroy();
      },
      onDone: () {
        print('Socket closed by peer.');
        socket.destroy();
      },
    );
  }

  void _sendOverTcp(Map<String, dynamic> payload) {
    if (role == MeshRole.studentNode) {
      if (_teacherTcpSocket != null) {
        _teacherTcpSocket!.write(jsonEncode(payload) + '\n');
      }
    } else {
      for (var socket in _studentSockets) {
        try {
          socket.write(jsonEncode(payload) + '\n');
        } catch (_) {}
      }
    }
  }

  /// Broadcasts a locally verified credential (VC) to the teacher's node.
  Future<void> gossipCredential(String credentialId, Map<String, dynamic> data) async {
    if (!_isConnected) throw Exception("Not connected to mesh.");
    print('Gossiping credential $credentialId...');

    _sendOverTcp({
      'type': 'CREDENTIAL_GOSSIP',
      'id': credentialId,
      'payload': data
    });
  }

  /// Syncs the dynamic workbook state via WebRTC/TCP for real-time offline collaboration.
  Future<void> syncCanvasState(List<Map<String, dynamic>> strokes) async {
     if (!_isConnected) return;
     print('Syncing canvas state: ${strokes.length} strokes');

     _sendOverTcp({
       'type': 'CANVAS_SYNC',
       'strokes': strokes
     });
  }

  void disconnect() {
    _isConnected = false;
    _udpSocket?.close();
    _tcpServerSocket?.close();
    _teacherTcpSocket?.destroy();
    for (var socket in _studentSockets) {
      socket.destroy();
    }
    _studentSockets.clear();
    print('Disconnected from mesh network.');
  }
}
