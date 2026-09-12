import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../sim/simulador.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/registro_actividad.dart';
import 'monitoreo_camara.dart';
import 'monitoreo_flota.dart';
import 'monitoreo_mapa.dart';

/// Monitoreo en vivo, repartido en tres vistas para que ninguna se sature en
/// la pantalla de una tablet: el mapa, la flota y la cámara del dron.
/// El registro de actividad entra como panel lateral cuando se lo pide.
class PantallaMonitoreo extends StatefulWidget {
  const PantallaMonitoreo({super.key, required this.sim});

  final Simulador sim;

  @override
  State<PantallaMonitoreo> createState() => _PantallaMonitoreoState();
}

class _PantallaMonitoreoState extends State<PantallaMonitoreo> {
  late Dron _activo = widget.sim.ciudadela.drones.first;
  int _vista = 0;
  bool _actividad = false;

  Ciudadela get _cd => widget.sim.ciudadela;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _cabecera(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: switch (_vista) {
                  0 => VistaMapa(
                      sim: widget.sim,
                      dronActivo: _activo,
                      onSeleccionar: (d) => setState(() => _activo = d),
                    ),
                  1 => VistaFlota(
                      sim: widget.sim,
                      dronActivo: _activo,
                      onSeleccionar: (d) => setState(() => _activo = d),
                    ),
                  _ => VistaCamara(
                      sim: widget.sim,
                      dronActivo: _activo,
                      onSeleccionar: (d) => setState(() => _activo = d),
                    ),
                },
              ),
              if (_actividad)
                SizedBox(
                  width: 320,
                  child: PanelActividad(
                    sim: widget.sim,
                    onCerrar: () => setState(() => _actividad = false),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cabecera() => Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Paleta.acento,
                borderRadius: BorderRadius.circular(7),
              ),
              child: const Text('EN VIVO',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: Color(0xFF04141A))),
            ),
            const SizedBox(width: 11),
            Text(_cd.nombre,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700)),
            const SizedBox(width: 18),
            Segmentos<int>(
              opciones: const {0: 'Mapa', 1: 'Flota', 2: 'Cámara'},
              valor: _vista,
              onCambio: (i) => setState(() => _vista = i),
            ),
            const Spacer(),
            ListenableBuilder(
              listenable: widget.sim,
              builder: (context, _) {
                final ultimo =
                    widget.sim.registro.isEmpty ? null : widget.sim.registro.first;
                return Row(
                  children: [
                    if (ultimo != null && !_actividad) ...[
                      Punto(colorEvento(ultimo.tipo), tam: 7, pulsa: true),
                      const SizedBox(width: 7),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 320),
                        child: Text(
                          '${ultimo.dron} — ${ultimo.texto}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: Paleta.texto2),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    BotonAccion(
                      texto: 'Actividad',
                      icono: Icons.notifications_none,
                      activo: _actividad,
                      onTap: () => setState(() => _actividad = !_actividad),
                    ),
                    if (widget.sim.alertas > 0) ...[
                      const SizedBox(width: 7),
                      Ficha(
                        texto: '${widget.sim.alertas}',
                        icono: Icons.warning_amber_rounded,
                        color: Paleta.alerta,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      );
}
