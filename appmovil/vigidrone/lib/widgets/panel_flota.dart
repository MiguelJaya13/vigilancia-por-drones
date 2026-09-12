import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../tema.dart';
import 'comunes.dart';

/// Columna izquierda del monitoreo: la flota con su telemetría, más las
/// pestañas de misión, checklist y geocerca.
class PanelFlota extends StatefulWidget {
  const PanelFlota({
    super.key,
    required this.ciudadela,
    required this.dronActivo,
    required this.onSeleccionar,
  });

  final Ciudadela ciudadela;
  final Dron? dronActivo;
  final ValueChanged<Dron> onSeleccionar;

  @override
  State<PanelFlota> createState() => _PanelFlotaState();
}

class _PanelFlotaState extends State<PanelFlota> {
  int _pestana = 0;
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    final cd = widget.ciudadela;
    final enVuelo = cd.drones.where((d) => d.estado.volando).length;

    return Panel(
      padding: EdgeInsets.zero,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Pestanas(
            actual: _pestana,
            onCambio: (i) => setState(() => _pestana = i),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: switch (_pestana) {
                0 => _vistaFlota(cd, enVuelo),
                1 => _vistaMision(cd),
                2 => const _Checklist(),
                _ => _vistaGeocerca(cd),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _vistaFlota(Ciudadela cd, int enVuelo) {
    final filtro = _busqueda.trim().toLowerCase();
    final lista = cd.drones.where((d) {
      if (filtro.isEmpty) return true;
      return d.nombre.toLowerCase().contains(filtro) ||
          d.codigo.toLowerCase().contains(filtro) ||
          d.sectorId.toLowerCase() == filtro;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TituloPanel('Flota', detalle: '$enVuelo de ${cd.drones.length} en vuelo'),
        const SizedBox(height: 11),
        TextField(
          onChanged: (v) => setState(() => _busqueda = v),
          style: const TextStyle(fontSize: 12.5),
          decoration: InputDecoration(
            hintText: 'Buscar dron o sector…',
            hintStyle: const TextStyle(fontSize: 12.5, color: Paleta.texto3),
            prefixIcon: const Icon(Icons.search, size: 17, color: Paleta.texto3),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 34, minHeight: 34),
            isDense: true,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.35),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Paleta.linea),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Paleta.linea),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Paleta.acento),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: lista.isEmpty
              ? Center(
                  child: Text('Sin resultados',
                      style: TextStyle(fontSize: 12, color: Paleta.texto3)))
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: lista.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _TarjetaDron(
                    dron: lista[i],
                    activo: lista[i].id == widget.dronActivo?.id,
                    onTap: () => widget.onSeleccionar(lista[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _vistaMision(Ciudadela cd) => ListView(
        padding: EdgeInsets.zero,
        children: [
          const TituloPanel('Misión activa', detalle: 'Patrullaje perimetral'),
          const SizedBox(height: 11),
          for (var i = 0; i < cd.sectores.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 7),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Paleta.acento.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('${i + 1}',
                        style: mono(tam: 11, color: Paleta.acento)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sector ${cd.sectores[i].id} · ${cd.sectores[i].nombre}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        const Etiqueta('Barrido RGB + térmico · 6 waypoints'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const _Nota('Ciclo completo estimado: 24 min'),
        ],
      );

  Widget _vistaGeocerca(Ciudadela cd) => ListView(
        padding: EdgeInsets.zero,
        children: [
          const TituloPanel('Geocerca', detalle: 'Límites operativos'),
          const SizedBox(height: 11),
          _Dato('Radio autorizado', '${cd.radioGeocerca.round()} m'),
          _Dato('Altura máxima', '${cd.alturaMaxima} m AGL'),
          _Dato('Retorno automático', 'Batería < 20%'),
          _Dato('Cámaras enlazadas', '${cd.camaras}'),
          _Dato('Viviendas cubiertas', '${cd.viviendas}'),
          const _Nota(
              'La violación de geocerca dispara alerta inmediata al puesto de guardia.'),
        ],
      );
}

class _Pestanas extends StatelessWidget {
  const _Pestanas({required this.actual, required this.onCambio});

  final int actual;
  final ValueChanged<int> onCambio;

  static const _items = [
    (Icons.flight, 'Vuelo'),
    (Icons.route, 'Misión'),
    (Icons.checklist, 'Checklist'),
    (Icons.shield_outlined, 'Geocerca'),
  ];

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Paleta.linea)),
        ),
        child: Row(
          children: [
            for (var i = 0; i < _items.length; i++)
              Expanded(
                child: InkWell(
                  onTap: () => onCambio(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: i == actual
                          ? Paleta.acento.withValues(alpha: 0.15)
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: i == actual ? Paleta.acento : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(_items[i].$1,
                            size: 17,
                            color: i == actual ? Paleta.acento : Paleta.texto3),
                        const SizedBox(height: 4),
                        Text(
                          _items[i].$2.toUpperCase(),
                          style: etiqueta(
                              i == actual ? Paleta.acento : Paleta.texto3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

class _TarjetaDron extends StatelessWidget {
  const _TarjetaDron({
    required this.dron,
    required this.activo,
    required this.onTap,
  });

  final Dron dron;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorBateria = Paleta.deBateria(dron.bateria);

    return Material(
      color: activo
          ? Paleta.acento.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            border: Border.all(color: activo ? Paleta.acento : Paleta.linea),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Punto(Paleta.deEstado(dron.estado),
                      pulsa: dron.estado == EstadoDron.enVuelo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(dron.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                  Text('${dron.bateria.round()}%',
                      style: mono(tam: 12, peso: FontWeight.w700, color: colorBateria)),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Etiqueta('Sector ${dron.sectorId}', color: Paleta.texto2),
                  ),
                  const SizedBox(width: 7),
                  Text(dron.estado.texto,
                      style: const TextStyle(fontSize: 11, color: Paleta.texto3)),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Metrica('${dron.altitud.round()} m', 'Altitud', tam: 12),
                  Metrica('${dron.velocidad.toStringAsFixed(1)} m/s', 'Velocidad',
                      tam: 12),
                  Metrica('${dron.distanciaBase} m', 'Desde base', tam: 12),
                ],
              ),
              const SizedBox(height: 9),
              Barra(valor: dron.bateria / 100, color: colorBateria),
            ],
          ),
        ),
      ),
    );
  }
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
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.zero,
        children: [
          const TituloPanel('Checklist pre-vuelo', detalle: 'Antes de despegar'),
          const SizedBox(height: 8),
          for (final e in _items.entries)
            CheckboxListTile(
              value: e.value,
              onChanged: (v) => setState(() => _items[e.key] = v ?? false),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(e.key, style: const TextStyle(fontSize: 12.5)),
            ),
        ],
      );
}

class _Dato extends StatelessWidget {
  const _Dato(this.rotulo, this.valor);

  final String rotulo;
  final String valor;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 7),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Etiqueta(rotulo),
            Text(valor, style: mono(tam: 12)),
          ],
        ),
      );
}

class _Nota extends StatelessWidget {
  const _Nota(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Paleta.acento.withValues(alpha: 0.07),
          border: Border.all(color: Paleta.acento.withValues(alpha: 0.18)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(texto,
            style: const TextStyle(fontSize: 11.5, color: Paleta.texto2)),
      );
}
