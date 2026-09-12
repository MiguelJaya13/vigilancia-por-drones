import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../datos/ciudadela.dart';

enum TipoEvento { info, alerta, critico }

class EventoRegistro {
  EventoRegistro({
    required this.hora,
    required this.dron,
    required this.sector,
    required this.texto,
    required this.tipo,
  });

  final DateTime hora;
  final String dron;
  final String sector;
  final String texto;
  final TipoEvento tipo;
}

const _eventosSim = [
  ('Barrido térmico completado', TipoEvento.info),
  ('Movimiento detectado en vía interna', TipoEvento.alerta),
  ('Waypoint alcanzado, continuando ruta', TipoEvento.info),
  ('Vehículo no registrado en garita', TipoEvento.alerta),
  ('Señal de video estabilizada', TipoEvento.info),
  ('Cruce de geocerca detectado', TipoEvento.critico),
  ('Batería bajo el 30%, evaluando retorno', TipoEvento.alerta),
  ('Ronda perimetral sin novedad', TipoEvento.info),
];

/// Telemetría en vivo de la flota: mueve cada dron por su ruta de patrullaje,
/// consume batería y alimenta el registro de actividad.
///
/// En producción este objeto se alimentaría del enlace MQTT del dock; la
/// interfaz no cambiaría, solo la fuente de los datos.
class Simulador extends ChangeNotifier {
  Simulador(this.ciudadela) {
    _registro.addAll([
      EventoRegistro(
        hora: DateTime.now().subtract(const Duration(seconds: 95)),
        dron: ciudadela.drones.first.nombre,
        sector: 'A',
        texto: 'Misión de patrullaje iniciada',
        tipo: TipoEvento.info,
      ),
      EventoRegistro(
        hora: DateTime.now().subtract(const Duration(seconds: 190)),
        dron: ciudadela.drones[1].nombre,
        sector: 'B',
        texto: 'Enlace de video 4K establecido',
        tipo: TipoEvento.info,
      ),
    ]);
    iniciar();
  }

  final Ciudadela ciudadela;
  final _registro = <EventoRegistro>[];
  final _azar = math.Random(7);

  Timer? _reloj;
  int _tic = 0;
  bool _pausado = false;

  List<Dron> get flota => ciudadela.drones;
  List<EventoRegistro> get registro => List.unmodifiable(_registro);
  bool get pausado => _pausado;
  int get alertas => _registro.where((e) => e.tipo != TipoEvento.info).length;

  void iniciar() {
    _reloj?.cancel();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void alternarPausa() {
    _pausado = !_pausado;
    notifyListeners();
  }

  /// Manda el dron de vuelta a la base (Return To Home).
  void retornar(Dron d) {
    d.estado = EstadoDron.retornando;
    _anotar(d, 'Retorno a base ordenado por el operador', TipoEvento.alerta);
    notifyListeners();
  }

  /// Aterriza el dron en el punto donde está.
  void aterrizar(Dron d) {
    d.estado = EstadoDron.enBase;
    d.altitud = 0;
    d.velocidad = 0;
    _anotar(d, 'Aterrizaje ordenado por el operador', TipoEvento.alerta);
    notifyListeners();
  }

  /// Reanuda el patrullaje autónomo.
  void despegar(Dron d) {
    d.estado = EstadoDron.enVuelo;
    _anotar(d, 'Patrullaje autónomo reanudado', TipoEvento.info);
    notifyListeners();
  }

  void _tick() {
    if (_pausado) return;
    _tic++;

    for (final d in flota) {
      if (!d.estado.volando) {
        if (d.estado == EstadoDron.cargando) {
          d.bateria = math.min(100, d.bateria + 0.35);
          if (d.bateria >= 99.5) d.estado = EstadoDron.enBase;
        }
        d.velocidad = 0;
        d.altitud = 0;
        continue;
      }

      d.progreso += d.paso;
      final i = d.progreso.floor() % d.ruta.length;
      final j = (i + 1) % d.ruta.length;
      final t = d.progreso - d.progreso.floor();
      final a = d.ruta[i], b = d.ruta[j];

      d.posicion = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      d.rumbo = _rumbo(a, b);
      d.bateria = math.max(0, d.bateria - 0.05);
      if (d.bateria < 20 && d.estado == EstadoDron.enVuelo) {
        d.estado = EstadoDron.retornando;
        _anotar(d, 'Batería bajo el 20%, retorno automático', TipoEvento.alerta);
      }
      d.altitud = d.altitudBase + math.sin(_tic / 6 + d.fase) * 1.8;
      d.velocidad = d.velocidadBase + math.sin(_tic / 4 + d.fase) * 0.9;
      d.distanciaBase = distanciaM(d.posicion, d.base).round();
      d.senal = 88 + (math.sin(_tic / 9 + d.fase) * 10).round();
      d.satelites = 14 + (math.sin(_tic / 11 + d.fase) * 3).round();
    }

    if (_tic % 7 == 0) {
      final activos = flota.where((d) => d.estado.volando).toList();
      if (activos.isNotEmpty) {
        final d = activos[_azar.nextInt(activos.length)];
        final (texto, tipo) = _eventosSim[_azar.nextInt(_eventosSim.length)];
        _anotar(d, texto, tipo);
      }
    }

    notifyListeners();
  }

  void _anotar(Dron d, String texto, TipoEvento tipo) {
    _registro.insert(
      0,
      EventoRegistro(
        hora: DateTime.now(),
        dron: d.nombre,
        sector: d.sectorId,
        texto: texto,
        tipo: tipo,
      ),
    );
    if (_registro.length > 60) _registro.removeLast();
  }

  double _rumbo(LatLng a, LatLng b) {
    final dx = (b.longitude - a.longitude) *
        math.cos(a.latitude * math.pi / 180);
    final dy = b.latitude - a.latitude;
    return math.atan2(dx, dy) * 180 / math.pi;
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }
}
