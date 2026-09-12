import 'package:flutter/material.dart';

import '../tema.dart';
import 'aleatorio.dart';
import 'ciudadela.dart';

class TipoEventoBitacora {
  const TipoEventoBitacora(this.id, this.nombre, this.color, this.peso);
  final String id;
  final String nombre;
  final Color color;
  final int peso;
}

const tiposEvento = <TipoEventoBitacora>[
  TipoEventoBitacora('patrullaje', 'Patrullaje rutinario', Paleta.acento, 58),
  TipoEventoBitacora('movimiento', 'Movimiento detectado', Paleta.violeta, 18),
  TipoEventoBitacora('vehiculo', 'Vehículo no registrado', Paleta.alerta, 12),
  TipoEventoBitacora('perimetro', 'Alerta perimetral', Paleta.naranja, 8),
  TipoEventoBitacora('intrusion', 'Intrusión confirmada', Paleta.critico, 4),
];

TipoEventoBitacora tipoPorId(String id) =>
    tiposEvento.firstWhere((t) => t.id == id, orElse: () => tiposEvento.first);

const _detalles = <String, List<String>>{
  'patrullaje': [
    'Recorrido perimetral completo sin novedad',
    'Barrido térmico programado, sin hallazgos',
    'Verificación de puntos ciegos de cámaras fijas',
    'Ronda nocturna con iluminación IR',
  ],
  'movimiento': [
    'Movimiento en zona verde, descartado (fauna)',
    'Persona no identificada por vía interna',
    'Actividad fuera de horario en área común',
    'Grupo de personas en cancha fuera de horario',
  ],
  'vehiculo': [
    'Vehículo sin registro en garita, placa capturada',
    'Camioneta estacionada en zona prohibida 14 min',
    'Motocicleta circulando sin autorización',
    'Vehículo de carga sin orden de ingreso',
  ],
  'perimetro': [
    'Cruce de geocerca en muro perimetral',
    'Objeto arrojado sobre el cerramiento',
    'Escalamiento detectado en muro posterior',
    'Apertura no autorizada de puerta de servicio',
  ],
  'intrusion': [
    'Intrusión confirmada, alerta enviada a guardia',
    'Persona dentro del predio sin autorización, 911 notificado',
    'Ingreso forzado detectado, seguimiento activo',
  ],
};

class Grabacion {
  const Grabacion({
    required this.id,
    required this.fecha,
    required this.minutoDia,
    required this.duracion,
    required this.sectorId,
    required this.sectorNombre,
    required this.dronNombre,
    required this.tipo,
    required this.detalle,
    required this.resolucion,
    required this.camara,
    required this.pesoMB,
    required this.revisado,
  });

  final String id;
  final DateTime fecha;
  final int minutoDia;
  final int duracion; // segundos
  final String sectorId;
  final String sectorNombre;
  final String dronNombre;
  final String tipo;
  final String detalle;
  final String resolucion;
  final String camara;
  final int pesoMB;
  final bool revisado;

  String get hora => '${_dd(minutoDia ~/ 60)}:${_dd(minutoDia % 60)}';
}

String _dd(int n) => n.toString().padLeft(2, '0');

String isoDe(DateTime d) => '${d.year}-${_dd(d.month)}-${_dd(d.day)}';

/// Duración en m:ss.
String duracionTexto(int segundos) =>
    '${segundos ~/ 60}:${_dd(segundos % 60)}';

/// Reloj hh:mm:ss a partir de los segundos del día.
String relojDia(num segundos) {
  final s = segundos.floor().clamp(0, 86399);
  return '${_dd(s ~/ 3600)}:${_dd((s ~/ 60) % 60)}:${_dd(s % 60)}';
}

const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];
const _diasSemana = [
  'lunes', 'martes', 'miércoles', 'jueves', 'viernes', 'sábado', 'domingo',
];

String fechaLarga(DateTime d) =>
    '${_diasSemana[d.weekday - 1]} ${d.day} de ${_meses[d.month - 1]} de ${d.year}';

/// Sello de fecha y hora como el que graba el NVR sobre la imagen.
String selloFecha(DateTime fecha, num segundos) {
  const abrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  return '${_dd(fecha.day)}-${_dd(fecha.month)}-${fecha.year} '
      '${abrev[fecha.weekday - 1]} ${relojDia(segundos)}';
}

/// Grabaciones de un día. Misma fecha ⇒ mismos registros.
List<Grabacion> grabacionesDe(Ciudadela cd, DateTime dia) {
  final iso = isoDe(dia);
  final r = Aleatorio('${cd.codigo}|$iso');
  final total = 26 + r.entero(18);
  final lista = <Grabacion>[];

  for (var i = 0; i < total; i++) {
    final minuto = r.entero(1440);
    final hora = minuto ~/ 60;
    final sector = r.elemento(cd.sectores);
    final dron = r.elemento(cd.drones);

    var tipo = _tipoPonderado(r);
    if (hora >= 1 && hora <= 5 && r.probabilidad(0.4)) {
      tipo = r.elemento(const ['movimiento', 'perimetro', 'intrusion']);
    }
    if (hora >= 9 && hora <= 16 && r.probabilidad(0.5)) tipo = 'patrullaje';

    final duracion = tipo == 'patrullaje'
        ? 240 + r.entero(900)
        : 45 + r.entero(420);
    final cuatroK = r.probabilidad(0.65);

    lista.add(Grabacion(
      id: '$iso-$i',
      fecha: DateTime(dia.year, dia.month, dia.day),
      minutoDia: minuto,
      duracion: duracion,
      sectorId: sector.id,
      sectorNombre: sector.nombre,
      dronNombre: dron.nombre,
      tipo: tipo,
      detalle: r.elemento(_detalles[tipo]!),
      resolucion: cuatroK ? '4K · 30fps' : '1080p · 60fps',
      camara: r.probabilidad(0.5) ? 'RGB + Térmica' : 'RGB',
      pesoMB: ((duracion / 60) * (cuatroK ? 210 : 95)).round(),
      revisado: r.probabilidad(0.55),
    ));
  }

  lista.sort((a, b) => a.minutoDia.compareTo(b.minutoDia));
  return lista;
}

String _tipoPonderado(Aleatorio r) {
  final total = tiposEvento.fold<int>(0, (s, t) => s + t.peso);
  var v = r.siguiente() * total;
  for (final t in tiposEvento) {
    v -= t.peso;
    if (v <= 0) return t.id;
  }
  return 'patrullaje';
}

class ResumenDia {
  const ResumenDia({
    required this.segmentos,
    required this.horas,
    required this.alertas,
    required this.criticas,
    required this.almacenamientoGB,
    required this.pendientes,
  });

  final int segmentos;
  final double horas;
  final int alertas;
  final int criticas;
  final double almacenamientoGB;
  final int pendientes;
}

ResumenDia resumenDe(List<Grabacion> gs) {
  final seg = gs.fold<int>(0, (s, g) => s + g.duracion);
  final mb = gs.fold<int>(0, (s, g) => s + g.pesoMB);
  return ResumenDia(
    segmentos: gs.length,
    horas: seg / 3600,
    alertas: gs.where((g) => g.tipo != 'patrullaje').length,
    criticas: gs
        .where((g) => g.tipo == 'intrusion' || g.tipo == 'perimetro')
        .length,
    almacenamientoGB: mb / 1024,
    pendientes: gs.where((g) => !g.revisado).length,
  );
}
