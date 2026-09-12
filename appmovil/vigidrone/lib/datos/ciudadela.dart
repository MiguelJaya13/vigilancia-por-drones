import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Nivel de riesgo de un sector, que tiñe el croquis y el mapa.
enum Riesgo { bajo, medio, alto }

/// Estado operativo de un dron.
enum EstadoDron { enVuelo, retornando, enBase, cargando, sinSenal, manual }

extension EstadoDronTexto on EstadoDron {
  String get texto => switch (this) {
        EstadoDron.enVuelo => 'En vuelo',
        EstadoDron.retornando => 'Retornando',
        EstadoDron.enBase => 'En base',
        EstadoDron.cargando => 'Cargando',
        EstadoDron.sinSenal => 'Sin señal',
        EstadoDron.manual => 'Control manual',
      };

  bool get volando =>
      this == EstadoDron.enVuelo ||
      this == EstadoDron.retornando ||
      this == EstadoDron.manual;
}

class Sector {
  const Sector({
    required this.id,
    required this.nombre,
    required this.riesgo,
    required this.centro,
    required this.poligono,
  });

  final String id;
  final String nombre;
  final Riesgo riesgo;
  final LatLng centro;
  final List<LatLng> poligono;
}

class Dron {
  Dron({
    required this.id,
    required this.nombre,
    required this.modelo,
    required this.sectorId,
    required this.bateria,
    required this.estado,
    required this.ruta,
    required this.base,
  })  : posicion = ruta.first,
        rumbo = 0,
        altitud = estado.volando ? 42 : 0,
        velocidad = estado.volando ? 6 : 0,
        distanciaBase = 0,
        senal = 92,
        satelites = 15;

  final String id;
  final String nombre;
  final String modelo;
  final String sectorId;
  final List<LatLng> ruta;
  final LatLng base;

  double bateria;
  EstadoDron estado;
  LatLng posicion;
  double rumbo;
  double altitud;
  double velocidad;
  int distanciaBase;
  int senal;
  int satelites;

  /// Avance acumulado sobre la ruta, en índices de waypoint.
  double progreso = 0;
  double paso = 0.012;
  double fase = 0;
  double altitudBase = 42;
  double velocidadBase = 6;

  /// Código corto para rótulos: 'D2'.
  String get codigo => id.split('-').last;
}

class Ciudadela {
  const Ciudadela({
    required this.codigo,
    required this.nombre,
    required this.direccion,
    required this.centro,
    required this.perimetro,
    required this.sectores,
    required this.drones,
    required this.radioGeocerca,
    required this.camaras,
    required this.viviendas,
    required this.alturaMaxima,
  });

  final String codigo;
  final String nombre;
  final String direccion;
  final LatLng centro;
  final List<LatLng> perimetro;
  final List<Sector> sectores;
  final List<Dron> drones;
  final double radioGeocerca;
  final int camaras;
  final int viviendas;
  final int alturaMaxima;

  Sector sectorPorId(String id) =>
      sectores.firstWhere((s) => s.id == id, orElse: () => sectores.first);
}

// ---------------------------------------------------------------------------
// Geometría: metros a grados según la latitud, para que el recinto mida en el
// mapa lo que dice medir.
// ---------------------------------------------------------------------------

const double _mPorGradoLat = 110540;
const double _mPorGradoLng = 111320;

({double dLng, double dLat}) _aGrados(double mx, double my, double lat) => (
      dLng: mx / (_mPorGradoLng * math.cos(lat * math.pi / 180)),
      dLat: my / _mPorGradoLat,
    );

List<LatLng> _rect(LatLng c, double ancho, double alto) {
  final g = _aGrados(ancho / 2, alto / 2, c.latitude);
  return [
    LatLng(c.latitude - g.dLat, c.longitude - g.dLng),
    LatLng(c.latitude - g.dLat, c.longitude + g.dLng),
    LatLng(c.latitude + g.dLat, c.longitude + g.dLng),
    LatLng(c.latitude + g.dLat, c.longitude - g.dLng),
  ];
}

/// Distancia aproximada en metros entre dos puntos.
double distanciaM(LatLng a, LatLng b) {
  final dx = (a.longitude - b.longitude) *
      _mPorGradoLng *
      math.cos(a.latitude * math.pi / 180);
  final dy = (a.latitude - b.latitude) * _mPorGradoLat;
  return math.sqrt(dx * dx + dy * dy);
}

/// Desplaza un punto los metros indicados hacia el este y el norte.
LatLng desplazar(LatLng p, double metrosEste, double metrosNorte) {
  final g = _aGrados(metrosEste, metrosNorte, p.latitude);
  return LatLng(p.latitude + g.dLat, p.longitude + g.dLng);
}

