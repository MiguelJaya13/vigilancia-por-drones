import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../tema.dart';

/// Cuadricóptero visto desde arriba, con los rotores girando.
/// El dibujo apunta al norte, de modo que rotarlo por el rumbo lo alinea
/// con el sentido de vuelo.
class IconoDron extends StatefulWidget {
  const IconoDron({
    super.key,
    this.tam = 26,
    this.color = Paleta.acento,
    this.rumbo = 0,
    this.activo = false,
    this.girando = true,
  });

  final double tam;
  final Color color;

  /// Rumbo en grados (0 = norte).
  final double rumbo;
  final bool activo;
  final bool girando;

  @override
  State<IconoDron> createState() => _IconoDronState();
}

class _IconoDronState extends State<IconoDron>
    with SingleTickerProviderStateMixin {
  late final AnimationController _palas = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    if (widget.girando) _palas.repeat();
  }

  @override
  void didUpdateWidget(covariant IconoDron old) {
    super.didUpdateWidget(old);
    if (widget.girando && !_palas.isAnimating) {
      _palas.repeat();
    } else if (!widget.girando && _palas.isAnimating) {
      _palas.stop();
    }
  }

  @override
  void dispose() {
    _palas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Transform.rotate(
        angle: widget.rumbo * math.pi / 180,
        child: AnimatedBuilder(
          animation: _palas,
          builder: (context, _) => CustomPaint(
            size: Size.square(widget.tam),
            painter: _PintorDron(
              color: widget.color,
              giroPalas: _palas.value * 2 * math.pi,
              activo: widget.activo,
            ),
          ),
        ),
      );
}

class _PintorDron extends CustomPainter {
  _PintorDron({
    required this.color,
    required this.giroPalas,
    required this.activo,
  });

  final Color color;
  final double giroPalas;
  final bool activo;

  @override
  void paint(Canvas lienzo, Size tam) {
    final u = tam.width / 24; // el dibujo se define sobre una caja de 24
    final centro = Offset(tam.width / 2, tam.height / 2);

    final trazo = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.7 * u;
    final relleno = Paint()..color = color;

    // Brazos en diagonal.
    const brazos = [
      [Offset(8.4, 8.4), Offset(6.2, 6.2)],
      [Offset(15.6, 8.4), Offset(17.8, 6.2)],
      [Offset(8.4, 15.6), Offset(6.2, 17.8)],
      [Offset(15.6, 15.6), Offset(17.8, 17.8)],
    ];
    for (final b in brazos) {
      lienzo.drawLine(b[0] * u, b[1] * u, trazo);
    }

    // Rotores con sus palas girando.
    const rotores = [
      Offset(5.4, 5.4),
      Offset(18.6, 5.4),
      Offset(5.4, 18.6),
      Offset(18.6, 18.6),
    ];
    final aro = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * u;
    final pala = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1 * u;

    for (var i = 0; i < rotores.length; i++) {
      final c = rotores[i] * u;
      lienzo.drawCircle(c, 3.1 * u, aro);
      final giro = giroPalas + i * 0.6;
      for (final a in [giro, giro + math.pi / 2]) {
        final d = Offset(math.cos(a), math.sin(a)) * 2.3 * u;
        lienzo.drawLine(c - d, c + d, pala);
      }
    }

    // Cuerpo y nariz.
    lienzo.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: centro, width: 6.6 * u, height: 7.2 * u),
        Radius.circular(2.3 * u),
      ),
      relleno,
    );
    lienzo.drawLine(
      Offset(12 * u, 9.1 * u),
      Offset(12 * u, 6.4 * u),
      trazo..strokeWidth = 1.6 * u,
    );
    // Cámara bajo el fuselaje.
    lienzo.drawCircle(
      Offset(12 * u, 13.5 * u),
      1.4 * u,
      Paint()..color = const Color(0xFF04141A),
    );

    if (activo) {
      lienzo.drawCircle(
        centro,
        tam.width / 2,
        Paint()
          ..color = color.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PintorDron old) =>
      old.giroPalas != giroPalas || old.color != color || old.activo != activo;
}
