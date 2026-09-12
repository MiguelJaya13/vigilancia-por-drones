import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../tema.dart';
import 'comunes.dart';

/// Joystick táctil. En la tablet es el control principal, así que el pomo
/// sigue al dedo y vuelve al centro al soltar.
class Joystick extends StatefulWidget {
  const Joystick({super.key, required this.rotulo, required this.ejes, this.tam = 92});

  final String rotulo;
  final String ejes;
  final double tam;

  @override
  State<Joystick> createState() => _JoystickState();
}

class _JoystickState extends State<Joystick> {
  Offset _pomo = Offset.zero;

  void _mover(Offset local) {
    final r = widget.tam / 2;
    final d = local - Offset(r, r);
    final max = r - 16;
    final dist = math.min(d.distance, max);
    final a = math.atan2(d.dy, d.dx);
    setState(() => _pomo = Offset(math.cos(a) * dist, math.sin(a) * dist));
  }

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onPanStart: (e) => _mover(e.localPosition),
            onPanUpdate: (e) => _mover(e.localPosition),
            onPanEnd: (_) => setState(() => _pomo = Offset.zero),
            onPanCancel: () => setState(() => _pomo = Offset.zero),
            child: Container(
              width: widget.tam,
              height: widget.tam,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Paleta.lineaFuerte),
                gradient: RadialGradient(
                  center: const Alignment(0, -0.25),
                  colors: [
                    Colors.white.withValues(alpha: 0.09),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(widget.tam),
                    painter: _PintorEjes(),
                  ),
                  AnimatedSlide(
                    offset: Offset(_pomo.dx / 30, _pomo.dy / 30),
                    duration: const Duration(milliseconds: 90),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Paleta.texto, Paleta.texto2],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 5),
          Etiqueta(widget.rotulo),
          Text(widget.ejes,
              style: etiqueta(Paleta.texto3).copyWith(fontSize: 8)),
        ],
      );
}

class _PintorEjes extends CustomPainter {
  @override
  void paint(Canvas lienzo, Size tam) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.14);
    lienzo.drawRect(
        Rect.fromLTWH(tam.width / 2 - 0.5, 9, 1, tam.height - 18), p);
    lienzo.drawRect(
        Rect.fromLTWH(9, tam.height / 2 - 0.5, tam.width - 18, 1), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Consola de vuelo: joysticks y acciones sobre el dron seleccionado.
class ControlesVuelo extends StatelessWidget {
  const ControlesVuelo({
    super.key,
    required this.dron,
    required this.pausado,
    required this.onPausa,
    required this.onAterrizar,
    required this.onRetornar,
    required this.onDespegar,
  });

  final Dron? dron;
  final bool pausado;
  final VoidCallback onPausa;
  final VoidCallback onAterrizar;
  final VoidCallback onRetornar;
  final VoidCallback onDespegar;

  @override
  Widget build(BuildContext context) {
    final enBase = dron != null && !dron!.estado.volando;

    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      hijo: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Joystick(rotulo: 'Altitud / Giro', ejes: 'THR · YAW'),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BotonAccion(
                texto: pausado ? 'Reanudar' : 'Pausar',
                icono: pausado ? Icons.play_arrow : Icons.pause,
                onTap: onPausa,
              ),
              const SizedBox(height: 7),
              if (enBase)
                BotonAccion(
                  texto: 'Despegar',
                  icono: Icons.flight_takeoff,
                  principal: true,
                  onTap: onDespegar,
                )
              else
                BotonAccion(
                  texto: 'Aterrizar',
                  icono: Icons.flight_land,
                  onTap: dron == null ? null : onAterrizar,
                ),
              const SizedBox(height: 7),
              BotonAccion(
                texto: 'RTH',
                icono: Icons.home_outlined,
                peligro: true,
                onTap: dron == null || enBase ? null : onRetornar,
              ),
              const SizedBox(height: 6),
              if (dron != null)
                Etiqueta('${dron!.nombre} · ${dron!.estado.texto}'),
            ],
          ),
          const SizedBox(width: 20),
          const Joystick(rotulo: 'Desplazamiento', ejes: 'PITCH · ROLL'),
        ],
      ),
    );
  }
}
