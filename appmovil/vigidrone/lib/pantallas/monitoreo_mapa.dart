import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../datos/ciudadela.dart';
import '../sim/simulador.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/mapa_vigilancia.dart';
import '../widgets/tarjeta_dron.dart';

/// Vista de mapa: el recinto casi a pantalla completa. Solo lleva encima lo
/// que hace falta para leerlo — capas, sectores y la tira de drones — porque
/// la telemetría y los controles viven en sus propias vistas.
class VistaMapa extends StatefulWidget {
  const VistaMapa({
    super.key,
    required this.sim,
    required this.dronActivo,
    required this.onSeleccionar,
  });

  final Simulador sim;
  final Dron dronActivo;
  final ValueChanged<Dron> onSeleccionar;

  @override
  State<VistaMapa> createState() => _VistaMapaState();
}

class _VistaMapaState extends State<VistaMapa> {
  final _mapa = MapController();
  String? _sector;
  bool _geocerca = true, _sectores = true, _rutas = true;
  bool _seguir = true;

  Ciudadela get _cd => widget.sim.ciudadela;

  @override
  void initState() {
    super.initState();
    widget.sim.addListener(_seguirDron);
  }

  @override
  void dispose() {
    widget.sim.removeListener(_seguirDron);
    super.dispose();
  }

  /// Mantiene el dron seleccionado centrado mientras patrulla.
  void _seguirDron() {
    if (!_seguir || !mounted) return;
    try {
      _mapa.move(widget.dronActivo.posicion, _mapa.camera.zoom);
    } catch (_) {
      // El mapa todavía no está montado; el próximo tic lo intenta de nuevo.
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sim,
      builder: (context, _) => Stack(
        children: [
          Positioned.fill(
            child: MapaVigilancia(
              ciudadela: _cd,
              controlador: _mapa,
              dronActivo: widget.dronActivo,
              sectorActivo: _sector,
              onDron: widget.onSeleccionar,
              onSector: (s) => setState(() => _sector = _sector == s ? null : s),
              verGeocerca: _geocerca,
              verSectores: _sectores,
              verRutas: _rutas,
            ),
          ),

          // Capas y seguimiento, como botones de ícono.
          Positioned(
            top: 12,
            right: 12,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              hijo: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Boton(
                    icono: Icons.my_location,
                    activo: _seguir,
                    tip: _seguir ? 'Siguiendo al dron' : 'Seguir al dron',
                    onTap: () => setState(() => _seguir = !_seguir),
                  ),
                  const _Separador(),
                  _Boton(
                    icono: Icons.shield_outlined,
                    activo: _geocerca,
                    tip: 'Geocerca',
                    onTap: () => setState(() => _geocerca = !_geocerca),
                  ),
                  _Boton(
                    icono: Icons.grid_view,
                    activo: _sectores,
                    tip: 'Sectores',
                    onTap: () => setState(() => _sectores = !_sectores),
                  ),
                  _Boton(
                    icono: Icons.route,
                    activo: _rutas,
                    tip: 'Rutas de patrullaje',
                    onTap: () => setState(() => _rutas = !_rutas),
                  ),
                  const _Separador(),
                  _Boton(
                    icono: Icons.add,
                    tip: 'Acercar',
                    onTap: () =>
                        _mapa.move(_mapa.camera.center, _mapa.camera.zoom + 0.6),
                  ),
                  _Boton(
                    icono: Icons.remove,
                    tip: 'Alejar',
                    onTap: () =>
                        _mapa.move(_mapa.camera.center, _mapa.camera.zoom - 0.6),
                  ),
                ],
              ),
            ),
          ),

          // Sector tocado: una sola línea, no un panel.
          if (_sector != null)
            Positioned(
              top: 12,
              left: 12,
              child: Panel(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                hijo: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Paleta
                            .porRiesgo[_cd.sectorPorId(_sector!).riesgo],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_sector!,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF06121A))),
                    ),
                    const SizedBox(width: 9),
                    Text(_cd.sectorPorId(_sector!).nombre,
                        style: const TextStyle(fontSize: 12.5)),
                    const SizedBox(width: 9),
                    Etiqueta(
                        'riesgo ${_cd.sectorPorId(_sector!).riesgo.name}'),
                    const SizedBox(width: 6),
                    InkWell(
                      onTap: () => setState(() => _sector = null),
                      child: const Icon(Icons.close,
                          size: 15, color: Paleta.texto3),
                    ),
                  ],
                ),
              ),
            ),

          // Tira inferior: telemetría del dron activo y selección rápida.
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Panel(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              hijo: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Punto(Paleta.deEstado(widget.dronActivo.estado),
                          pulsa: widget.dronActivo.estado == EstadoDron.enVuelo),
                      const SizedBox(width: 9),
                      Text(widget.dronActivo.nombre,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 20,
                          runSpacing: 6,
                          children: [
                            _Lectura('${widget.dronActivo.altitud.round()} m',
                                'altitud'),
                            _Lectura(
                                '${widget.dronActivo.velocidad.toStringAsFixed(1)} m/s',
                                'velocidad'),
                            _Lectura('${widget.dronActivo.distanciaBase} m',
                                'desde base'),
                            _Lectura('${widget.dronActivo.bateria.round()}%',
                                'batería',
                                color:
                                    Paleta.deBateria(widget.dronActivo.bateria)),
                            _Lectura('${widget.dronActivo.senal}%', 'señal'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _cd.drones.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 7),
                      itemBuilder: (_, i) => FichaDron(
                        dron: _cd.drones[i],
                        activo: _cd.drones[i].id == widget.dronActivo.id,
                        onTap: () => widget.onSeleccionar(_cd.drones[i]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Lectura extends StatelessWidget {
  const _Lectura(this.valor, this.rotulo, {this.color});

  final String valor;
  final String rotulo;
  final Color? color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(valor, style: mono(tam: 13, peso: FontWeight.w700, color: color)),
          const SizedBox(width: 5),
          Etiqueta(rotulo),
        ],
      );
}

class _Boton extends StatelessWidget {
  const _Boton({
    required this.icono,
    required this.tip,
    required this.onTap,
    this.activo = false,
  });

  final IconData icono;
  final String tip;
  final VoidCallback onTap;
  final bool activo;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tip,
        child: Material(
          color: activo ? Paleta.acento.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.all(9),
              child: Icon(icono,
                  size: 19, color: activo ? Paleta.acento : Paleta.texto2),
            ),
          ),
        ),
      );
}

class _Separador extends StatelessWidget {
  const _Separador();

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: Paleta.linea,
      );
}
