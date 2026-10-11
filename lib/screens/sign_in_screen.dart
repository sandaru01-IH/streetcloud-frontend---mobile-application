// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';

import '../api/client.dart';
import '../main.dart';
import '../widgets.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _apiAddress = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_apiAddress.text.isEmpty) _apiAddress.text = AppScope.of(context).api.apiBase;
  }

  Future<void> _saveBase(ApiClient api) async {
    await api.setApiBase(_apiAddress.text);
  }

  void _onSuccess() {
    if (mounted) Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = AppScope.of(context).api;
    try {
      await _saveBase(api);
      final body = await api.send('POST', '/api/v1/auth/login', jsonBody: {
        'email': _email.text.trim(),
        'password': _password.text,
      });
      final accessToken = body?['accessToken'] as String?;
      final refreshToken = body?['refreshToken'] as String?;
      await api.setTokens(accessToken, refreshToken);
      _onSuccess();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _guest() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = AppScope.of(context).api;
    try {
      await _saveBase(api);
      final body = await api.send('POST', '/api/v1/auth/guest');
      final accessToken = body?['accessToken'] as String?;
      final refreshToken = body?['refreshToken'] as String?;
      await api.setTokens(accessToken, refreshToken);
      _onSuccess();
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppScope.of(context).theme.paletteFor(context);
    return StreetScaffold(
      palette: palette,
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Sign in', style: TextStyle(color: palette.text, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('On a phone, use this computer\'s Wi-Fi address, not 127.0.0.1.', style: TextStyle(color: palette.muted)),
          const SizedBox(height: 20),
          StreetField(label: 'API address', controller: _apiAddress, palette: palette),
          const SizedBox(height: 14),
          StreetField(label: 'Email', controller: _email, palette: palette),
          const SizedBox(height: 14),
          StreetField(label: 'Password', controller: _password, obscure: true, palette: palette),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: palette.error)),
          ],
          const SizedBox(height: 18),
          StreetButton(label: _busy ? 'Please wait' : 'Sign in', onPressed: _busy ? null : _login, palette: palette),
          const SizedBox(height: 10),
          StreetButton(label: 'Create an account', secondary: true, onPressed: _busy ? null : () => Navigator.of(context).pushNamed('/register'), palette: palette),
          const SizedBox(height: 10),
          StreetButton(label: 'Explore the sample street', secondary: true, onPressed: _busy ? null : _guest, palette: palette),
        ],
      ),
    );
  }
}
