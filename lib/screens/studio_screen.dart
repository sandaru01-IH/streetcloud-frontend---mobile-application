import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../api/client.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets.dart';

const _makingLines = [
  'Reading your idea',
  'Shaping the street',
  'Building the new view',
  'Adding the final touches',
  'Delivering the best one right away',
];

final _photoBlur = ImageFilter.blur(sigmaX: 18, sigmaY: 18);

const _scoringLines = [
  'Looking at this street',
  'Reading the fifteen properties',
  'Weighing what changed',
  'Adding the final touches',
  'The scores are almost ready',
];

class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key, required this.sessionId});
  final String sessionId;

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  final _text = TextEditingController();
  String _tab = 'design';
  String? _error;
  String? _pendingId;
  Map<String, dynamic>? _session;
  List<Map<String, dynamic>> _versions = [];
  List<Map<String, dynamic>> _concepts = [];
  String _cloudLabel = 'Priorities';
  String? _photoUrl;
  String? _photoSubject;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
    _poll = Timer.periodic(const Duration(seconds: 2), (_) {
      final job = _session?['activeJob'];
      if (job is Map && job['status'] != null) _refresh();
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _text.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final api = AppScope.of(context).api;
    try {
      final session = await api.send('GET', '/api/v1/sessions/${widget.sessionId}');
      final versions = await api.send('GET', '/api/v1/sessions/${widget.sessionId}/versions');
      final cloud = await api.send('GET', '/api/v1/sessions/${widget.sessionId}/wordcloud');
      if (!mounted) return;
      setState(() {
        _session = session;
        _versions = ((versions?['versions'] as List?) ?? []).cast<Map<String, dynamic>>();
        _concepts = ((cloud?['concepts'] as List?) ?? []).cast<Map<String, dynamic>>();
        _cloudLabel = '${cloud?['label'] ?? 'Priorities'}';
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _submit([String? chip]) async {
    final value = (chip ?? _text.text).trim();
    if (value.isEmpty || _session == null) return;
    final submissionId = _pendingId ?? const Uuid().v4();
    setState(() {
      _pendingId = submissionId;
      _error = null;
    });
    try {
      await AppScope.of(context).api.send('POST', '/api/v1/sessions/${widget.sessionId}/feedback', jsonBody: {
        'text': value,
        'clientSubmissionId': submissionId,
        'expectedSessionRevision': _session?['revision'],
      });
      _text.clear();
      setState(() => _pendingId = null);
      await _refresh();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    final api = AppScope.of(context).api;
    final current = _session?['currentVersion'] as Map?;
    final job = _session?['activeJob'] as Map?;
    _holdPhoto(api.mediaUrl(current?['imagePath'] as String? ?? _session?['originalImagePath'] as String?));
    final image = _photoUrl;
    return StreetScaffold(
      palette: palette,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: StreetHeader(
              title: '${_session?['title'] ?? 'Studio'}',
              palette: palette,
              trailing: StreetCircleButton(
                icon: Icons.insights_outlined,
                palette: palette,
                tooltip: 'Scores',
                iconColor: palette.primary,
                onPressed: () => _scores(context, current?['versionId'] as String?),
              ),
            ),
          ),
          if (_session?['demo'] == true || current?['demoLabeled'] == true)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Wrap(spacing: 8, children: [
                if (_session?['demo'] == true) _pill(palette, 'DEMO'),
                if (current?['demoLabeled'] == true) _pill(palette, 'DEMO / MOCK RESULT'),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: DecoratedBox(
              decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: palette.border)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    for (final item in ['design', 'cloud', 'history'])
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _tab = item),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _tab == item ? palette.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item == 'cloud' ? 'Word Cloud' : item[0].toUpperCase() + item.substring(1),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: _tab == item ? palette.onPrimary : palette.text, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: _tab == 'design' ? _design(palette, image, job, current) : _tab == 'cloud' ? _cloud(palette) : _history(palette)),
        ],
      ),
    );
  }

  Widget _design(AppPalette palette, String? image, Map? job, Map? current) {
    final making = job != null;
    final failed = job?['errorMessage'] != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border),
                boxShadow: const [BoxShadow(color: Color(0x14071426), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(
                      color: palette.wash,
                      child: image == null
                          ? Center(child: Icon(Icons.add_photo_alternate_outlined, color: palette.muted, size: 42))
                          : _HeldPhoto(url: image, headers: _headers()),
                    ),
                    if (making)
                      BackdropFilter(
                        filter: _photoBlur,
                        child: const ColoredBox(color: Color(0x66101820)),
                      ),
                    Positioned(
                      left: 12,
                      top: 12,
                      child: _HistoryChip('Version ${current?['versionNumber'] ?? 0}', Colors.white, const Color(0xCC10233F)),
                    ),
                    if (current?['demoLabeled'] == true)
                      const Positioned(top: 12, right: 12, child: _HistoryChip('DEMO / MOCK RESULT', Color(0xFF10233F), Color(0xFFF6E7A8))),
                    if (making)
                      Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white),
                                  const SizedBox(height: 12),
                                  if (failed)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: Text('${job['errorMessage']}', textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFF0A8A0), fontSize: 16)),
                                    )
                                  else
                                    const _StatusLine(lines: _makingLines, color: Colors.white),
                                  TextButton(
                                    onPressed: () async {
                                      await AppScope.of(context).api.send('POST', '/api/v1/generations/${job['jobId']}/cancel');
                                      await _refresh();
                                    },
                                    child: const Text('Stop generation', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.border),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 8, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 2,
                      maxLines: 4,
                      style: TextStyle(color: palette.text, fontFamily: 'Roboto', fontSize: 16, decoration: TextDecoration.none),
                      decoration: InputDecoration(
                        hintText: 'Describe a change to this street',
                        hintStyle: TextStyle(color: palette.muted),
                        filled: false,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                      color: making ? palette.border : palette.primary,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: making ? null : () => _submit(),
                        child: SizedBox(width: 48, height: 48, child: Icon(Icons.arrow_upward_rounded, color: palette.onPrimary)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: palette.error))),
          if (_session?['mode'] == 'collaborative')
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(onPressed: _invite, child: Text('Invite code', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w600))),
            ),
        ],
      ),
    );
  }

  Widget _cloud(AppPalette palette) {
    final ideas = [..._concepts]..sort((left, right) => ((right['weight'] as num?) ?? 0).compareTo((left['weight'] as num?) ?? 0));
    final heaviest = ideas.fold<num>(1, (maxWeight, item) => ((item['weight'] as num?) ?? 0) > maxWeight ? (item['weight'] as num) : maxWeight);
    final inks = [palette.primary, palette.text, palette.primary.withValues(alpha: 0.72), palette.muted];
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        Text(_cloudLabel, style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: const [BoxShadow(color: Color(0x14071426), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
              child: ideas.isEmpty
                  ? Text('Your ideas will appear here.', textAlign: TextAlign.center, style: TextStyle(color: palette.muted, fontSize: 16))
                  : Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 14,
                      runSpacing: 10,
                      children: [
                        for (var index = 0; index < ideas.length; index++)
                          Text(
                            '${ideas[index]['label']}',
                            style: TextStyle(
                              color: inks[index % inks.length],
                              fontSize: 15 + (((ideas[index]['weight'] as num?) ?? 1) / heaviest) * 17,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ),
        if (ideas.isNotEmpty) ...[
          const SizedBox(height: 18),
          Text('Ideas', style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final item in ideas)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: DecoratedBox(
                decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: palette.border)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(child: Text('${item['label']}', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600, fontSize: 16))),
                      Text('${item['submissionCount']} · ${item['contributorCount']} people', style: TextStyle(color: palette.muted, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _history(AppPalette palette) {
    final api = AppScope.of(context).api;
    final currentId = (_session?['currentVersion'] as Map?)?['versionId'];
    final versions = _versions.reversed.toList();
    if (versions.isEmpty) {
      return Center(child: Text('No versions yet.', style: TextStyle(color: palette.muted, fontSize: 16)));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: versions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final version = versions[index];
        final current = version['versionId'] == currentId;
        final image = api.mediaUrl(version['imagePath'] as String?);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: current ? palette.primary : palette.border, width: current ? 2 : 1),
            boxShadow: const [BoxShadow(color: Color(0x14071426), blurRadius: 16, offset: Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SizedBox(
                  height: 210,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ColoredBox(
                        color: palette.wash,
                        child: image == null
                            ? Icon(Icons.image_outlined, color: palette.muted, size: 36)
                            : Image.network(image, headers: _headers(), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.image_outlined, color: palette.muted, size: 36)),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x00000000), Color(0xCC10233F)],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        bottom: 12,
                        right: 12,
                        child: Row(
                          children: [
                            Text('Version ${version['versionNumber']}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Roboto')),
                            const Spacer(),
                            if (current) _HistoryChip('Current', palette.onPrimary, palette.primary),
                          ],
                        ),
                      ),
                      if (version['demoLabeled'] == true)
                        const Positioned(top: 12, left: 12, child: _HistoryChip('DEMO / MOCK RESULT', Color(0xFF10233F), Color(0xFFF6E7A8))),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Row(
                  children: [
                    _historyAction(palette, Icons.insights_outlined, 'Scores', () => _scores(context, version['versionId'] as String?)),
                    const SizedBox(width: 8),
                    _historyAction(palette, Icons.ios_share, 'Export', () => _shareImage(version)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _historyAction(AppPalette palette, IconData icon, String label, VoidCallback onPressed) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18, color: palette.primary),
        label: Text(label, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: palette.border),
          backgroundColor: palette.wash,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _invite() async {
    final invite = await AppScope.of(context).api.send('POST', '/api/v1/sessions/${widget.sessionId}/invites');
    if (!mounted) return;
    setState(() => _error = 'Join code ${invite?['code']}');
  }

  Future<void> _shareImage(Map<String, dynamic> version) async {
    final api = AppScope.of(context).api;
    final url = api.mediaUrl(version['exportPath'] as String?);
    if (url == null) return;
    final bytes = await api.download(url);
    final file = File('${(await getTemporaryDirectory()).path}/street-v${version['versionNumber']}.jpg');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path, mimeType: 'image/jpeg')]);
  }

  void _holdPhoto(String? url) {
    if (url == null || url.isEmpty) return;
    final subject = Uri.tryParse(url)?.path ?? url;
    if (_photoSubject == subject && _photoUrl != null) return;
    _photoSubject = subject;
    _photoUrl = url;
  }

  Map<String, String> _headers() {
    final token = AppScope.of(context).api.accessToken;
    return token == null ? {} : {'Authorization': 'Bearer $token'};
  }

  Future<void> _scores(BuildContext context, String? versionId) async {
    if (versionId == null) return;
    final palette = AppScope.of(context).theme.paletteFor(context);
    final shown = _versions.where((item) => item['versionId'] == versionId).firstOrNull;
    final earlier = _versions.where((item) => shown != null && (item['versionNumber'] as num) < (shown['versionNumber'] as num)).toList()
      ..sort((left, right) => (left['versionNumber'] as num).compareTo(right['versionNumber'] as num));
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: palette.surface,
      builder: (context) => _ScoreSheet(
        versionId: versionId,
        previousVersionId: earlier.isEmpty ? null : '${earlier.last['versionId']}',
        visionProvider: '${_session?['visionProvider'] ?? ''}',
        versionNumber: shown?['versionNumber'],
      ),
    );
  }

  Widget _pill(AppPalette palette, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: palette.surface, borderRadius: BorderRadius.circular(999), border: Border.all(color: palette.border)),
      child: Text(text, style: TextStyle(color: palette.text, fontSize: 12)),
    );
  }
}

class _HeldPhoto extends StatefulWidget {
  const _HeldPhoto({required this.url, required this.headers});
  final String url;
  final Map<String, String> headers;

  @override
  State<_HeldPhoto> createState() => _HeldPhotoState();
}

class _HeldPhotoState extends State<_HeldPhoto> {
  late ImageProvider _image;

  @override
  void initState() {
    super.initState();
    _image = NetworkImage(widget.url, headers: widget.headers);
  }

  @override
  void didUpdateWidget(covariant _HeldPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _image = NetworkImage(widget.url, headers: widget.headers);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Image(
        image: _image,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.expand(),
      ),
    );
  }
}

class _HistoryChip extends StatelessWidget {
  const _HistoryChip(this.label, this.color, this.background);
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700, fontFamily: 'Roboto')),
      ),
    );
  }
}

