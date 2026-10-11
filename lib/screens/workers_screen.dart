import 'package:flutter/material.dart';

import '../api/client.dart';
import '../main.dart';
import '../widgets.dart';

class WorkersScreen extends StatefulWidget {
  const WorkersScreen({super.key});

  @override
  State<WorkersScreen> createState() => _WorkersScreenState();
}

class _WorkersScreenState extends State<WorkersScreen> {
  final _name = TextEditingController(text: 'Planning lab GPU');
  final _publicId = TextEditingController();
  final _code = TextEditingController();
  String? _shownOnce;
  String? _error;
  List<Map<String, dynamic>> _workers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final body = await AppScope.of(context).api.send('GET', '/api/v1/workers');
      setState(() => _workers = ((body?['workers'] as List?) ?? []).cast<Map<String, dynamic>>());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    return StreetScaffold(
      palette: palette,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreetHeader(title: 'GPU servers', palette: palette),
          const SizedBox(height: 8),
          Text('The PC connects outbound to this API. The phone never opens ComfyUI\'s port. Pair with the server id and a one-time code.', style: TextStyle(color: palette.muted)),
          const SizedBox(height: 14),
          StreetField(label: 'Server name', controller: _name, palette: palette),
          const SizedBox(height: 12),
          StreetButton(label: 'Register this account\'s server', palette: palette, onPressed: _register),
          if (_shownOnce != null) ...[
            const SizedBox(height: 12),
            SelectableText(_shownOnce!, style: TextStyle(color: palette.error)),
          ],
          const SizedBox(height: 12),
          StreetField(label: 'Server id', controller: _publicId, palette: palette),
          const SizedBox(height: 12),
          StreetField(label: 'Pairing code', controller: _code, palette: palette),
          const SizedBox(height: 12),
          StreetButton(label: 'Pair', palette: palette, onPressed: _pair),
          const SizedBox(height: 12),
          ..._workers.map((worker) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${worker['friendlyName']} · ${worker['publicId']} · ${worker['status']}', style: TextStyle(color: palette.text)),
                  const SizedBox(height: 6),
                  StreetButton(
                    label: 'Unpair ${worker['publicId']}',
                    secondary: true,
                    palette: palette,
                    onPressed: () => _unpair('${worker['publicId']}'),
                  ),
                ]),
              )),
          if (_error != null) Text(_error!, style: TextStyle(color: palette.error)),
        ],
      ),
    );
  }

  Future<void> _register() async {
    setState(() => _error = null);
    try {
      final api = AppScope.of(context).api;
      final created = await api.send('POST', '/api/v1/workers/register', jsonBody: {'friendlyName': _name.text.trim()});
      final publicId = '${created?['publicId']}';
      final challenge = await api.send('POST', '/api/v1/workers/$publicId/pairing-challenges');
      _publicId.text = publicId;
      setState(() {
        _shownOnce = 'Device token, shown once: ${created?['deviceToken']}\nServer id $publicId\nPairing code ${challenge?['pairingCode']}';
      });
      await _load();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _pair() async {
    setState(() => _error = null);
    try {
      await AppScope.of(context).api.send('POST', '/api/v1/workers/pair', jsonBody: {
        'workerId': _publicId.text.trim(),
        'pairingCode': _code.text.trim(),
      });
      await _load();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  Future<void> _unpair(String publicId) async {
    setState(() => _error = null);
    try {
      await AppScope.of(context).api.send('POST', '/api/v1/workers/$publicId/unpair');
      setState(() => _shownOnce = null);
      await _load();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }
}
