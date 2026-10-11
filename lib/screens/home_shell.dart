// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets.dart';
import 'setup_screen.dart';
import 'studio_screen.dart';
import 'workers_screen.dart';

const _cardShadow = [BoxShadow(color: Color(0x14071426), blurRadius: 16, offset: Offset(0, 8))];

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    final pages = [
      _HomePage(onOpen: _openSession),
      _SessionsPage(onOpen: _openSession),
      const _SettingsPage(),
    ];
    return StreetScaffold(
      palette: palette,
      body: Column(
        children: [
          Expanded(child: pages[_index]),
          _ShellNav(index: _index, palette: palette, onSelect: (value) => setState(() => _index = value)),
        ],
      ),
    );
  }

  Future<void> _openSession(String sessionId) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => StudioScreen(sessionId: sessionId)));
  }
}

class _ShellNav extends StatelessWidget {
  const _ShellNav({required this.index, required this.palette, required this.onSelect});
  final int index;
  final AppPalette palette;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.photo_library_outlined, 'Sessions'),
      (Icons.tune_rounded, 'Settings'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
          boxShadow: _cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: index == i ? palette.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(items[i].$1, size: 20, color: index == i ? palette.onPrimary : palette.muted),
                            const SizedBox(height: 2),
                            Text(
                              items[i].$2,
                              style: TextStyle(
                                color: index == i ? palette.onPrimary : palette.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage({required this.onOpen});
  final Future<void> Function(String sessionId) onOpen;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  List<Map<String, dynamic>> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final body = await AppScope.of(context).api.send('GET', '/api/v1/sessions');
      final rows = (body?['sessions'] as List?) ?? [];
      if (mounted) setState(() => _sessions = rows.cast<Map<String, dynamic>>());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _open(String sessionId) async {
    await widget.onOpen(sessionId);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    final recent = _sessions.take(4).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      children: [
        Text('Street Cloud', style: TextStyle(color: palette.text, fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Roboto', decoration: TextDecoration.none)),
        const SizedBox(height: 6),
        Text('AI Assisted Co-Urban Designer by Smartmind', style: TextStyle(color: palette.muted, fontSize: 12, height: 1.35)),
        const SizedBox(height: 16),
        _ActionCard(
          palette: palette,
          icon: Icons.add_a_photo_outlined,
          title: 'New street design',
          subtitle: 'Photograph a street and describe a change.',
          filled: true,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SetupScreen()));
            if (mounted) await _load();
          },
        ),
        const SizedBox(height: 10),
        _ActionCard(
          palette: palette,
          icon: Icons.group_outlined,
          title: 'Join with a code',
          subtitle: 'Open a street someone shared with you.',
          onTap: _join,
        ),
        const SizedBox(height: 22),
        Text('Recent', style: TextStyle(color: palette.text, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: palette.error))),
        if (recent.isEmpty)
          _EmptyCard(palette: palette, message: 'No streets yet. A new design starts with one photograph.')
        else
          for (final session in recent) _SessionCard(session: session, palette: palette, onOpen: _open),
      ],
    );
  }

  void _showError(String message, AppPalette palette) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message, style: TextStyle(color: palette.onPrimary))));
    }
  }

  Future<void> _join() async {
    final code = TextEditingController();
    final api = AppScope.of(context).api;
    final palette = AppScope.of(context).theme.paletteFor(context);
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: palette.border)),
        title: Text('Join with a code', style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: code,
          autofocus: true,
          style: TextStyle(color: palette.text, fontFamily: 'Roboto', decoration: TextDecoration.none),
          decoration: InputDecoration(
            hintText: 'Invitation code',
            hintStyle: TextStyle(color: palette.muted),
            filled: true,
            fillColor: palette.wash,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: palette.border)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: Text('Cancel', style: TextStyle(color: palette.muted))),
          TextButton(onPressed: () => Navigator.pop(dialogCtx, true), child: Text('Join', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    String? errorMessage;
    try {
      final body = await api.send('POST', '/api/v1/invitations/redeem', jsonBody: {'code': code.text.trim()});
      final sessionId = body?['sessionId'] as String?;
      if (sessionId != null) await _open(sessionId);
    } on ApiException catch (error) {
      errorMessage = error.message;
    }

    if (errorMessage != null) {
      _showError(errorMessage, palette);
    }
  }
}

