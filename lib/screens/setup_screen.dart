import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../api/client.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets.dart';
import 'studio_screen.dart';
import 'workers_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _title = TextEditingController(text: 'Untitled street');
  String _mode = 'individual';
  bool _demo = true;
  String _processing = 'demo';
  String _provider = 'mock';
  String? _workerId;
  String _policy = 'automatic';
  List<Map<String, dynamic>> _providers = [];
  List<Map<String, dynamic>> _workers = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    try {
      final providers = await api.send('GET', '/api/v1/providers/image');
      final workers = await api.send('GET', '/api/v1/workers');
      setState(() {
        _providers = ((providers?['image'] as List?) ?? []).cast<Map<String, dynamic>>();
        _workers = ((workers?['workers'] as List?) ?? []).cast<Map<String, dynamic>>();
      });
    } catch (_) {}
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_processing == 'hosted_gpu') {
        final hosted = _providers.cast<Map<String, dynamic>?>().firstWhere(
              (item) => item?['id'] == 'comfyui_hosted',
              orElse: () => null,
            );
        if (hosted?['configured'] != true) {
          setState(() => _error = 'Configure hosted GPU to enable.');
          return;
        }
      }
      final api = AppScope.of(context).api;
      if (_demo) {
        final session = await api.send('POST', '/api/v1/sessions', jsonBody: {
          'title': _title.text.trim(),
          'demo': true,
          'mode': 'individual',
        });
        if (!mounted) return;
        _open('${session?['sessionId']}');
        return;
      }
      final picked = await _pickPhoto();
      if (picked == null || !mounted) return;
      final consent = await _confirmConsent(picked);
      if (consent != true || !mounted) return;
      final session = await api.send('POST', '/api/v1/sessions', jsonBody: {
        'title': _title.text.trim(),
        'mode': _mode,
        'processingMode': _processing,
        'provider': _provider,
        'workerId': _workerId,
        'generationPolicy': _policy,
        'demo': false,
      });
      final sessionId = '${session?['sessionId']}';
      final presign = await api.send('POST', '/api/v1/sessions/$sessionId/source-upload');
      await api.send('PUT', '${presign?['uploadPath']}', bytes: picked, contentType: 'image/jpeg');
      await api.send('POST', '/api/v1/sessions/$sessionId/source-upload/complete', jsonBody: {
        'assetId': presign?['assetId'],
        'consent': true,
      });
      if (!mounted) return;
      _open(sessionId);
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Uint8List?> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.photo_camera), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
            ListTile(leading: const Icon(Icons.photo_library), title: const Text('Library'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ],
        ),
      ),
    );
    if (source == null) return null;
    final file = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 1600);
    return file?.readAsBytes();
  }

  Future<bool?> _confirmConsent(Uint8List bytes) {
    var consent = false;
    return showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Review photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.memory(bytes, height: 180, fit: BoxFit.contain),
              const SizedBox(height: 12),
              Row(
                children: [
                  Switch(value: consent, onChanged: (value) => setLocal(() => consent = value)),
                  const Expanded(child: Text('I consent to processing this photo with the selected provider. EXIF location data is stripped on the server. This is not a surveyed design.')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Retake')),
            TextButton(onPressed: consent ? () => Navigator.pop(context, true) : null, child: const Text('Use this photo')),
          ],
        ),
      ),
    );
  }

  void _open(String sessionId) {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => StudioScreen(sessionId: sessionId)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    return StreetScaffold(
      palette: palette,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          StreetHeader(title: 'New street design', palette: palette),
          const SizedBox(height: 14),
          StreetField(label: 'Title', controller: _title, palette: palette),
          const SizedBox(height: 14),
          Text('Who is designing?', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: StreetButton(label: 'Just me', secondary: _mode != 'individual', palette: palette, onPressed: () => setState(() => _mode = 'individual'))),
            const SizedBox(width: 8),
            Expanded(child: StreetButton(label: 'A group', secondary: _mode != 'collaborative', palette: palette, onPressed: () => setState(() {
              _mode = 'collaborative';
              _demo = false;
              _policy = 'batched';
              _processing = 'cloud_api';
            }))),
          ]),
          const SizedBox(height: 14),
          Text('Processing', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Material(
            color: palette.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: palette.border),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openProcessing(palette),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_processingLabel(), style: TextStyle(color: palette.text, fontWeight: FontWeight.w600, fontSize: 16)),
                          const SizedBox(height: 4),
                          Text(_processingDetail(), style: TextStyle(color: palette.muted)),
                        ],
                      ),
                    ),
                    Icon(Icons.unfold_more, color: palette.primary),
                  ],
                ),
              ),
            ),
          ),
          if (_mode == 'collaborative') ...[
            const SizedBox(height: 12),
            Text('Group generation', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            StreetButton(label: 'After each idea', secondary: _policy != 'automatic', palette: palette, onPressed: () => setState(() => _policy = 'automatic')),
            const SizedBox(height: 8),
            StreetButton(label: 'Batch ideas', secondary: _policy != 'batched', palette: palette, onPressed: () => setState(() => _policy = 'batched')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: palette.error)),
          ],
          const SizedBox(height: 14),
          StreetButton(label: _busy ? 'Please wait' : (_demo ? 'Open sample' : 'Take or choose a photo'), palette: palette, onPressed: _busy ? null : _start),
        ],
      ),
    );
  }

  String _processingLabel() {
    if (_demo) return 'Sample street';
    if (_processing == 'hosted_gpu') return 'Hosted GPU';
    if (_processing == 'private_gpu') {
      final worker = _workers.cast<Map<String, dynamic>?>().where((item) => item?['workerId'] == _workerId).firstOrNull;
      return worker == null ? 'Private GPU' : '${worker['friendlyName']}';
    }
    final provider = _providers.cast<Map<String, dynamic>?>().where((item) => item?['id'] == _provider).firstOrNull;
    return '${provider?['label'] ?? 'Cloud provider'}';
  }

  String _processingDetail() {
    if (_demo) return 'DEMO / MOCK RESULT. No photo leaves this demo.';
    if (_processing == 'hosted_gpu') return _hostedNotice();
    if (_processing == 'private_gpu') {
      final worker = _workers.cast<Map<String, dynamic>?>().where((item) => item?['workerId'] == _workerId).firstOrNull;
      return worker == null ? 'Choose a paired server.' : '${worker['publicId']} · ${worker['status']}';
    }
    final provider = _providers.cast<Map<String, dynamic>?>().where((item) => item?['id'] == _provider).firstOrNull;
    if (provider?['configured'] == true) return 'Configured on the server.';
    return '${provider?['notice'] ?? ''}';
  }

  String _hostedNotice() {
    final hosted = _providers.cast<Map<String, dynamic>?>().where((item) => item?['id'] == 'comfyui_hosted').firstOrNull;
    return '${hosted?['notice'] ?? 'Configure hosted GPU to enable.'}';
  }

  Future<void> _openProcessing(AppPalette palette) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.surface,
        title: Row(
          children: [
            Expanded(child: Text('Processing', style: TextStyle(color: palette.text))),
            IconButton(onPressed: () => Navigator.pop(dialogContext), icon: Icon(Icons.close, color: palette.text)),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _choice(palette, 'Sample street', 'DEMO / MOCK RESULT. No photo leaves this demo.', _demo, () {
                  setState(() {
                    _demo = true;
                    _processing = 'demo';
                    _provider = 'mock';
                    _mode = 'individual';
                    _workerId = null;
                  });
                  Navigator.pop(dialogContext);
                }),
                ..._providers.where((item) => item['id'] != 'mock' && item['id'] != 'comfyui_hosted').map((provider) {
                  final selected = !_demo && _provider == provider['id'];
                  return _choice(
                    palette,
                    '${provider['label']}',
                    provider['configured'] == true ? 'Configured on the server.' : '${provider['notice'] ?? ''}',
                    selected,
                    provider['configured'] == true
                        ? () {
                            setState(() {
                              _demo = false;
                              _processing = 'cloud_api';
                              _provider = '${provider['id']}';
                              _workerId = null;
                            });
                            Navigator.pop(dialogContext);
                          }
                        : null,
                  );
                }),
                _choice(palette, 'Hosted GPU', _hostedNotice(), _processing == 'hosted_gpu', () {
                  setState(() {
                    _demo = false;
                    _processing = 'hosted_gpu';
                    _provider = 'comfyui_hosted';
                    _workerId = null;
                  });
                  Navigator.pop(dialogContext);
                }),
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Text('Private GPU', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
                ),
                if (_workers.isEmpty) Text('No paired server yet.', style: TextStyle(color: palette.muted)),
                ..._workers.map((worker) => _choice(
                      palette,
                      '${worker['friendlyName']} · ${worker['publicId']}',
                      '${worker['status']}',
                      _workerId == worker['workerId'],
                      () {
                        setState(() {
                          _demo = false;
                          _processing = 'private_gpu';
                          _provider = 'comfyui_private';
                          _workerId = '${worker['workerId']}';
                        });
                        Navigator.pop(dialogContext);
                      },
                    )),
                StreetButton(
                  label: 'Pair a server',
                  secondary: true,
                  palette: palette,
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkersScreen()));
                    await _load();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choice(AppPalette palette, String title, String body, bool selected, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? palette.primary : palette.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: palette.muted)),
            ]),
          ),
        ),
      ),
    );
  }
}
