import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

class StreetScaffold extends StatelessWidget {
  const StreetScaffold({super.key, required this.palette, required this.body, this.bottom});
  final AppPalette palette;
  final Widget body;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      palette: palette,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: body),
        bottomNavigationBar: bottom,
      ),
    );
  }
}

class StreetHeader extends StatelessWidget {
  const StreetHeader({super.key, required this.title, required this.palette, this.trailing});
  final String title;
  final AppPalette palette;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          StreetCircleButton(
            icon: Icons.arrow_back_rounded,
            palette: palette,
            tooltip: 'Back',
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: palette.text, fontSize: 22, height: 1.15, fontWeight: FontWeight.w700, fontFamily: 'Roboto', decoration: TextDecoration.none),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class StreetCircleButton extends StatelessWidget {
  const StreetCircleButton({super.key, required this.icon, required this.palette, required this.onPressed, this.tooltip, this.iconColor});
  final IconData icon;
  final AppPalette palette;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: palette.surface,
        elevation: 0,
        shadowColor: const Color(0x14071426),
        shape: CircleBorder(side: BorderSide(color: palette.border)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: iconColor ?? palette.text, size: 20),
          ),
        ),
      ),
    );
  }
}

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.dark, required this.palette, required this.onChanged});
  final bool dark;
  final AppPalette palette;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? palette.wash : palette.wash,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: dark ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dark ? palette.primary : palette.surface,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x22071426), blurRadius: 6, offset: Offset(0, 2))],
              ),
            ),
          ),
          Row(
            children: [
              _ThemeHalf(
                tooltip: 'Light mode',
                icon: Icons.wb_sunny_rounded,
                color: dark ? palette.muted : palette.primary,
                onTap: () => onChanged(false),
              ),
              _ThemeHalf(
                tooltip: 'Dark mode',
                icon: Icons.dark_mode_rounded,
                color: dark ? palette.onPrimary : palette.muted,
                onTap: () => onChanged(true),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeHalf extends StatelessWidget {
  const _ThemeHalf({required this.tooltip, required this.icon, required this.color, required this.onTap});
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(child: Icon(icon, size: 18, color: color)),
        ),
      ),
    );
  }
}

class StreetField extends StatelessWidget {
  const StreetField({super.key, required this.label, required this.controller, this.obscure = false, this.palette});
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final AppPalette? palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: colors?.muted)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: TextStyle(color: colors?.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: colors?.surface ?? Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors?.border ?? Colors.transparent)),
          ),
        ),
      ],
    );
  }
}

class StreetButton extends StatelessWidget {
  const StreetButton({super.key, required this.label, required this.onPressed, this.secondary = false, this.danger = false, this.palette});
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool danger;
  final AppPalette? palette;

  @override
  Widget build(BuildContext context) {
    final colors = palette;
    if (secondary || danger) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          foregroundColor: danger ? colors?.error : colors?.primary,
          backgroundColor: colors?.surface,
          side: BorderSide(color: colors?.border ?? Colors.transparent),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors?.primary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: (colors?.primary ?? const Color(0xFF1C3D5A)).withValues(alpha: 0.22), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: colors?.onPrimary ?? Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(label),
      ),
    );
  }
}
