import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Imágenes satelitales de Esri World Imagery: sin API key ni tarjeta,
/// suficientes para el prototipo y para el mapa de la tablet.
const plantillaSatelite =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

const plantillaEtiquetas =
    'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

String urlTile(int x, int y, int z) =>
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';

/// Coordenadas de tile (fraccionarias) de un punto.
({double x, double y}) tileXY(LatLng p, int z) {
  final n = math.pow(2, z).toDouble();
  final x = (p.longitude + 180) / 360 * n;
  final r = p.latitude * math.pi / 180;
  final y = (1 - math.log(math.tan(r) + 1 / math.cos(r)) / math.pi) / 2 * n;
  return (x: x, y: y);
}

/// Mosaico 3×3 centrado en el punto, con el desfase sub-tile en fracción.
class Mosaico {
  const Mosaico(this.tiles, this.desfaseX, this.desfaseY, this.zoom);

  final List<({int x, int y})> tiles;
  final double desfaseX;
  final double desfaseY;
  final int zoom;

  factory Mosaico.en(LatLng p, {int zoom = 18}) {
    final t = tileXY(p, zoom);
    final bx = t.x.floor(), by = t.y.floor();
    final lista = <({int x, int y})>[];
    for (var dy = -1; dy <= 1; dy++) {
      for (var dx = -1; dx <= 1; dx++) {
        lista.add((x: bx + dx, y: by + dy));
      }
    }
    return Mosaico(lista, t.x - bx - 0.5, t.y - by - 0.5, zoom);
  }
}
