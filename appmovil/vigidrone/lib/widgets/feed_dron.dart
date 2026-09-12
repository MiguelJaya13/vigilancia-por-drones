import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show relojDia;
import '../datos/ciudadela.dart';
import '../tema.dart';
import 'comunes.dart';
import 'visor_tiles.dart';

/// Cámara del dron seleccionado, con sus modos y el gimbal.
class FeedDron extends StatefulWidget {
  const FeedDron({super.key, required this.dron, required this.ciudadela});

  final Dron? dron;
  final Ciudadela ciudadela;

  @override
  State<FeedDron> createState() => _FeedDronState();
}

class _FeedDronState extends State<FeedDron> {
  ModoCamara _modo = ModoCamara.rgb;
  double _gimbal = -60;

  @override
  Widget build(BuildContext context) {
    final d = widget.dron;
    final sinSenal = d == null || !d.estado.volando;
    final ahora = DateTime.now();
    final segundos = ahora.hour * 3600 + ahora.minute * 60 + ahora.second;

    return Panel(
      recorte: true,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Paleta.linea)),
            ),
            child: Row(
              children: [
                const Punto(Paleta.critico, tam: 7, pulsa: true),
                const SizedBox(width: 6),
                Text('REC',
                    style: etiqueta(Paleta.critico).copyWith(fontSize: 10)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(d?.nombre ?? 'Sin dron',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                ),
                Etiqueta(d == null ? '—' : 'Sector ${d.sectorId}'),
              ],
            ),
          ),

          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (sinSenal)
                  const ColoredBox(
                    color: Color(0xFF05080C),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.videocam_off_outlined,
                              size: 26, color: Paleta.texto3),
                          SizedBox(height: 8),
                          Text('Cámara en base',
                              style: TextStyle(
                                  fontSize: 11.5, color: Paleta.texto3)),
                        ],
                      ),
                    ),
                  )
                else
                  VisorTiles(
                    punto: d.posicion,
                    zoom: 19,
                    escala: 1.45 + (_gimbal + 90) / 190,
                    modo: _modo,
                  ),
                const CapaVideo(vineta: 0.4),
                if (!sinSenal) const _Mira(),
                Padding(
                  padding: const EdgeInsets.all(9),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: SelloVideo(
                            '${widget.ciudadela.codigo} · ${_nombreModo(_modo)}'),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: SelloVideo(relojDia(segundos)),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: SelloVideo(d == null
                            ? '—'
                            : '${d.posicion.latitude.toStringAsFixed(5)}, '
                                '${d.posicion.longitude.toStringAsFixed(5)}'),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SelloVideo('GIM ${_gimbal.round()}°'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 9, 12, 4),
            child: Row(
              children: [
                Segmentos<ModoCamara>(
                  opciones: const {
                    ModoCamara.rgb: 'RGB',
                    ModoCamara.ir: 'IR',
                    ModoCamara.termica: 'Térmica',
                  },
                  valor: _modo,
                  onCambio: (m) => setState(() => _modo = m),
                ),
                const SizedBox(width: 10),
                const Etiqueta('Gimbal'),
                Expanded(
                  child: Slider(
                    value: _gimbal,
                    min: -90,
                    max: 0,
                    onChanged: (v) => setState(() => _gimbal = v),
                  ),
                ),
              ],
            ),
          ),

          if (d != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Paleta.linea)),
              ),
              child: Row(
                children: [
                  Icon(Icons.signal_cellular_alt, size: 13, color: Paleta.texto2),
                  const SizedBox(width: 4),
                  Text('${d.senal}%', style: mono(tam: 10.5, color: Paleta.texto2)),
                  const SizedBox(width: 13),
                  Icon(Icons.satellite_alt, size: 13, color: Paleta.texto2),
                  const SizedBox(width: 4),
                  Text('${d.satelites}', style: mono(tam: 10.5, color: Paleta.texto2)),
                  const Spacer(),
                  Flexible(
                    child: Text(d.modelo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: mono(tam: 10.5, color: Paleta.texto2)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _nombreModo(ModoCamara m) => switch (m) {
        ModoCamara.rgb => 'RGB',
        ModoCamara.ir => 'IR',
        ModoCamara.termica => 'TÉRMICA',
        ModoCamara.nocturna => 'NOCTURNA',
      };
}

class _Mira extends StatelessWidget {
  const _Mira();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(painter: _PintorMira()),
      );
}

class _PintorMira extends CustomPainter {
  @override
  void paint(Canvas lienzo, Size tam) {
    final c = Offset(tam.width / 2, tam.height / 2);
    final lado = tam.shortestSide * 0.32;

    final linea = Paint()
      ..color = Colors.white.withValues(alpha: 0.75)
      ..strokeWidth = 1.3;
    final marco = Paint()
      ..color = Paleta.acento.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    lienzo.drawRect(Rect.fromCenter(center: c, width: lado, height: lado), marco);
    for (final d in [
      [Offset(c.dx, c.dy - lado * 0.85), Offset(c.dx, c.dy - lado * 0.55)],
      [Offset(c.dx, c.dy + lado * 0.55), Offset(c.dx, c.dy + lado * 0.85)],
      [Offset(c.dx - lado * 0.85, c.dy), Offset(c.dx - lado * 0.55, c.dy)],
      [Offset(c.dx + lado * 0.55, c.dy), Offset(c.dx + lado * 0.85, c.dy)],
    ]) {
      lienzo.drawLine(d[0], d[1], linea);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
