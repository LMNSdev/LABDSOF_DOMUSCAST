import 'dart:async';

import 'package:flutter/material.dart';

class AvisoPopupController {
  Timer? _timer;
  OverlayEntry? _entry;
  VoidCallback? _onDismiss;

  void show(
    BuildContext context,
    String mensagem, {
    required Color cor,
    VoidCallback? onDismiss,
  }) {
    _dismiss();
    final overlay = Overlay.of(context);
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        top: top,
        left: 16,
        right: 16,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Material(
              key: const Key('aviso-popup'),
              color: cor,
              elevation: 6,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          mensagem,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _entry = entry;
    _onDismiss = onDismiss;
    overlay.insert(entry);
    _timer = Timer(const Duration(seconds: 4), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    _timer = null;
    final entry = _entry;
    _entry = null;
    if (entry?.mounted ?? false) entry!.remove();
    final callback = _onDismiss;
    _onDismiss = null;
    callback?.call();
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
    _onDismiss = null;
  }
}
