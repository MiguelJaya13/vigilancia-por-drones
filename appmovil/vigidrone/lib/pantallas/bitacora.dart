import 'dart:async';
import 'package:flutter/material.dart';

import '../datos/bitacora.dart';
import '../datos/ciudadela.dart';
import '../tema.dart';
import '../widgets/calendario.dart';
import '../widgets/comunes.dart';
import '../widgets/visor_tiles.dart';

/// Bitácora: acceso a las grabaciones por día y por sector, que es la
/// consulta que hace un administrador cuando ocurre un incidente.
class PantallaBitacora extends StatefulWidget {
  const PantallaBitacora({super.key, required this.ciudadela});

  final Ciudadela ciudadela;

  @override
  State<PantallaBitacora> createState() => _PantallaBitacoraState();
}

class _PantallaBitacoraState extends State<PantallaBitacora> {
  DateTime _fecha = DateTime.now();
  String _sector = 'todos';
  late final Set<String> _tipos = tiposEvento.map((t) => t.id).toSet();
  Grabacion? _seleccion;

  int _t = 0; // segundos reproducidos del clip
  bool _reproduciendo = false;
  int _velocidad = 1;
  Timer? _reloj;

  List<Grabacion> get _delDia => grabacionesDe(widget.ciudadela, _fecha);

  List<Grabacion> get _filtradas => _delDia
      .where((g) =>
          (_sector == 'todos' || g.sectorId == _sector) && _tipos.contains(g.tipo))
      .toList();