class _SessionsPage extends StatefulWidget {
  const _SessionsPage({required this.onOpen});
  final Future<void> Function(String sessionId) onOpen;

  @override
  State<_SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<_SessionsPage> {
  List<Map<String, dynamic>> _sessions = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final body = await AppScope.of(context).api.send('GET', '/api/v1/sessions');
      if (mounted) setState(() => _sessions = ((body?['sessions'] as List?) ?? []).cast<Map<String, dynamic>>());
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {}
  }

  Future<void> _open(String sessionId) async {
    await widget.onOpen(sessionId);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      children: [
        Text('Sessions', style: TextStyle(color: palette.text, fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Roboto', decoration: TextDecoration.none)),
        const SizedBox(height: 6),
        Text(
          _sessions.isEmpty ? 'Streets you start or join show up here.' : '${_sessions.length} ${_sessions.length == 1 ? 'street' : 'streets'}',
          style: TextStyle(color: palette.muted, fontSize: 15),
        ),
        const SizedBox(height: 16),
        if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: TextStyle(color: palette.error))),
        if (_sessions.isEmpty)
          _EmptyCard(palette: palette, message: 'Nothing saved yet.')
        else
          for (final session in _sessions) _SessionCard(session: session, palette: palette, onOpen: _open),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.filled = false,
  });

