import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_table_screen.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});
  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _db = FirebaseDatabase.instance.ref();
  String? _roomCode;
  StreamSubscription<DatabaseEvent>? _roomSub;
  List<String> _players = [];
  bool _loading = false;
  String? _error;

  String _generateCode() {
    final rand = Random();
    return List.generate(4, (_) => rand.nextInt(10)).join();
  }

  Future<void> _createRoom() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسمك أولاً');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _loading = false; _error = 'خطأ في تسجيل الدخول، حاول لاحقاً'; });
      return;
    }
    final code = _generateCode();
    await _db.child('rooms/$code').set({
      'players': {uid: name},
      'createdAt': ServerValue.timestamp,
      'status': 'waiting',
    });
    _listenToRoom(code);
  }

  Future<void> _joinRoom() async {
    final name = _nameController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      setState(() => _error = 'اكتب اسمك وكود الغرفة');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() { _loading = false; _error = 'خطأ في تسجيل الدخول، حاول لاحقاً'; });
      return;
    }
    final snapshot = await _db.child('rooms/$code').get();
    if (!snapshot.exists) {
      setState(() { _loading = false; _error = 'الغرفة غير موجودة'; });
      return;
    }
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(data['players'] ?? {});
    if (players.length >= 4) {
      setState(() { _loading = false; _error = 'الغرفة ممتلئة'; });
      return;
    }
    await _db.child('rooms/$code/players/$uid').set(name);
    _listenToRoom(code);
  }

  void _listenToRoom(String code) {
    setState(() { _roomCode = code; _loading = false; });
    _roomSub = _db.child('rooms/$code/players').onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() => _players = data.values.map((v) => v.toString()).toList());
      if (_players.length == 4) {
        _roomSub?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const GameTableScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('مارياس - غرفة الانتظار')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _roomCode == null ? _buildJoinForm() : _buildWaitingRoom(),
      ),
    );
  }

  Widget _buildJoinForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'اسمك', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _codeController,
          decoration: const InputDecoration(labelText: 'كود الغرفة (للانضمام)', border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        if (_error != null) Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(_error!, style: const TextStyle(color: Colors.red)),
        ),
        if (_loading) const Center(child: CircularProgressIndicator())
        else Column(children: [
          ElevatedButton(onPressed: _createRoom, child: const Padding(padding: EdgeInsets.all(12), child: Text('إنشاء غرفة جديدة'))),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _joinRoom, child: const Padding(padding: EdgeInsets.all(12), child: Text('انضمام لغرفة'))),
        ]),
      ],
    );
  }

  Widget _buildWaitingRoom() {
    return Column(
      children: [
        const Text('كود الغرفة', style: TextStyle(fontSize: 16)),
        Text(_roomCode!, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 8)),
        const SizedBox(height: 24),
        Text('اللاعبون (${_players.length}/4)', style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 12),
        ..._players.map((p) => ListTile(leading: const Icon(Icons.person), title: Text(p))),
        const SizedBox(height: 24),
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        const Text('في انتظار انضمام باقي اللاعبين...'),
      ],
    );
  }
}
