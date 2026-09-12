import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show selloFecha;
import '../datos/camaras.dart';
import '../tema.dart';
import 'visor_tiles.dart';

/// Un cuadro de cámara con la fecha y el nombre quemados encima, como el
/// frame que entrega un NVR. En producción sería el reproductor del stream.
class CeldaCamara extends StatelessWidget {
  const CeldaCamara({
    super.key,
    required this.camara,
    required this.fecha,
    required this.segundos,
    this.activa = false,
    this.onTap,
    this.zoom = 1,
    this.nocturna = true,
    this.calidadBaja = false,
    this.nombreGrande = false,
  });

  final Camara camara;
  final DateTime fecha;
  final num segundos;
  final bool activa;
  final VoidCallback? onTap;
  final double zoom;
  final bool nocturna;
  final bool calidadBaja;
  final bool nombreGrande;

  @override
  Widget build(BuildContext context) {
    // Cada cámara mira hacia un lado distinto: da variedad al mosaico.
    final giro = (camara.id.codeUnitAt(camara.id.length - 1) % 4) * 0.05 - 0.075;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF04070A),
          border: Border.all(
            color: activa ? Paleta.critico : Colors.transparent,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!camara.enLinea)
              const _SinSenal()
            else
              VisorTiles(
                punto: camara.posicion,
                zoom: calidadBaja ? 17 : 18,
                escala: 1.7 * zoom,
                giro: giro,
                modo: nocturna ? ModoCamara.nocturna : ModoCamara.rgb,
              ),
            if (camara.enLinea) const CapaVideo(),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  if (camara.enLinea)
                    Align(
                      alignment: Alignment.topLeft,
                      child: SelloVideo(selloFecha(fecha, segundos)),
                    ),
                  if (camara.enLinea && camara.ir && nocturna)
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Paleta.critico.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text('IR',
                            style: etiqueta(const Color(0xFFFCA5A5))
                                .copyWith(fontSize: 8.5)),
                      ),
                    ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      camara.nombre,
                      style: TextStyle(
                        fontSize: nombreGrande ? 17 : 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 5),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: SelloVideo(camara.id,
                        tam: 8.5, color: const Color(0x9EFFFFFF)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinSenal extends StatelessWidget {
  const _SinSenal();

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF0A0F15),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('SIN SEÑAL',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.6,
                    fontWeight: FontWeight.w700,
                    color: Paleta.critico,
                  )),
              const SizedBox(height: 4),
              const Text('Verificar alimentación PoE',
                  style: TextStyle(fontSize: 9.5, color: Paleta.texto3)),
            ],
          ),
        ),
      );
}

/// Hueco del mosaico cuando la página no llena la rejilla.
class CeldaVacia extends StatelessWidget {
  const CeldaVacia({super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF070B10),
        child: const Center(
          child: Text('Sin cámara',
              style: TextStyle(fontSize: 10.5, color: Paleta.texto3)),
        ),
      );
}
