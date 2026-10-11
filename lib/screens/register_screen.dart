import 'package:flutter/material.dart';

import '../api/client.dart';
import '../main.dart';
import '../widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _register() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = AppScope.of(context).api;
    try {
      final body = await api.send('POST', '/api/v1/auth/register', jsonBody: {
        'displayName': _name.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
      });
      await api.setTokens(body?['accessToken'] as String?, body?['refreshToken'] as String?);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
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
          StreetHeader(title: 'Create account', palette: palette),
          const SizedBox(height: 20),
          StreetField(label: 'Name', controller: _name, palette: palette),
          const SizedBox(height: 14),
          StreetField(label: 'Email', controller: _email, palette: palette),
          const SizedBox(height: 14),
          StreetField(label: 'Password', controller: _password, obscure: true, palette: palette),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: palette.error)),
          ],
          const SizedBox(height: 18),
          StreetButton(label: _busy ? 'Please wait' : 'Create account', onPressed: _busy ? null : _register, palette: palette),
        ],
      ),
    );
  }
}