class _StatusLine extends StatefulWidget {
  const _StatusLine({required this.lines, this.color});
  final List<String> lines;
  final Color? color;

  @override
  State<_StatusLine> createState() => _StatusLineState();
}

class _StatusLineState extends State<_StatusLine> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 2200), (_) {
      if (!mounted || widget.lines.isEmpty) return;
      setState(() => _index = (_index + 1) % widget.lines.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = widget.lines[_index];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      child: Text(
        line,
        key: ValueKey(line),
        textAlign: TextAlign.center,
        style: TextStyle(color: widget.color, fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Roboto', decoration: TextDecoration.none),
      ),
    );
  }
}

class _ScoreSheet extends StatefulWidget {
  const _ScoreSheet({required this.versionId, required this.previousVersionId, required this.visionProvider, required this.versionNumber});
  final String versionId;
  final String? previousVersionId;
  final String visionProvider;
  final Object? versionNumber;

  @override
  State<_ScoreSheet> createState() => _ScoreSheetState();
}

class _ScoreSheetState extends State<_ScoreSheet> {
  Map<String, dynamic>? _evaluation;
  Map<String, num> _prior = {};
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = AppScope.of(context).api;
    try {
      final evaluation = await api.send('GET', '/api/v1/versions/${widget.versionId}/evaluations');
      final prior = <String, num>{};
      if (widget.previousVersionId != null) {
        final previous = await api.send('GET', '/api/v1/versions/${widget.previousVersionId}/evaluations');
        for (final item in ((previous?['assessments'] as List?) ?? [])) {
          final row = item as Map;
          if (row['score'] is num) prior['${row['key']}'] = row['score'] as num;
        }
      }
      if (!mounted) return;
      setState(() {
        _evaluation = evaluation;
        _prior = prior;
        _error = null;
      });
      final status = evaluation?['status'];
      if (status == 'queued' || status == 'running') {
        _timer ??= Timer.periodic(const Duration(seconds: 2), (_) => _load());
      } else {
        _timer?.cancel();
        _timer = null;
      }
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    final scoring = _evaluation?['status'] == 'queued' || _evaluation?['status'] == 'running' || _evaluation == null;
    final label = _evaluation?['origin'] == 'authored_fixture'
        ? 'DEMO FIXTURE — not a vision model'
        : (_evaluation?['model'] != null ? 'Vision model · ${_evaluation?['model']}' : (widget.visionProvider == 'ollama_vision' ? 'Local vision model' : widget.visionProvider));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text("Alexander's 15 properties", style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.w700, height: 1.2)),
          const SizedBox(height: 4),
          Text('Values of a living structure', style: TextStyle(color: palette.muted, fontSize: 14, height: 1.3)),
          const SizedBox(height: 2),
          Text('v${widget.versionNumber ?? ''} · $label', style: TextStyle(color: palette.muted)),
          if (_error != null) Text(_error!, style: TextStyle(color: palette.error)),
          if (scoring && _error == null)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                _StatusLine(lines: _scoringLines),
              ]),
            ),
          if (_evaluation?['status'] == 'failed') Text('${_evaluation?['errorMessage'] ?? ''}', style: TextStyle(color: palette.error)),
          if (_evaluation?['status'] == 'not_requested') Text('No score for this version yet.', style: TextStyle(color: palette.muted)),
          if (!scoring)
            for (final raw in ((_evaluation?['assessments'] as List?) ?? [])) _row(palette, raw as Map),
          const SizedBox(height: 8),
          StreetButton(label: 'Export CSV', secondary: true, palette: palette, onPressed: () => _export('csv')),
          const SizedBox(height: 8),
          StreetButton(label: 'Export JSON', secondary: true, palette: palette, onPressed: () => _export('json')),
        ],
      ),
    );
  }

  Widget _row(AppPalette palette, Map item) {
    final score = item['score'];
    final key = '${item['key']}';
    String delta = '';
    Color? deltaColor;
    if (score is num && _prior[key] != null && score != _prior[key]) {
      final change = score - _prior[key]!;
      delta = ' (${change > 0 ? '+' : ''}${change.toStringAsFixed(change == change.roundToDouble() ? 0 : 1)})';
      deltaColor = change > 0 ? palette.success : palette.error;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Expanded(child: Text('${item['name']}', style: TextStyle(color: palette.text))),
        Text(score == null ? 'N/A' : '$score', style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
        Text(delta, style: TextStyle(color: deltaColor, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Future<void> _export(String kind) async {
    final rows = ((_evaluation?['assessments'] as List?) ?? []).cast<Map>();
    final model = _evaluation?['model'];
    final body = kind == 'csv'
        ? 'property,score\n${rows.map((item) => '"${item['name']}",${item['score'] ?? ''}').join('\n')}'
        : '{"version":${widget.versionNumber ?? 0},"model":${model == null ? 'null' : '"$model"'},"scores":[${rows.map((item) => '{"property":"${item['name']}","key":"${item['key']}","score":${item['score'] ?? 'null'}}').join(',')}]}';
    final file = File('${(await getTemporaryDirectory()).path}/alexander-scores.$kind');
    await file.writeAsString(body);
    await Share.shareXFiles([XFile(file.path)]);
  }
}