// ---------------------------------------------------------------------------
// La ciudadela que vigila esta instalación.
//
// Centro verificado contra la imagen satelital y nombrado por geocodificación
// inversa de OpenStreetMap: cae sobre manzanas urbanizadas, no sobre el río.
// Cada instalación de VigiDrone atiende una sola ciudadela: para desplegar en
// otra, basta cambiar estas constantes.
// ---------------------------------------------------------------------------

const LatLng _centro = LatLng(-2.150069, -79.867859);
const double _ancho = 460;
const double _alto = 340;

const _sectoresDef = [
  ('A', 'Garita principal', Riesgo.medio),
  ('B', 'Área social y club', Riesgo.bajo),
  ('C', 'Ribera del río', Riesgo.alto),
  ('D', 'Manzanas 12-20', Riesgo.medio),
];

const _dronesDef = [
  ('D1', 'HalcónCat', 'DJI Matrice 30T', 'A', 72.0, EstadoDron.enVuelo),
  ('D2', 'Vigía 02', 'DJI Mavic 3E', 'B', 64.0, EstadoDron.enVuelo),
  ('D3', 'Vigía 03', 'DJI Mavic 3E', 'C', 91.0, EstadoDron.enVuelo),
  ('D4', 'Centinela 04', 'Autel EVO II', 'D', 38.0, EstadoDron.retornando),
  ('D5', 'Centinela 05', 'Autel EVO II', 'A', 100.0, EstadoDron.enBase),
];

Ciudadela construirCiudadela() {
  final qa = _ancho / 2, qh = _alto / 2;
  final g = _aGrados(qa / 2, qh / 2, _centro.latitude);

  // Cuadrantes: A noroeste, B noreste, C suroeste, D sureste.
  final centrosSector = <String, LatLng>{
    'A': LatLng(_centro.latitude + g.dLat, _centro.longitude - g.dLng),
    'B': LatLng(_centro.latitude + g.dLat, _centro.longitude + g.dLng),
    'C': LatLng(_centro.latitude - g.dLat, _centro.longitude - g.dLng),
    'D': LatLng(_centro.latitude - g.dLat, _centro.longitude + g.dLng),
  };

  final sectores = [
    for (final (id, nombre, riesgo) in _sectoresDef)
      Sector(
        id: id,
        nombre: nombre,
        riesgo: riesgo,
        centro: centrosSector[id]!,
        poligono: _rect(centrosSector[id]!, qa - 26, qh - 26),
      ),
  ];

  final drones = <Dron>[];
  final usados = <String, int>{};
  for (var i = 0; i < _dronesDef.length; i++) {
    final (sufijo, nombre, modelo, sectorId, bateria, estado) = _dronesDef[i];
    final v = usados[sectorId] = (usados[sectorId] ?? -1) + 1;
    final c = centrosSector[sectorId]!;
    // Barrido en serpentina dentro del sector; el margen separa a dos drones
    // que comparten sector.
    final margen = 30.0 + v * 22;
    final rx = qa / 2 - margen, ry = qh / 2 - margen;
    final ruta = [
      desplazar(c, -rx, ry),
      desplazar(c, rx, ry),
      desplazar(c, rx, 0),
      desplazar(c, -rx, 0),
      desplazar(c, -rx, -ry),
      desplazar(c, rx, -ry),
    ];

    final d = Dron(
      id: 'ER-$sufijo',
      nombre: nombre,
      modelo: modelo,
      sectorId: sectorId,
      bateria: bateria,
      estado: estado,
      ruta: ruta,
      base: _centro,
    );
    d.paso = 0.010 + (i % 3) * 0.004;
    d.fase = i * 1.7;
    d.altitudBase = 38 + i * 7;
    d.velocidadBase = 5.5 + (i % 4);
    d.altitud = estado.volando ? d.altitudBase : 0;
    d.velocidad = estado.volando ? d.velocidadBase : 0;
    d.distanciaBase = distanciaM(d.posicion, _centro).round();
    drones.add(d);
  }

  return Ciudadela(
    codigo: 'ER',
    nombre: 'Ciudadela Entre Ríos',
    direccion: 'Vía a Samborondón · Samborondón',
    centro: _centro,
    perimetro: _rect(_centro, _ancho, _alto),
    sectores: sectores,
    drones: drones,
    radioGeocerca: math.max(_ancho, _alto) * 0.6,
    camaras: 24,
    viviendas: 312,
    alturaMaxima: 120,
  );
}
