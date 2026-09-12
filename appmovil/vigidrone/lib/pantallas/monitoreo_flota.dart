import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../sim/simulador.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import '../widgets/tarjeta_dron.dart';

/// Vista de flota: las tarjetas de los drones en rejilla, más la misión,
/// el checklist y la geocerca. Todo lo que antes se apretaba en la columna
/// lateral del mapa vive aquí, con espacio para leerse.
class VistaFlota extends StatefulWidget {
  const VistaFlota({
    super.key,
    required this.sim,
    required this.dronActivo,
    required this.onSeleccionar,
  });

  final Simulador sim;
  final Dron dronActivo;
  final ValueChanged<Dron> onSeleccionar;

  @override
  State<VistaFlota> createState() => _VistaFlotaState();
}

class _VistaFlotaState extends State<VistaFlota> {
  int _tab = 0;

  Ciudadela get _cd => widget.sim.ciudadela;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.sim,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Segmentos<int>(
                  opciones: const {
                    0: 'Flota',
                    1: 'Misión',
                    2: 'Checklist',
                    3: 'Geocerca',
                  },
                  valor: _tab,
                  onCambio: (i) => setState(() => _tab = i),
                ),
                const Spacer(),
                if (_tab == 0)
                  Etiqueta(
                      '${_cd.drones.where((d) => d.estado.volando).length} de ${_cd.drones.length} en vuelo'),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: switch (_tab) {
                0 => _rejillaFlota(),
                1 => _mision(),
                2 => const _Checklist(),
                _ => _geocerca(),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _rejillaFlota() {
    final columnas = MediaQuery.sizeOf(context).width > 1180 ? 3 : 2;
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columnas,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 150,
      ),
      itemCount: _cd.drones.length,
      itemBuilder: (_, i) {
        final d = _cd.drones[i];
        return TarjetaDron(
          dron: d,
          activo: d.id == widget.dronActivo.id,
          onTap: () => widget.onSeleccionar(d),
        );
      },
    );
  }

  Widget _mision() => ListView(
        padding: EdgeInsets.zero,
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TituloPanel('Misión activa',
                    detalle: 'Patrullaje perimetral por sectores'),
                const SizedBox(height: 12),
                for (var i = 0; i < _cd.sectores.length; i++)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Paleta.porRiesgo[_cd.sectores[i].riesgo],
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(_cd.sectores[i].id,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF06121A))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_cd.sectores[i].nombre,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 3),
                              const Etiqueta(
                                  'Barrido RGB + térmico · 6 waypoints'),
                            ],
                          ),
                        ),
                        Etiqueta(
                            '${_cd.drones.where((d) => d.sectorId == _cd.sectores[i].id).length} dron(es)'),
                      ],
                    ),
                  ),
                const _Nota('Ciclo completo estimado: 24 min'),
              ],
            ),
          ),
        ],
      );

  Widget _geocerca() => ListView(
        padding: EdgeInsets.zero,
        children: [
          Panel(
            padding: const EdgeInsets.all(14),
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TituloPanel('Geocerca', detalle: 'Límites operativos'),
                const SizedBox(height: 12),
                _Dato('Radio autorizado', '${_cd.radioGeocerca.round()} m'),
                _Dato('Altura máxima', '${_cd.alturaMaxima} m AGL'),
                _Dato('Retorno automático', 'Batería < 20%'),
                _Dato('Cámaras enlazadas', '${_cd.camaras}'),
                _Dato('Viviendas cubiertas', '${_cd.viviendas}'),
                const _Nota(
                    'La violación de geocerca dispara alerta inmediata al puesto de guardia.'),
              ],
            ),
          ),
        ],
      );
}

class _Checklist extends StatefulWidget {
  const _Checklist();

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  final _items = <String, bool>{
    'Baterías sobre 80%': true,
    'Hélices sin daño': true,
    'Enlace RC y video': true,
    'GPS ≥ 12 satélites': true,
    'Clima apto (viento < 8 m/s)': true,
    'Permiso DGAC vigente': true,
    'Tarjeta de grabación con espacio': false,
  };

  @override
  Widget build(BuildContext context) {
    final listos = _items.values.where((v) => v).length;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Panel(
          padding: const EdgeInsets.all(14),
          hijo: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TituloPanel('Checklist pre-vuelo',
                  detalle: '$listos de ${_items.length} verificados'),
              const SizedBox(height: 6),
              for (final e in _items.entries)
                CheckboxListTile(
                  value: e.value,
                  onChanged: (v) => setState(() => _items[e.key] = v ?? false),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(e.key, style: const TextStyle(fontSize: 13)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Etiqueta(rotulo),
            Text(valor, style: mono(tam: 13)),
          ],
        ),
      );
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Paleta.acento.withValues(alpha: 0.07),
          border: Border.all(color: Paleta.acento.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(texto,
            style: const TextStyle(fontSize: 12, color: Paleta.texto2)),
      );
}
