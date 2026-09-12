import 'package:flutter/material.dart';

import '../datos/camaras.dart';
import '../tema.dart';

/// Línea de tiempo del NVR: franja azul con lo grabado, marcas de evento y
/// cursor arrastrable. Trabaja en minutos del día (0-1440).
class LineaTiempoCamara extends StatelessWidget {
  const LineaTiempoCamara({
    super.key,
    required this.grabacion,
    required this.minuto,
    required this.onBuscar,
    required this.onEvento,
  });

  final GrabacionCamara grabacion;
  final double minuto;
  final ValueChanged<double> onBuscar;
  final ValueChanged<EventoCamara> onEvento;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 13,
            child: LayoutBuilder(
              builder: (context, c) => Stack(
                children: [
                  for (var h = 0; h <= 24; h += 3)
                    Positioned(
                      left: (h / 24) * c.maxWidth - 14,
                      child: SizedBox(
                        width: 28,
                        child: Text(
                          '${h.toString().padLeft(2, '0')}:00',
                          textAlign: TextAlign.center,
                          style: mono(tam: 8.5, color: Paleta.texto3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 3),
          LayoutBuilder(
            builder: (context, c) {
              void buscar(Offset local) =>
                  onBuscar(((local.dx / c.maxWidth) * 1440).clamp(0, 1440));

              return GestureDetector(
                onTapDown: (e) => buscar(e.localPosition),
                onHorizontalDragUpdate: (e) => buscar(e.localPosition),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    border: Border.all(color: Paleta.linea),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        for (final t in grabacion.tramos)
                          Positioned(
                            left: (t.inicio / 1440) * c.maxWidth,
                            width: ((t.fin - t.inicio) / 1440) * c.maxWidth,
                            top: 0,
                            bottom: 0,
                            child: const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0xFF2F7FE0), Color(0xFF1E63B8)],
                                ),
                              ),
                            ),
                          ),
                        for (final e in grabacion.eventos)
                          Positioned(
                            left: (e.minuto / 1440) * c.maxWidth - 2,
                            top: 0,
                            bottom: 0,
                            width: 4,
                            child: Tooltip(
                              message:
                                  '${tipoCamaraPorId(e.tipo).nombre} · ${e.hora}',
                              child: GestureDetector(
                                onTap: () => onEvento(e),
                                child: ColoredBox(
                                    color: tipoCamaraPorId(e.tipo).color),
                              ),
                            ),
                          ),
                        Positioned(
                          left: (minuto / 1440) * c.maxWidth - 1,
                          top: 0,
                          bottom: 0,
                          width: 2,
                          child: const ColoredBox(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 12,
            runSpacing: 5,
            children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 14,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F7FE0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 5),
                const Text('Grabado',
                    style: TextStyle(fontSize: 10, color: Paleta.texto2)),
              ]),
              for (final t in tiposEventoCamara)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 3, height: 11, color: t.color),
                  const SizedBox(width: 5),
                  Text(t.nombre,
                      style: const TextStyle(fontSize: 10, color: Paleta.texto2)),
                ]),
            ],
          ),
        ],
      );
}
