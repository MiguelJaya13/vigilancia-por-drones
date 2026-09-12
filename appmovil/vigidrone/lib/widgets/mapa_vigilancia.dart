import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../datos/ciudadela.dart';
import '../tema.dart';
import '../util/tiles.dart';
import 'icono_dron.dart';

/// Mapa satelital del recinto: geocerca, perímetro, sectores, rutas de
/// patrullaje y la flota en movimiento.
class MapaVigilancia extends StatelessWidget {
  const MapaVigilancia({
    super.key,
    required this.ciudadela,
    required this.controlador,
    required this.dronActivo,
    required this.sectorActivo,
    required this.onDron,
    required this.onSector,
    this.verGeocerca = true,
    this.verSectores = true,
    this.verRutas = true,
  });

  final Ciudadela ciudadela;
  final MapController controlador;
  final Dron? dronActivo;
  final String? sectorActivo;
  final ValueChanged<Dron> onDron;
  final ValueChanged<String> onSector;
  final bool verGeocerca;
  final bool verSectores;
  final bool verRutas;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controlador,
      options: MapOptions(
        initialCenter: ciudadela.centro,
        initialZoom: 17.1,
        minZoom: 14,
        maxZoom: 19,
        backgroundColor: const Color(0xFF0A1016),
      ),
      children: [
        TileLayer(
          urlTemplate: plantillaSatelite,
          userAgentPackageName: 'ec.falcom360.vigidrone',
          maxNativeZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),
        TileLayer(
          urlTemplate: plantillaEtiquetas,
          userAgentPackageName: 'ec.falcom360.vigidrone',
          maxNativeZoom: 19,
          tileProvider: NetworkTileProvider(),
        ),

        if (verGeocerca)
          CircleLayer(
            circles: [
              CircleMarker(
                point: ciudadela.centro,
                radius: ciudadela.radioGeocerca,
                useRadiusInMeter: true,
                color: Paleta.acento.withValues(alpha: 0.10),
                borderColor: Paleta.acento.withValues(alpha: 0.65),
                borderStrokeWidth: 2,
              ),
            ],
          ),

        if (verSectores)
          PolygonLayer(
            polygons: [
              for (final s in ciudadela.sectores)
                Polygon(
                  points: s.poligono,
                  color: Paleta.porRiesgo[s.riesgo]!
                      .withValues(alpha: sectorActivo == s.id ? 0.42 : 0.13),
                  borderColor: Paleta.porRiesgo[s.riesgo]!,
                  borderStrokeWidth: sectorActivo == s.id ? 3 : 1.4,
                ),
            ],
          ),

        PolygonLayer(
          polygons: [
            Polygon(
              points: ciudadela.perimetro,
              color: Colors.transparent,
              borderColor: Paleta.texto,
              borderStrokeWidth: 2.2,
            ),
          ],
        ),

        if (verRutas)
          PolylineLayer(
            polylines: [
              for (final d in ciudadela.drones)
                Polyline(
                  points: [...d.ruta, d.ruta.first],
                  color: Colors.white.withValues(alpha: 0.42),
                  strokeWidth: 1.2,
                ),
            ],
          ),

        // Etiquetas de sector.
        if (verSectores)
          MarkerLayer(
            markers: [
              for (final s in ciudadela.sectores)
                Marker(
                  point: s.centro,
                  width: 118,
                  height: 36,
                  alignment: Alignment.center,
                  child: _EtiquetaSector(
                    sector: s,
                    activo: sectorActivo == s.id,
                    onTap: () => onSector(s.id),
                  ),
                ),
            ],
          ),

        // Flota.
        MarkerLayer(
          markers: [
            for (final d in ciudadela.drones)
              Marker(
                point: d.posicion,
                width: 118,
                height: 62,
                alignment: Alignment.center,
                child: _MarcadorDron(
                  dron: d,
                  activo: d.id == dronActivo?.id,
                  onTap: () => onDron(d),
                ),
              ),
          ],
        ),

        // Base de despegue.
        MarkerLayer(
          markers: [
            Marker(
              point: ciudadela.centro,
              width: 26,
              height: 26,
              child: const _Base(),
            ),
          ],
        ),
      ],
    );
  }
}

class _EtiquetaSector extends StatelessWidget {
  const _EtiquetaSector({
    required this.sector,
    required this.activo,
    required this.onTap,
  });

  final Sector sector;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Paleta.porRiesgo[sector.riesgo]!;
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF060A0F).withValues(alpha: activo ? 0.94 : 0.72),
            border: Border.all(color: c.withValues(alpha: 0.6)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(sector.id,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: c,
                      height: 1.1)),
              Text(sector.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 9, color: Color(0xCCFFFFFF), height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MarcadorDron extends StatelessWidget {
  const _MarcadorDron({
    required this.dron,
    required this.activo,
    required this.onTap,
  });

  final Dron dron;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final enBase = !dron.estado.volando;
    final color = enBase ? Paleta.texto3 : Paleta.acento;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: activo ? color : const Color(0xE6080E14),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.6),
              boxShadow: [
                if (activo)
                  BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 12),
              ],
            ),
            child: Center(
              child: IconoDron(
                tam: 20,
                rumbo: dron.rumbo,
                girando: !enBase,
                color: activo ? const Color(0xFF04141A) : color,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xDB060A0F),
              border: Border.all(color: Paleta.linea),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(dron.codigo,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w800, height: 1.2)),
                Text('${dron.altitud.round()} m · ${dron.bateria.round()}%',
                    style: mono(tam: 8.5, color: Paleta.texto2)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Base extends StatelessWidget {
  const _Base();

  @override
  Widget build(BuildContext context) => Tooltip(
        message: 'Base de despegue',
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
          ),
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
}
