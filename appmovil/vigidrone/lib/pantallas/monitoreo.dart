import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../datos/ciudadela.dart';
import '../sim/simulador.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/controles_vuelo.dart';
import '../widgets/feed_dron.dart';
import '../widgets/mapa_vigilancia.dart';
import '../widgets/panel_flota.dart';
import '../widgets/registro_actividad.dart';

/// Pantalla de monitoreo en vivo: el mapa a pantalla completa con los
/// paneles superpuestos, pensada para tablet en horizontal.
class PantallaMonitoreo extends StatefulWidget {
  const PantallaMonitoreo({super.key, required this.sim});

  final Simulador sim;

  @override
  State<PantallaMonitoreo> createState() => _PantallaMonitoreoState();
}

class _PantallaMonitoreoState extends State<PantallaMonitoreo> {
  final _mapa = MapController();
  late Dron _activo = widget.sim.ciudadela.drones.first;
  String? _sector;
  bool _geocerca = true, _sectores = true, _rutas = true;

  Ciudadela get _cd => widget.sim.ciudadela;

  void _seleccionar(Dron d) {
    setState(() => _activo = d);
    _mapa.move(d.posicion, _mapa.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sim,
      builder: (context, _) {
        final estrecho = MediaQuery.sizeOf(context).width < 1100;

        return Stack(
          children: [
            Positioned.fill(
              child: MapaVigilancia(
                ciudadela: _cd,
                controlador: _mapa,
                dronActivo: _activo,
                sectorActivo: _sector,
                onDron: _seleccionar,
                onSector: (s) => setState(() => _sector = _sector == s ? null : s),
                verGeocerca: _geocerca,
                verSectores: _sectores,
                verRutas: _rutas,
              ),
            ),

            // Columna izquierda: la flota.
            Positioned(
              left: 12,
              top: 12,
              bottom: 12,
              width: estrecho ? 250 : 288,
              child: PanelFlota(
                ciudadela: _cd,
                dronActivo: _activo,
                onSeleccionar: _seleccionar,
              ),
            ),

            // Encabezado y registro.
            Positioned(
              left: (estrecho ? 250 : 288) + 24,
              top: 12,
              right: (estrecho ? 300 : 372) + 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Panel(
                    padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
                    hijo: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Paleta.acento,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Text('EN VIVO',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Color(0xFF04141A))),
                        ),
                        const SizedBox(width: 11),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_cd.nombre,
                                style: const TextStyle(
                                    fontSize: 13.5, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 2),
                            Etiqueta(_cd.direccion),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  RegistroActividad(eventos: widget.sim.registro),
                ],
              ),
            ),

            // Consola de vuelo.
            Positioned(
              bottom: 12,
              left: (estrecho ? 250 : 288) + 24,
              right: (estrecho ? 300 : 372) + 24,
              child: Center(
                child: ControlesVuelo(
                  dron: _activo,
                  pausado: widget.sim.pausado,
                  onPausa: widget.sim.alternarPausa,
                  onAterrizar: () => widget.sim.aterrizar(_activo),
                  onRetornar: () => widget.sim.retornar(_activo),
                  onDespegar: () => widget.sim.despegar(_activo),
                ),
              ),
            ),

            // Columna derecha: cámara del dron, capas y sectores.
            Positioned(
              right: 12,
              top: 12,
              bottom: 12,
              width: estrecho ? 300 : 372,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    FeedDron(dron: _activo, ciudadela: _cd),
                    const SizedBox(height: 12),
                    _PanelCapas(
                      geocerca: _geocerca,
                      sectores: _sectores,
                      rutas: _rutas,
                      onCambio: (g, s, r) => setState(() {
                        _geocerca = g;
                        _sectores = s;
                        _rutas = r;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _PanelSectores(
                      ciudadela: _cd,
                      activo: _sector,
                      onTap: (s) =>
                          setState(() => _sector = _sector == s ? null : s),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanelCapas extends StatelessWidget {
  const _PanelCapas({
    required this.geocerca,
    required this.sectores,
    required this.rutas,
    required this.onCambio,
  });

  final bool geocerca, sectores, rutas;
  final void Function(bool, bool, bool) onCambio;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.fromLTRB(13, 11, 13, 5),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_outlined, size: 14, color: Paleta.texto3),
                const SizedBox(width: 6),
                const Etiqueta('Capas'),
              ],
            ),
            _Interruptor('Geocerca', geocerca,
                (v) => onCambio(v, sectores, rutas)),
            _Interruptor('Sectores', sectores,
                (v) => onCambio(geocerca, v, rutas)),
            _Interruptor('Rutas', rutas, (v) => onCambio(geocerca, sectores, v)),
          ],
        ),
      );
}

class _Interruptor extends StatelessWidget {
  const _Interruptor(this.texto, this.valor, this.onCambio);

  final String texto;
  final bool valor;
  final ValueChanged<bool> onCambio;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => onCambio(!valor),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Checkbox(
                  value: valor,
                  onChanged: (v) => onCambio(v ?? false),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Text(texto, style: const TextStyle(fontSize: 12.5)),
            ],
          ),
        ),
      );
}

class _PanelSectores extends StatelessWidget {
  const _PanelSectores({
    required this.ciudadela,
    required this.activo,
    required this.onTap,
  });

  final Ciudadela ciudadela;
  final String? activo;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Panel(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 8),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Etiqueta('Sectores · nivel de riesgo'),
            const SizedBox(height: 4),
            for (final s in ciudadela.sectores)
              _FilaSector(
                sector: s,
                drones: ciudadela.drones.where((d) => d.sectorId == s.id).length,
                activo: activo == s.id,
                onTap: () => onTap(s.id),
              ),
          ],
        ),
      );
}

class _FilaSector extends StatelessWidget {
  const _FilaSector({
    required this.sector,
    required this.drones,
    required this.activo,
    required this.onTap,
  });

  final Sector sector;
  final int drones;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(9),
        child: Container(
          margin: const EdgeInsets.only(top: 5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: activo ? Colors.white.withValues(alpha: 0.1) : null,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Paleta.porRiesgo[sector.riesgo],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(sector.id,
                    style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF06121A))),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(sector.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
              Etiqueta('$drones dron${drones == 1 ? '' : 'es'}'),
            ],
          ),
        ),
      );
}