  @override
  void initState() {
    super.initState();
    _seleccion = _filtradas.isEmpty ? null : _filtradas.first;
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_reproduciendo || _seleccion == null) return;
      setState(() {
        _t += _velocidad;
        if (_t >= _seleccion!.duracion) {
          _t = _seleccion!.duracion;
          _reproduciendo = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  void _refiltrar() {
    final lista = _filtradas;
    setState(() {
      _seleccion = lista.isEmpty ? null : lista.first;
      _t = 0;
      _reproduciendo = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final estrecho = MediaQuery.sizeOf(context).width < 1100;
    final filtradas = _filtradas;
    final resumen = resumenDe(filtradas);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: estrecho ? 260 : 296, child: _filtros()),
          const SizedBox(width: 12),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _encabezado(resumen),
                const SizedBox(height: 12),
                _reproductor(),
                const SizedBox(height: 12),
                _lineaTiempo(filtradas),
                const SizedBox(height: 12),
                _tabla(filtradas, resumen),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- filtros
  Widget _filtros() => Panel(
        padding: const EdgeInsets.all(14),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const TituloPanel('Bitácora',
                detalle: 'Grabaciones por día y sector'),
            const SizedBox(height: 14),
            const Etiqueta('Día'),
            const SizedBox(height: 7),
            Calendario(
              valor: _fecha,
              onCambio: (d) {
                setState(() => _fecha = d);
                _refiltrar();
              },
              alertasDe: (d) => grabacionesDe(widget.ciudadela, d)
                  .where((g) => g.tipo != 'patrullaje')
                  .length,
            ),
            const SizedBox(height: 14),
            const Etiqueta('Sector'),
            const SizedBox(height: 7),
            _botonSector('todos', 'Todos', null),
            for (final s in widget.ciudadela.sectores)
              _botonSector(s.id, s.nombre, Paleta.porRiesgo[s.riesgo]),
            const SizedBox(height: 14),
            const Etiqueta('Tipo de evento'),
            const SizedBox(height: 4),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final t in tiposEvento)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (_tipos.contains(t.id)) {
                            if (_tipos.length > 1) _tipos.remove(t.id);
                          } else {
                            _tipos.add(t.id);
                          }
                        });
                        _refiltrar();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 28,
                              child: Checkbox(
                                value: _tipos.contains(t.id),
                                onChanged: (_) {},
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                            Punto(t.color, tam: 7),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(t.nombre,
                                  style: const TextStyle(fontSize: 12)),
                            ),
                            Text(
                              '${_delDia.where((g) => g.tipo == t.id).length}',
                              style: mono(tam: 11, color: Paleta.texto3),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _botonSector(String id, String texto, Color? color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: id == _sector
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: () {
              setState(() => _sector = id);
              _refiltrar();
            },
            borderRadius: BorderRadius.circular(9),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              child: Row(
                children: [
                  if (color != null) ...[
                    Container(
                      width: 19,
                      height: 19,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(id,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF06121A))),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  // ------------------------------------------------------------- encabezado
  Widget _encabezado(ResumenDia r) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fechaLarga(_fecha),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Etiqueta(_sector == 'todos'
                    ? 'Todos los sectores'
                    : 'Sector $_sector'),
              ],
            ),
          ),
          Wrap(
            spacing: 7,
            children: [
              Ficha(texto: '${r.segmentos} segmentos', icono: Icons.videocam),
              Ficha(
                  texto: '${r.horas.toStringAsFixed(1)} h',
                  icono: Icons.schedule),
              Ficha(
                texto: '${r.alertas} alertas',
                icono: Icons.warning_amber_rounded,
                color: r.alertas > 0 ? Paleta.alerta : null,
              ),
              Ficha(texto: '${r.almacenamientoGB.toStringAsFixed(1)} GB'),
            ],
          ),
        ],
      );

  // ------------------------------------------------------------ reproductor
  Widget _reproductor() {
    final g = _seleccion;
    if (g == null) {
      return Panel(
        padding: const EdgeInsets.symmetric(vertical: 56),
        hijo: const Center(
          child: Column(
            children: [
              Icon(Icons.videocam_off_outlined, size: 26, color: Paleta.texto3),
              SizedBox(height: 10),
              Text('No hay grabaciones con los filtros seleccionados.',
                  style: TextStyle(fontSize: 13, color: Paleta.texto3)),
            ],
          ),
        ),
      );
    }

    final tipo = tipoPorId(g.tipo);
    final sector = widget.ciudadela.sectorPorId(g.sectorId);
    final critico = g.tipo == 'intrusion' || g.tipo == 'perimetro';
    final segundosReloj = g.minutoDia * 60 + _t;
    final termica = g.camara.contains('Térmica') && g.tipo != 'patrullaje';

    return Panel(
      padding: EdgeInsets.zero,
      recorte: true,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 16 / 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                VisorTiles(
                  punto: sector.centro,
                  zoom: 18,
                  escala: 1.5,
                  modo: termica ? ModoCamara.termica : ModoCamara.rgb,
                ),
                const CapaVideo(vineta: 0.45),
                Padding(
                  padding: const EdgeInsets.all(11),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Punto(Paleta.critico, tam: 7, pulsa: true),
                            const SizedBox(width: 6),
                            SelloVideo(
                                '${widget.ciudadela.codigo} · SECTOR ${g.sectorId}'),
                          ],
                        ),
                      ),
                      Align(
                        alignment: Alignment.topRight,
                        child: SelloVideo(
                            '${isoDe(g.fecha)} ${relojDia(segundosReloj)}'),
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: SelloVideo('${g.dronNombre} · ${g.camara}'),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: SelloVideo(g.resolucion),
                      ),
                      if (critico)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0x99050810),
                              border: Border.all(color: tipo.color, width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tipo.nombre.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                                color: tipo.color,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, c) => GestureDetector(
              onTapDown: (e) => setState(() => _t =
                  ((e.localPosition.dx / c.maxWidth) * g.duracion)
                      .clamp(0, g.duracion)
                      .round()),
              child: Container(
                height: 6,
                color: Colors.white.withValues(alpha: 0.1),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (_t / g.duracion).clamp(0, 1),
                  child: ColoredBox(color: tipo.color),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 9,
              runSpacing: 9,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BotonAccion(
                  texto: _reproduciendo ? 'Pausa' : 'Reproducir',
                  icono: _reproduciendo ? Icons.pause : Icons.play_arrow,
                  principal: true,
                  onTap: () => setState(() => _reproduciendo = !_reproduciendo),
                ),
                BotonAccion(
                  texto: 'Anterior',
                  icono: Icons.skip_previous,
                  onTap: () => _mover(-1),
                ),
                BotonAccion(
                  texto: 'Siguiente',
                  icono: Icons.skip_next,
                  onTap: () => _mover(1),
                ),
                Text('${duracionTexto(_t)} / ${duracionTexto(g.duracion)}',
                    style: mono(tam: 12, color: Paleta.texto2)),
                Segmentos<int>(
                  opciones: const {1: '1×', 2: '2×', 4: '4×', 8: '8×'},
                  valor: _velocidad,
                  onCambio: (v) => setState(() => _velocidad = v),
                ),
                BotonAccion(
                  texto: '${g.pesoMB} MB',
                  icono: Icons.download,
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Descarga en cola · ${g.id}',
                          style: const TextStyle(fontSize: 12.5)),
                      backgroundColor: Paleta.panelAlto,
                      behavior: SnackBarBehavior.floating,
                      width: 420,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Paleta.linea)),
            ),
            child: Row(
              children: [
                Ficha(texto: tipo.nombre, color: tipo.color, punto: tipo.color),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(g.detalle,
                      style: const TextStyle(fontSize: 12.5)),
                ),
                Etiqueta(
                    'Inicio ${g.hora} · Sector ${g.sectorId} — ${g.sectorNombre}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mover(int paso) {
    final lista = _filtradas;
    final i = lista.indexWhere((g) => g.id == _seleccion?.id);
    final j = i + paso;
    if (j < 0 || j >= lista.length) return;
    setState(() {
      _seleccion = lista[j];
      _t = 0;
      _reproduciendo = false;
    });
  }

  // ---------------------------------------------------------- línea tiempo
  Widget _lineaTiempo(List<Grabacion> gs) => Panel(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 11),
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Etiqueta('Línea de tiempo · 24 h'),
                Wrap(
                  spacing: 11,
                  children: [
                    for (final t in tiposEvento)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Punto(t.color, tam: 6),
                        const SizedBox(width: 5),
                        Text(t.nombre,
                            style: const TextStyle(
                                fontSize: 10, color: Paleta.texto2)),
                      ]),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, c) => SizedBox(
                height: 46,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Paleta.linea),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withValues(alpha: 0.16),
                            Paleta.acento.withValues(alpha: 0.10),
                            Paleta.alerta.withValues(alpha: 0.10),
                            const Color(0xFF6366F1).withValues(alpha: 0.16),
                          ],
                          stops: const [0.12, 0.38, 0.62, 0.88],
                        ),
                      ),
                    ),
                    for (final g in gs)
                      Positioned(
                        left: (g.minutoDia / 1440) * c.maxWidth,
                        top: 8,
                        height: 30,
                        width: ((g.duracion / 60 / 1440) * c.maxWidth)
                            .clamp(3.0, c.maxWidth),
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _seleccion = g;
                            _t = 0;
                            _reproduciendo = false;
                          }),
                          child: Tooltip(
                            message:
                                '${g.hora} · ${tipoPorId(g.tipo).nombre} · Sector ${g.sectorId}',
                            child: Container(
                              decoration: BoxDecoration(
                                color: tipoPorId(g.tipo)
                                    .color
                                    .withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(3),
                                border: g.id == _seleccion?.id
                                    ? Border.all(color: Colors.white, width: 1.6)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                for (final f in ['Madrugada', 'Mañana', 'Tarde', 'Noche'])
                  Expanded(
                    child: Center(
                      child: Text(f, style: etiqueta().copyWith(fontSize: 9.5)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  // ------------------------------------------------------------------ tabla
  Widget _tabla(List<Grabacion> gs, ResumenDia r) => Panel(
        padding: EdgeInsets.zero,
        hijo: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Paleta.linea)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grabaciones del día',
                      style:
                          TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  Etiqueta(
                      '${gs.length} resultado${gs.length == 1 ? '' : 's'} · ${r.pendientes} sin revisar'),
                ],
              ),
            ),
            if (gs.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 34),
                child: Center(
                  child: Text('No hay grabaciones con los filtros seleccionados.',
                      style: TextStyle(fontSize: 12.5, color: Paleta.texto3)),
                ),
              )
            else
              for (final g in gs) _fila(g),
          ],
        ),
      );

  Widget _fila(Grabacion g) {
    final tipo = tipoPorId(g.tipo);
    final activa = g.id == _seleccion?.id;

    return Material(
      color: activa ? Paleta.acento.withValues(alpha: 0.14) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() {
          _seleccion = g;
          _t = 0;
          _reproduciendo = false;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
              left: BorderSide(
                color: activa ? Paleta.acento : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              SizedBox(width: 52, child: Text(g.hora, style: mono(tam: 12))),
              SizedBox(
                width: 128,
                child: Text('${g.sectorId}  ${g.sectorNombre}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Paleta.texto2)),
              ),
              SizedBox(
                width: 96,
                child: Text(g.dronNombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, color: Paleta.texto2)),
              ),
              Punto(tipo.color, tam: 7),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tipo.nombre,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    Text(g.detalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10.5, color: Paleta.texto3)),
                  ],
                ),
              ),
              SizedBox(
                width: 54,
                child: Text(duracionTexto(g.duracion), style: mono(tam: 11.5)),
              ),
              SizedBox(
                width: 82,
                child: Text(g.resolucion,
                    style: mono(tam: 10, color: Paleta.texto3)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (g.revisado ? Paleta.ok : Paleta.alerta)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  g.revisado ? 'REVISADO' : 'PENDIENTE',
                  style: etiqueta(g.revisado ? Paleta.ok : Paleta.alerta)
                      .copyWith(fontSize: 9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
