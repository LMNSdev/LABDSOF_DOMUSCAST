import 'dart:async';

import 'package:flutter/material.dart';
import '../local/queue_db.dart';
import '../services/api_service.dart';
import '../services/sessao_admin.dart';
import '../services/sessao_residente.dart';
import 'criar_condominio_screen.dart';
import 'home_screen.dart';
import 'ler_qr_screen.dart';
import 'nome_residente_screen.dart';

class LandingScreen extends StatefulWidget {
  final SessaoAdminStore? store;
  final SessaoResidenteStore? storeResidente;
  final ApiService? api;
  final FilaReportes? fila;

  /// Links `domuscast://entrar?t=` que abrem a app (US-15).
  final Stream<Uri>? links;

  const LandingScreen({super.key, this.store, this.storeResidente, this.api, this.fila, this.links});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final SessaoAdminStore _store = widget.store ?? SeguraSessaoAdminStore();
  late final SessaoResidenteStore _storeResidente =
      widget.storeResidente ?? SeguraSessaoResidenteStore();
  late final ApiService _api = widget.api ?? ApiService();
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _abrirSessao();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _links?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  // Quem já tem sessão entra direto na app (nos Reportes), sem voltar a pedir o nome.
  // Só sem sessão é que um link domuscast://entrar abre o ecrã do nome.
  Future<void> _abrirSessao() async {
    final admin = await _store.ler();
    final residente = admin == null ? await _storeResidente.ler() : null;
    if (!mounted) return;
    if (admin != null || residente != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            api: _api,
            sessao: admin,
            sessaoResidente: residente,
            storeResidente: _storeResidente,
            fila: widget.fila,
          ),
        ),
      );
      return;
    }
    _links = widget.links?.listen(_abrirLink);
  }

  void _abrirLink(Uri link) {
    final token = tokenDoLink(link.toString());
    if (token == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NomeResidenteScreen(api: _api, store: _storeResidente, token: token, fila: widget.fila),
    ));
  }

  void _criarCondominio() {
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => CriarCondominioScreen(api: _api, store: _store)),
    );
  }

  void _enter() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => LerQrScreen(api: _api, store: _storeResidente),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A2559), Color(0xFF0F3478), Color(0xFF1A52A8)],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                // Desliza quando o ecrã é baixo demais para o conteúdo.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            SizedBox(height: size.height * 0.12),

                            // ── Ícone ──────────────────────────────────────────────
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color:
                                    const Color.fromRGBO(255, 255, 255, 0.12),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color:
                                      const Color.fromRGBO(255, 255, 255, 0.2),
                                  width: 1.5,
                                ),
                              ),
                              child: const _BuildingIcon(),
                            ),

                            const SizedBox(height: 28),

                            // ── Nome ───────────────────────────────────────────────
                            const Text(
                              'DomusCast',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'A gestão do seu condomínio,\nsimplificada.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.72),
                                fontSize: 17,
                                height: 1.5,
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 56),

                            // ── Features ───────────────────────────────────────────
                            ..._features.map(
                                (f) => _FeatureTile(icon: f.$1, text: f.$2)),

                            const Spacer(),

                            // ── CTA ────────────────────────────────────────────────
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _enter,
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF0F3478),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                child: const Text('Entrar'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: _criarCondominio,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                      color: Color.fromRGBO(255, 255, 255, 0.6),
                                      width: 1.5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  textStyle: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600),
                                ),
                                child: const Text(
                                    'Sou administrador: criar condomínio'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Acesso por QR code da fração',
                              style: TextStyle(
                                color: Color.fromRGBO(255, 255, 255, 0.4),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _features = [
  (Icons.report_problem_outlined,   'Reporte avarias em menos de 1 minuto'),
    (Icons.history_rounded, 'Acompanhe o estado e o histórico de cada problema'),
  (Icons.wifi_off_rounded, 'Funciona sem internet - sincroniza quando voltar'),
];

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String text;
  const _FeatureTile({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color.fromRGBO(255, 255, 255, 0.85),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BuildingIcon extends StatelessWidget {
  const _BuildingIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(96, 96),
      painter: _BuildingPainter(),
    );
  }
}

class _BuildingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Building body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 22, cy - 4, 44, 30),
      const Radius.circular(3),
    );
    canvas.drawRRect(body, paint);

    // Roof
    final roof = Path()
      ..moveTo(cx, cy - 22)
      ..lineTo(cx - 27, cy - 2)
      ..lineTo(cx + 27, cy - 2)
      ..close();
    canvas.drawPath(roof, paint);

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 6, cy + 12, 12, 14),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF0F3478),
    );

    // Signal arcs
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 3; i++) {
      final r = 10.0 + i * 8;
      arcPaint.strokeWidth = 2.5 - i * 0.5;
      canvas.drawArc(
        Rect.fromCenter(
            center: Offset(cx, cy - 26), width: r * 2, height: r * 2),
        3.7,
        2.0,
        false,
        arcPaint,
      );
    }

    // Signal dot
    canvas.drawCircle(Offset(cx, cy - 26), 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
