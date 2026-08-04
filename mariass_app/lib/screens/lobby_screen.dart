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
  String? _hostUid;
  bool get _isHost => _hostUid != null && _hostUid == FirebaseAuth.instance.currentUser?.uid;

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
      'players': {uid: {'name': name, 'joinedAt': ServerValue.timestamp}},
      'host': uid,
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
    await _db.child('rooms/$code/players/$uid').set({'name': name, 'joinedAt': ServerValue.timestamp});
    _listenToRoom(code);
  }

  void _listenToRoom(String code) {
    setState(() { _roomCode = code; _loading = false; });
    _db.child('rooms/$code/host').get().then((snap) {
      if (snap.exists && mounted) setState(() => _hostUid = snap.value.toString());
    });
    _roomSub = _db.child('rooms/$code/players').onValue.listen((event) {
      if (!event.snapshot.exists) return;
      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      setState(() => _players = data.entries
          .map((e) => (Map<String, dynamic>.from(e.value as Map))['name'].toString())
          .toList());
      if (data.length == 4) {
        _roomSub?.cancel();
        final sortedUids = data.keys.toList()
          ..sort((a, b) {
            final ta = (Map<String, dynamic>.from(data[a] as Map)['joinedAt'] ?? 0) as int;
            final tb = (Map<String, dynamic>.from(data[b] as Map)['joinedAt'] ?? 0) as int;
            return ta.compareTo(tb);
          });
        final myUid = FirebaseAuth.instance.currentUser!.uid;
        final myIndex = sortedUids.indexOf(myUid);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => GameTableScreen(
            roomCode: code,
            myIndex: myIndex,
            playerUids: sortedUids,
          )),
        );
      }
    });
  }

  Future<void> _startWithBots() async {
    final code = _roomCode;
    if (code == null) return;
    final snapshot = await _db.child('rooms/$code/players').get();
    if (!snapshot.exists) return;
    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final missing = 4 - data.length;
    if (missing <= 0) return;
    final updates = <String, dynamic>{};
    final base = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < missing; i++) {
      final botId = 'bot_${base}_$i';
      updates['rooms/$code/players/$botId'] = {
        'name': 'بوت ${i + 1}',
        'joinedAt': base + i,
        'isBot': true,
      };
    }
    await _db.update(updates);
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
        if (_isHost && _players.isNotEmpty && _players.length < 4) ...[
          ElevatedButton(
            onPressed: _startWithBots,
            child: Text('ابدأ اللعب مع ${4 - _players.length} بوت'),
          ),
          const SizedBox(height: 12),
        ],
        const CircularProgressIndicator(),
        const SizedBox(height: 12),
        const Text('في انتظار انضمام باقي اللاعبين...'),
      ],
    );
  }
}
