import 'dart:async';

import 'package:flutter/material.dart';

void mostrarAvisoPopup(
  BuildContext context,
  String mensagem, {
  required Color cor,
  VoidCallback? onDismiss,
}) {
  final overlay = Overlay.of(context);
  final top = MediaQuery.paddingOf(context).top + kToolbarHeight + 8;
  late final OverlayEntry entry;

  entry = OverlayEntry(
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  overlay.insert(entry);
  Timer(const Duration(seconds: 4), () {
    if (entry.mounted) {
      entry.remove();
      onDismiss?.call();
    }
  });
}
