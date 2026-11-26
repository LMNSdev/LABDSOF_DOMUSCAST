import 'package:flutter/material.dart';

/// Estado de um reporte com a mesma cor e ícone na lista e no detalhe.
class EstadoBadge extends StatelessWidget {
  final String? estado;
  final double tamanho;

  const EstadoBadge(this.estado, {super.key, this.tamanho = 12});

  static ({Color bg, Color fg, String label, IconData icon}) estilo(String? estado) =>
      switch (estado) {
        'resolvido' => (
          bg: const Color(0xFFE8F5E9),
          fg: const Color(0xFF2E7D32),
          label: 'Resolvido',
          icon: Icons.check_circle_outline,
        ),
        'em_curso' => (
          bg: const Color(0xFFFFF3E0),
          fg: const Color(0xFFE65100),
          label: 'Em curso',
          icon: Icons.autorenew,
        ),
        _ => (
          bg: const Color(0xFFFFEBEE),
          fg: const Color(0xFFC62828),
          label: 'Aberto',
          icon: Icons.error_outline,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final s = estilo(estado);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: tamanho - 2, vertical: tamanho / 3),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: tamanho + 1, color: s.fg),
          const SizedBox(width: 4),
          Text(
            s.label,
            style: TextStyle(fontSize: tamanho, fontWeight: FontWeight.w600, color: s.fg),
          ),
        ],
      ),
    );
  }
}