  final AppPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? palette.onPrimary : palette.text;
    final secondary = filled ? palette.onPrimary.withValues(alpha: 0.82) : palette.muted;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? palette.primary : palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: filled ? palette.primary : palette.border),
        boxShadow: _cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: filled ? palette.onPrimary.withValues(alpha: 0.16) : palette.wash,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: filled ? palette.onPrimary : palette.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: TextStyle(color: foreground, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(subtitle, style: TextStyle(color: secondary, fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: secondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({required this.session, required this.palette, required this.onOpen});
  final Map<String, dynamic> session;
  final AppPalette palette;
  final Future<void> Function(String sessionId) onOpen;

  @override
  Widget build(BuildContext context) {
    final demo = session['demo'] == true;
    final mode = _prettyMode('${session['mode']}');
    final provider = '${session['provider']}'.replaceAll('_', ' ');
    final status = _prettyStatus('${session['status']}');
    final when = _when(session['updatedAt']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: palette.border),
          boxShadow: _cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onOpen('${session['sessionId']}'),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: demo ? const Color(0xFFF6E7A8) : palette.wash,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(demo ? Icons.science_outlined : Icons.photo_outlined, color: demo ? const Color(0xFF1C1915) : palette.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${session['title']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: palette.text, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (demo) const _MiniChip('DEMO', Color(0xFF1C1915), Color(0xFFF6E7A8)),
                            _MiniChip(mode, palette.primary, palette.wash),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          [provider, status, if (when.isNotEmpty) when].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: palette.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: palette.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.palette, required this.message});
  final AppPalette palette;
  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: palette.muted, fontSize: 15, height: 1.35)),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip(this.label, this.foreground, this.background);
  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Text(label, style: TextStyle(color: foreground, fontSize: 11, fontWeight: FontWeight.w700)),
      ),
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage();

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  final _base = TextEditingController();
  String? _message;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_base.text.isEmpty) _base.text = AppScope.of(context).api.apiBase;
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final palette = scope.theme.paletteFor(context);
    final dark = palette.brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      children: [
        Row(
          children: [
            Expanded(child: Text('Settings', style: TextStyle(color: palette.text, fontSize: 30, fontWeight: FontWeight.w700, fontFamily: 'Roboto', decoration: TextDecoration.none))),
            ThemeToggle(
              dark: dark,
              palette: palette,
              onChanged: (value) => scope.theme.setMode(value ? ThemeMode.dark : ThemeMode.light),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text('Appearance follows the sun and moon switch.', style: TextStyle(color: palette.muted, fontSize: 15)),
        const SizedBox(height: 18),
        Text('Connection', style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: _cardShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreetField(label: 'API address', controller: _base, palette: palette),
                const SizedBox(height: 12),
                StreetButton(
                  label: 'Save API address',
                  palette: palette,
                  onPressed: () async {
                    await scope.api.setApiBase(_base.text);
                    setState(() => _message = 'Saved. Provider keys stay on the server.');
                  },
                ),
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(_message!, style: TextStyle(color: palette.success)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text('Server', style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _SettingRow(
          palette: palette,
          icon: Icons.info_outline,
          title: 'How this works',
          subtitle: 'Providers, keys, and how long data is kept.',
          onTap: () => _details(context),
        ),
        _SettingRow(
          palette: palette,
          icon: Icons.memory_outlined,
          title: 'GPU servers',
          subtitle: 'Pair a private server on this account.',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const WorkersScreen())),
        ),
        const SizedBox(height: 10),
        Text('Account', style: TextStyle(color: palette.text, fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        _SettingRow(
          palette: palette,
          icon: Icons.logout,
          title: 'Sign out',
          subtitle: 'Leave this phone signed out.',
          onTap: () async {
            await scope.api.setTokens(null, null);
            if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (_) => false);
          },
        ),
        _SettingRow(
          palette: palette,
          icon: Icons.delete_outline,
          title: 'Delete account data',
          subtitle: 'Remove this account from the server.',
          danger: true,
          onTap: () async {
            await scope.api.send('DELETE', '/api/v1/me');
            await scope.api.setTokens(null, null);
            if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/sign-in', (_) => false);
          },
        ),
      ],
    );
  }

  Future<void> _details(BuildContext context) async {
    final palette = AppScope.of(context).theme.paletteFor(context);
    Map<String, dynamic>? body;
    try {
      body = await AppScope.of(context).api.send('GET', '/api/v1/providers/image');
    } catch (_) {}
    if (!context.mounted) return;
    final providers = ((body?['image'] as List?) ?? []).cast<Map<String, dynamic>>();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22), side: BorderSide(color: palette.border)),
        title: Row(
          children: [
            Expanded(child: Text('How this works', style: TextStyle(color: palette.text, fontWeight: FontWeight.w700))),
            IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: palette.text)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keys stay on the API server. The phone never stores an OpenAI or Gemini key.', style: TextStyle(color: palette.muted, height: 1.35)),
              const SizedBox(height: 12),
              ...providers.map(
                (provider) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.wash,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${provider['label']}', style: TextStyle(color: palette.text, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(
                            '${provider['configured'] == true ? 'Configured' : 'Not configured'}${provider['notice'] == null ? '' : '. ${provider['notice']}'}',
                            style: TextStyle(color: palette.muted, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Pilot retention default is 90 days. Deleting a session removes stored images from this server. Third-party provider logs follow that provider\'s own terms.',
                style: TextStyle(color: palette.muted, height: 1.35),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Understood', style: TextStyle(color: palette.primary, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.palette,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final AppPalette palette;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? palette.error : palette.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: danger ? palette.error.withValues(alpha: 0.45) : palette.border),
          boxShadow: _cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(color: danger ? palette.error : palette.text, fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 3),
                        Text(subtitle, style: TextStyle(color: palette.muted, fontSize: 13, height: 1.3)),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: palette.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _prettyMode(String mode) {
  if (mode == 'collaborative') return 'Group';
  if (mode == 'individual') return 'Just me';
  if (mode.isEmpty || mode == 'null') return 'Street';
  return mode[0].toUpperCase() + mode.substring(1);
}

String _prettyStatus(String status) {
  if (status.isEmpty || status == 'null') return '';
  return status[0].toUpperCase() + status.substring(1);
}

String _when(Object? value) {
  final parsed = DateTime.tryParse('$value');
  if (parsed == null) return '';
  final diff = DateTime.now().difference(parsed.toLocal());
  if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final local = parsed.toLocal();
  return '${local.day} ${months[local.month - 1]}';
}
