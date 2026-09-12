import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../tema.dart';
import '../util/tiles.dart';

/// Modos de cámara. En producción cambiarían el stream del dron; aquí
/// cambian el filtro de color sobre la imagen satelital.
enum ModoCamara { rgb, ir, termica, nocturna }

const _filtros = <ModoCamara, List<double>>{
  // Matrices 4x5 aplicadas sobre RGBA.
  ModoCamara.rgb: [
    1.06, 0, 0, 0, 0,
    0, 1.06, 0, 0, 0,
    0, 0, 1.06, 0, 0,
    0, 0, 0, 1, 0,
  ],
  // Escala de grises invertida: el aspecto del canal infrarrojo.
  ModoCamara.ir: [
    -0.9, -0.5, -0.2, 0, 255,
    -0.9, -0.5, -0.2, 0, 255,
    -0.9, -0.5, -0.2, 0, 255,
    0, 0, 0, 1, 0,
  ],
  // Falso color térmico: frío azulado, caliente anaranjado.
  ModoCamara.termica: [
    1.8, 0.6, -0.6, 0, -60,
    0.5, 0.5, 0.4, 0, -30,
    -0.5, 0.2, 1.9, 0, 10,
    0, 0, 0, 1, 0,
  ],
  // Visión nocturna de cámara fija: oscura y desaturada.
  ModoCamara.nocturna: [
    0.42, 0.16, 0.06, 0, 0,
    0.16, 0.46, 0.08, 0, 0,
    0.10, 0.16, 0.40, 0, 0,
    0, 0, 0, 1, 0,
  ],
};

/// Mosaico de imágenes satelitales usado como "lo que ve la cámara".
///
/// En producción este widget sería el reproductor del stream (HLS/WebRTC);
/// la interfaz alrededor no cambiaría.
class VisorTiles extends StatelessWidget {
  const VisorTiles({
    super.key,
    required this.punto,
    this.zoom = 18,
    this.escala = 1.6,
    this.modo = ModoCamara.rgb,
    this.giro = 0,
  });

  final LatLng punto;
  final int zoom;
  final double escala;
  final ModoCamara modo;
  final double giro;

  @override
  Widget build(BuildContext context) {
    final mosaico = Mosaico.en(punto, zoom: zoom);

    return ColorFiltered(
      colorFilter: ColorFilter.matrix(_filtros[modo]!),
      child: LayoutBuilder(
        builder: (context, c) {
          final lado = (c.maxWidth > c.maxHeight ? c.maxWidth : c.maxHeight) *
              escala;
          return ClipRect(
            child: Transform.rotate(
              angle: giro,
              child: Stack(
                children: [
                  Positioned(
                    left: c.maxWidth / 2 - lado * (1.5 + mosaico.desfaseX),
                    top: c.maxHeight / 2 - lado * (1.5 + mosaico.desfaseY),
                    width: lado * 3,
                    height: lado * 3,
                    child: Column(
                      children: [
                        for (var fila = 0; fila < 3; fila++)
                          Row(
                            children: [
                              for (var col = 0; col < 3; col++)
                                _Tile(
                                  mosaico.tiles[fila * 3 + col],
                                  mosaico.zoom,
                                  lado,
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.t, this.zoom, this.lado);

  final ({int x, int y}) t;
  final int zoom;
  final double lado;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: lado,
        height: lado,
        child: Image.network(
          urlTile(t.x, t.y, zoom),
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF0A1016)),
          loadingBuilder: (_, hijo, progreso) =>
              progreso == null ? hijo : const ColoredBox(color: Color(0xFF0A1016)),
        ),
      );
}

/// Viñeta y líneas de barrido: hacen que la imagen lea como video de cámara.
class CapaVideo extends StatelessWidget {
  const CapaVideo({super.key, this.vineta = 0.55});

  final double vineta;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.9,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: vineta),
              ],
              stops: const [0.45, 1],
            ),
          ),
          child: const SizedBox.expand(),
        ),
      );
}

/// Rótulo sobreimpreso en el video (fecha, nombre, coordenadas).
class SelloVideo extends StatelessWidget {
  const SelloVideo(
    this.texto, {
    super.key,
    this.tam = 10,
    this.color = Colors.white,
    this.peso = FontWeight.w600,
  });

  final String texto;
  final double tam;
  final Color color;
  final FontWeight peso;

  @override
  Widget build(BuildContext context) => Text(
        texto,
        style: mono(tam: tam, peso: peso, color: color).copyWith(
          shadows: const [
            Shadow(color: Colors.black, blurRadius: 4),
            Shadow(color: Colors.black, blurRadius: 1, offset: Offset(0, 1)),
          ],
        ),
      );
}
