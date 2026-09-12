import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../tema.dart';
import 'aleatorio.dart';
import 'bitacora.dart' show isoDe;
import 'ciudadela.dart';

class Camara {
  const Camara({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    required this.sectorId,
    required this.sectorNombre,
    required this.tipo,
    required this.audio,
    required this.ir,
    required this.resolucion,
    required this.bitrate,
    required this.enLinea,
    required this.posicion,
  });

  final String id;
  final String nombre;
  final String ubicacion;
  final String sectorId;
  final String sectorNombre;
  final String tipo;
  final bool audio;
  final bool ir;
  final String resolucion;
  final int bitrate;
  final bool enLinea;
  final LatLng posicion;

  bool get ptz => tipo == 'PTZ';
}

const _ubicaciones = [
  'Carril de ingreso', 'Carril de salida', 'Garita — peatonal',
  'Muro perimetral', 'Vía interna', 'Área de juegos', 'Cancha múltiple',
  'Piscina', 'Parqueadero de visitas', 'Portón vehicular', 'Esquina norte',
  'Esquina sur', 'Callejón de servicio', 'Acceso a bodegas', 'Zona de basura',
  'Puerta de servicio', 'Ciclovía', 'Plazoleta central', 'Ingreso al club',
  'Paso peatonal',
];

const _tipos = ['Fija', 'Fija', 'Fija', 'PTZ', 'LPR', 'Térmica'];

/// Las cámaras fijas de la ciudadela: el NVR de la urbanización.
List<Camara> camarasDe(Ciudadela cd) {
  final r = Aleatorio('cam|${cd.codigo}');
  return List.generate(cd.camaras, (i) {
    final sector = cd.sectores[i % cd.sectores.length];
    final tipo = r.elemento(_tipos);
    final offline = r.probabilidad(0.07);
    final jx = (r.siguiente() - 0.5) * 0.0016;
    final jy = (r.siguiente() - 0.5) * 0.0011;

    return Camara(
      id: '${cd.codigo}-CAM${(i + 1).toString().padLeft(2, '0')}',
      nombre: 'Cámara ${(i + 1).toString().padLeft(2, '0')}',
      ubicacion: r.elemento(_ubicaciones),
      sectorId: sector.id,
      sectorNombre: sector.nombre,
      tipo: tipo,
      audio: r.probabilidad(0.55),
      ir: r.probabilidad(0.7),
      resolucion: r.probabilidad(0.6) ? '4MP · 2560×1440' : '1080p · 1920×1080',
      bitrate: 1400 + r.entero(3200),
      enLinea: !offline,
      posicion: LatLng(sector.centro.latitude + jy, sector.centro.longitude + jx),
    );
  });
}

class TipoEventoCamara {
  const TipoEventoCamara(this.id, this.nombre, this.color);
  final String id;
  final String nombre;
  final Color color;
}

const tiposEventoCamara = <TipoEventoCamara>[
  TipoEventoCamara('movimiento', 'Movimiento', Paleta.violeta),
  TipoEventoCamara('persona', 'Persona detectada', Paleta.alerta),
  TipoEventoCamara('vehiculo', 'Vehículo', Paleta.acento),
  TipoEventoCamara('linea', 'Cruce de línea', Paleta.naranja),
  TipoEventoCamara('manipulacion', 'Manipulación de cámara', Paleta.critico),
];

TipoEventoCamara tipoCamaraPorId(String id) => tiposEventoCamara
    .firstWhere((t) => t.id == id, orElse: () => tiposEventoCamara.first);

class EventoCamara {
  const EventoCamara({
    required this.id,
    required this.minuto,
    required this.tipo,
    required this.duracion,
    required this.camara,
  });

  final String id;
  final int minuto;
  final String tipo;
  final int duracion;
  final Camara camara;

  String get hora =>
      '${(minuto ~/ 60).toString().padLeft(2, '0')}:${(minuto % 60).toString().padLeft(2, '0')}';
}

class Tramo {
  const Tramo(this.inicio, this.fin);
  final int inicio;
  final int fin;
}

class GrabacionCamara {
  const GrabacionCamara({
    required this.tramos,
    required this.eventos,
    required this.finDia,
  });

  final List<Tramo> tramos;
  final List<EventoCamara> eventos;
  final int finDia;

  int get minutosGrabados =>
      tramos.fold<int>(0, (s, t) => s + (t.fin - t.inicio));
}

/// Grabación del día de una cámara: tramos realmente grabados (el NVR corta
/// por reinicios o pérdida de enlace) y marcas de evento.
GrabacionCamara grabacionCamara(Camara cam, DateTime dia) {
  final hoy = DateTime.now();
  final esHoy = isoDe(dia) == isoDe(hoy);
  final finDia = esHoy ? hoy.hour * 60 + hoy.minute : 1440;
  final r = Aleatorio('${cam.id}|${isoDe(dia)}');

  final cortes = r.entero(4);
  final huecos = List.generate(cortes, (_) {
    final inicio = r.entero(finDia > 40 ? finDia - 40 : 1);
    return Tramo(inicio, inicio + 4 + r.entero(26));
  })..sort((a, b) => a.inicio.compareTo(b.inicio));

  final tramos = <Tramo>[];
  var cursor = 0;
  for (final h in huecos) {
    if (h.inicio > cursor) {
      tramos.add(Tramo(cursor, h.fin.clamp(0, finDia) > h.inicio
          ? h.inicio.clamp(0, finDia)
          : cursor));
    }
    cursor = cursor > h.fin ? cursor : h.fin.clamp(0, finDia);
  }
  if (cursor < finDia) tramos.add(Tramo(cursor, finDia));
  tramos.removeWhere((t) => t.fin <= t.inicio);

  final total = 6 + r.entero(16);
  final eventos = <EventoCamara>[];
  for (var i = 0; i < total; i++) {
    var minuto = r.entero(finDia > 0 ? finDia : 1);
    if (r.probabilidad(0.35)) {
      minuto = r.entero(finDia < 360 ? (finDia > 0 ? finDia : 1) : 360);
    }
    final dentro = tramos.any((t) => minuto >= t.inicio && minuto < t.fin);
    if (!dentro) continue;
    eventos.add(EventoCamara(
      id: '${cam.id}-${isoDe(dia)}-$i',
      minuto: minuto,
      tipo: r.elemento(tiposEventoCamara).id,
      duracion: 20 + r.entero(160),
      camara: cam,
    ));
  }
  eventos.sort((a, b) => a.minuto.compareTo(b.minuto));

  return GrabacionCamara(tramos: tramos, eventos: eventos, finDia: finDia);
}
