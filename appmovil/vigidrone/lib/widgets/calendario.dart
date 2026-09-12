import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show isoDe;
import '../tema.dart';

const _dias = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const _meses = [
  'enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre',
];

/// Calendario mensual para elegir el día de la bitácora. El punto bajo cada
/// fecha indica cuántas alertas hubo; los días futuros quedan deshabilitados.
class Calendario extends StatefulWidget {
  const Calendario({
    super.key,
    required this.valor,
    required this.onCambio,
    required this.alertasDe,
  });

  final DateTime valor;
  final ValueChanged<DateTime> onCambio;
  final int Function(DateTime) alertasDe;

  @override
  State<Calendario> createState() => _CalendarioState();
}

class _CalendarioState extends State<Calendario> {
  late DateTime _vista = DateTime(widget.valor.year, widget.valor.month);

  @override
  Widget build(BuildContext context) {
    final hoy = DateTime.now();
    final primero = DateTime(_vista.year, _vista.month, 1);
    final desfase = (primero.weekday + 6) % 7; // la semana empieza en lunes
    final total = DateTime(_vista.year, _vista.month + 1, 0).day;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Paleta.linea),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () => setState(
                    () => _vista = DateTime(_vista.year, _vista.month - 1)),
                icon: const Icon(Icons.chevron_left, size: 18),
                visualDensity: VisualDensity.compact,
              ),
              Text('${_meses[_vista.month - 1]} ${_vista.year}',
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => setState(
                    () => _vista = DateTime(_vista.year, _vista.month + 1)),
                icon: const Icon(Icons.chevron_right, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final d in _dias)
                Expanded(
                  child: Center(
                    child: Text(d, style: etiqueta().copyWith(fontSize: 9)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            children: [
              for (var i = 0; i < desfase; i++) const SizedBox.shrink(),
              for (var d = 1; d <= total; d++)
                _Dia(
                  fecha: DateTime(_vista.year, _vista.month, d),
                  seleccionado: isoDe(DateTime(_vista.year, _vista.month, d)) ==
                      isoDe(widget.valor),
                  esHoy: isoDe(DateTime(_vista.year, _vista.month, d)) ==
                      isoDe(hoy),
                  futuro: DateTime(_vista.year, _vista.month, d)
                      .isAfter(DateTime(hoy.year, hoy.month, hoy.day)),
                  alertas: widget.alertasDe,
                  onTap: widget.onCambio,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  widget.onCambio(hoy);
                  setState(() => _vista = DateTime(hoy.year, hoy.month));
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('Hoy', style: TextStyle(fontSize: 12)),
              ),
              Row(
                children: [
                  for (final (c, t) in [
                    (Paleta.ok, 'baja'),
                    (Paleta.alerta, 'media'),
                    (Paleta.critico, 'alta'),
                  ]) ...[
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 3),
                    Text(t, style: etiqueta().copyWith(fontSize: 8.5)),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({
    required this.fecha,
    required this.seleccionado,
    required this.esHoy,
    required this.futuro,
    required this.alertas,
    required this.onTap,
  });

  final DateTime fecha;
  final bool seleccionado;
  final bool esHoy;
  final bool futuro;
  final int Function(DateTime) alertas;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final n = futuro ? 0 : alertas(fecha);
    final color = n > 12
        ? Paleta.critico
        : n > 6
            ? Paleta.alerta
            : n > 0
                ? Paleta.ok
                : null;

    return Opacity(
      opacity: futuro ? 0.32 : 1,
      child: Material(
        color: seleccionado ? Paleta.acento : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        child: InkWell(
          onTap: futuro ? null : () => onTap(fecha),
          borderRadius: BorderRadius.circular(7),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: esHoy && !seleccionado
                  ? Border.all(color: Paleta.lineaFuerte)
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  '${fecha.day}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: seleccionado ? FontWeight.w700 : FontWeight.w400,
                    color: seleccionado ? const Color(0xFF04141A) : Paleta.texto2,
                  ),
                ),
                if (color != null)
                  Positioned(
                    bottom: 3,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: seleccionado ? const Color(0xFF04141A) : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
