import 'dart:async';
import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show fechaLarga, isoDe, relojDia;
import '../datos/camaras.dart';
import '../datos/ciudadela.dart';
import '../tema.dart';
import '../widgets/celda_camara.dart';
import '../widgets/comunes.dart';
import '../widgets/linea_tiempo_camara.dart';

enum ModoVisor { directo, reproduccion }

/// Cámaras fijas de la ciudadela: mosaico del NVR, visor individual,
/// reproducción del día y notificaciones.
class PantallaCamaras extends StatefulWidget {
  const PantallaCamaras({super.key, required this.ciudadela});

  final Ciudadela ciudadela;

  @override
  State<PantallaCamaras> createState() => _PantallaCamarasState();
}

class _PantallaCamarasState extends State<PantallaCamaras> {
  late final List<Camara> _camaras = camarasDe(widget.ciudadela);

  DateTime _fecha = DateTime.now();
  ModoVisor _modo = ModoVisor.directo;
  Camara? _seleccionada;
  int _rejilla = 4;
  int _pagina = 0;
  String _sector = 'todos';
  String _busqueda = '';

  double _minuto = 0;
  bool _reproduciendo = false;
  int _velocidad = 1;
  bool _silencio = true;
  double _zoom = 1;
  bool _calidadBaja = false;

  Timer? _reloj;
  DateTime _ahora = DateTime.now();

  bool get _esHoy => isoDe(_fecha) == isoDe(DateTime.now());
  int get _topeMinuto =>
      _esHoy ? DateTime.now().hour * 60 + DateTime.now().minute : 1440;

  @override
  void initState() {
    super.initState();
    _reloj = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _ahora = DateTime.now();
        if (_modo == ModoVisor.reproduccion && _reproduciendo) {
          _minuto += _velocidad / 60;
          if (_minuto >= _topeMinuto) {
            _minuto = _topeMinuto.toDouble();
            _reproduciendo = false;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _reloj?.cancel();
    super.dispose();
  }

  List<Camara> get _filtradas {
    final t = _busqueda.trim().toLowerCase();
    return _camaras.where((c) {
      final okSector = _sector == 'todos' || c.sectorId == _sector;
      final okTexto = t.isEmpty ||
          c.nombre.toLowerCase().contains(t) ||
          c.ubicacion.toLowerCase().contains(t) ||
          c.id.toLowerCase().contains(t);
      return okSector && okTexto;
    }).toList();
  }

  void _irAModo(ModoVisor m) {
    setState(() {
      _modo = m;
      if (m == ModoVisor.reproduccion) {
        _minuto = (_topeMinuto - 30).clamp(0, 1440).toDouble();
        _reproduciendo = true;
      } else {
        _reproduciendo = false;
      }
    });
  }

  void _aviso(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(texto, style: const TextStyle(fontSize: 12.5)),
        backgroundColor: Paleta.panelAlto,
        behavior: SnackBarBehavior.floating,
        width: 460,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final estrecho = MediaQuery.sizeOf(context).width < 1150;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: estrecho ? 220 : 268, child: _listaCamaras()),
          const SizedBox(width: 12),
          Expanded(child: _visor()),
          if (!estrecho) ...[
            const SizedBox(width: 12),
            SizedBox(width: 252, child: _notificaciones()),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ lista
  Widget _listaCamaras() {
    final enLinea = _camaras.where((c) => c.enLinea).length;
    final lista = _filtradas;

    return Panel(
      padding: const EdgeInsets.all(13),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TituloPanel('Cámaras fijas',
              detalle: '$enLinea de ${_camaras.length} en línea'),
          const SizedBox(height: 10),
          TextField(
            onChanged: (v) => setState(() {
              _busqueda = v;
              _pagina = 0;
            }),
            style: const TextStyle(fontSize: 12.5),
            decoration: InputDecoration(
              hintText: 'Buscar cámara o ubicación…',
              hintStyle: const TextStyle(fontSize: 12, color: Paleta.texto3),
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
            ),
          ),
          const SizedBox(height: 9),
          _SelectorSector(
            ciudadela: widget.ciudadela,
            valor: _sector,
            onCambio: (s) => setState(() {
              _sector = s;
              _pagina = 0;
            }),
          ),
          const SizedBox(height: 9),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: lista.length,
              itemBuilder: (_, i) {
                final c = lista[i];
                final activa = c.id == _seleccionada?.id;
                return Material(
                  color: activa
                      ? Paleta.acento.withValues(alpha: 0.14)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  child: InkWell(
                    onTap: () => setState(() => _seleccionada = c),
                    borderRadius: BorderRadius.circular(9),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 8),
                      child: Row(
                        children: [
                          Punto(c.enLinea ? Paleta.ok : Paleta.critico, tam: 7),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.nombre,
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 2),
                                Text('${c.ubicacion} · Sector ${c.sectorId}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: etiqueta()),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(c.tipo,
                                style: etiqueta().copyWith(fontSize: 8.5)),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ visor
  Widget _visor() {
    final lista = _filtradas;
    final paginas = (lista.length / _rejilla).ceil().clamp(1, 999);
    final desde = _pagina * _rejilla;
    final visibles = lista.skip(desde).take(_rejilla).toList();
    final segundos = _modo == ModoVisor.directo
        ? _ahora.hour * 3600 + _ahora.minute * 60 + _ahora.second
        : _minuto * 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _barraVisor(paginas),
        const SizedBox(height: 12),
        Expanded(
          child: SingleChildScrollView(
            child: _seleccionada == null
                ? _mosaico(visibles, segundos)
                : _detalle(_seleccionada!, segundos),
          ),
        ),
      ],
    );
  }

  Widget _barraVisor(int paginas) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        hijo: Row(
          children: [
            Segmentos<ModoVisor>(
              opciones: const {
                ModoVisor.directo: 'Vista en directo',
                ModoVisor.reproduccion: 'Reproducción',
              },
              valor: _modo,
              onCambio: _irAModo,
            ),
            if (_modo == ModoVisor.reproduccion) ...[
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _cambiarDia(-1),
                icon: const Icon(Icons.chevron_left, size: 19),
                visualDensity: VisualDensity.compact,
              ),
              SizedBox(
                width: 128,
                child: Text(
                  _esHoy ? 'Hoy' : fechaLarga(_fecha).split(' de ').take(2).join(' de '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: _esHoy ? null : () => _cambiarDia(1),
                icon: const Icon(Icons.chevron_right, size: 19),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const Spacer(),
            if (_seleccionada == null) ...[
              const Icon(Icons.grid_view, size: 15, color: Paleta.texto3),
              const SizedBox(width: 7),
              Segmentos<int>(
                opciones: const {1: '1', 4: '2×2', 9: '3×3', 16: '4×4'},
                valor: _rejilla,
                onCambio: (n) => setState(() {
                  _rejilla = n;
                  _pagina = 0;
                }),
              ),
              const SizedBox(width: 10),
              IconButton(
                onPressed:
                    _pagina == 0 ? null : () => setState(() => _pagina--),
                icon: const Icon(Icons.chevron_left, size: 19),
                visualDensity: VisualDensity.compact,
              ),
              Text('${_pagina + 1}/$paginas',
                  style: mono(tam: 11, color: Paleta.texto2)),
              IconButton(
                onPressed: _pagina >= paginas - 1
                    ? null
                    : () => setState(() => _pagina++),
                icon: const Icon(Icons.chevron_right, size: 19),
                visualDensity: VisualDensity.compact,
              ),
            ] else
              BotonAccion(
                texto: 'Volver al mosaico',
                icono: Icons.grid_view,
                onTap: () => setState(() {
                  _seleccionada = null;
                  _zoom = 1;
                }),
              ),
          ],
        ),
      );

  Widget _mosaico(List<Camara> visibles, num segundos) {
    final columnas = switch (_rejilla) { 1 => 1, 4 => 2, 9 => 3, _ => 4 };
    return Panel(
      padding: const EdgeInsets.all(4),
      color: const Color(0xFF05080C),
      hijo: GridView.count(
        crossAxisCount: columnas,
        childAspectRatio: 16 / 9,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (final c in visibles)
            CeldaCamara(
              camara: c,
              fecha: _fecha,
              segundos: segundos,
              calidadBaja: _calidadBaja,
              onTap: () => setState(() => _seleccionada = c),
            ),
          for (var i = visibles.length; i < _rejilla; i++) const CeldaVacia(),
        ],
      ),
    );
  }

  Widget _detalle(Camara cam, num segundos) {
    final grabacion = grabacionCamara(cam, _fecha);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: EdgeInsets.zero,
          recorte: true,
          hijo: Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8.6,
                child: CeldaCamara(
                  camara: cam,
                  fecha: _fecha,
                  segundos: segundos,
                  zoom: _zoom,
                  activa: true,
                  calidadBaja: _calidadBaja,
                  nombreGrande: true,
                ),
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xB8050810),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_modo == ModoVisor.directo) ...[
                            const Punto(Paleta.critico, tam: 7, pulsa: true),
                            const SizedBox(width: 6),
                            Text('EN VIVO',
                                style: etiqueta(Colors.white)
                                    .copyWith(fontSize: 10)),
                          ] else
                            Text('REPRODUCCIÓN $_velocidad×',
                                style: etiqueta(Colors.white)
                                    .copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text('${cam.bitrate} kb/s · ${_calidadBaja ? 'SD' : 'HD'}',
                        style: mono(tam: 9.5, color: const Color(0xBFFFFFFF))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _controles(cam),
        if (_modo == ModoVisor.reproduccion) ...[
          const SizedBox(height: 12),
          Panel(
            padding: const EdgeInsets.fromLTRB(15, 12, 15, 11),
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Etiqueta('${cam.nombre} · ${cam.ubicacion}'),
                    Etiqueta(
                        '${(grabacion.minutosGrabados / 60).toStringAsFixed(1)} h grabadas · '
                        '${grabacion.eventos.length} eventos'),
                  ],
                ),
                const SizedBox(height: 14),
                LineaTiempoCamara(
                  grabacion: grabacion,
                  minuto: _minuto,
                  onBuscar: (m) =>
                      setState(() => _minuto = m.clamp(0, _topeMinuto.toDouble())),
                  onEvento: (e) => setState(() {
                    _minuto = e.minuto.toDouble();
                    _reproduciendo = true;
                  }),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _ficha(cam),
      ],
    );
  }

  Widget _controles(Camara cam) => Panel(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        hijo: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            BotonAccion(
              texto: _modo == ModoVisor.reproduccion && _reproduciendo
                  ? 'Pausa'
                  : 'Reproducir',
              icono: _modo == ModoVisor.reproduccion && _reproduciendo
                  ? Icons.pause
                  : Icons.play_arrow,
              principal: true,
              onTap: () {
                if (_modo == ModoVisor.directo) {
                  _irAModo(ModoVisor.reproduccion);
                } else {
                  setState(() => _reproduciendo = !_reproduciendo);
                }
              },
            ),
            if (_modo == ModoVisor.reproduccion) ...[
              BotonAccion(texto: '−10 s', onTap: () => _saltar(-10)),
              SizedBox(
                width: 84,
                child: Text(relojDia(_minuto * 60),
                    textAlign: TextAlign.center,
                    style: mono(tam: 13, peso: FontWeight.w700)),
              ),
              BotonAccion(texto: '+10 s', onTap: () => _saltar(10)),
              Segmentos<int>(
                opciones: const {1: '1×', 2: '2×', 4: '4×', 8: '8×', 16: '16×'},
                valor: _velocidad,
                onCambio: (v) => setState(() => _velocidad = v),
              ),
            ],
            BotonAccion(
              texto: _silencio ? 'Audio off' : 'Audio on',
              icono: _silencio ? Icons.volume_off : Icons.volume_up,
              activo: !_silencio,
              onTap: cam.audio ? () => setState(() => _silencio = !_silencio) : null,
            ),
            Segmentos<bool>(
              opciones: const {false: 'HD', true: 'SD'},
              valor: _calidadBaja,
              onCambio: (v) => setState(() => _calidadBaja = v),
            ),
            BotonAccion(
              texto: 'Zoom +',
              icono: Icons.zoom_in,
              onTap: () => setState(
                  () => _zoom = (_zoom + 0.35).clamp(1, 3).toDouble()),
            ),
            BotonAccion(
              texto: 'Reset',
              onTap: _zoom == 1 ? null : () => setState(() => _zoom = 1),
            ),
            BotonAccion(
              texto: 'Captura',
              icono: Icons.photo_camera_outlined,
              onTap: () => _aviso(
                  'Captura guardada · ${cam.nombre} ${relojDia(_modo == ModoVisor.directo ? _ahora.hour * 3600 + _ahora.minute * 60 + _ahora.second : _minuto * 60)}'),
            ),
            BotonAccion(
              texto: 'Grabar',
              icono: Icons.fiber_manual_record,
              peligro: true,
              onTap: () => _aviso('Grabando clip manual de ${cam.nombre}…'),
            ),
            BotonAccion(
              texto: 'Descargar',
              icono: Icons.download,
              onTap: () => _aviso('Descarga en cola · ${cam.id} ${isoDe(_fecha)}'),
            ),
          ],
        ),
      );

  Widget _ficha(Camara cam) => Panel(
        padding: const EdgeInsets.all(13),
        hijo: Wrap(
          spacing: 26,
          runSpacing: 12,
          children: [
            Metrica(cam.ubicacion, 'Ubicación', tam: 12),
            Metrica('${cam.sectorId} · ${cam.sectorNombre}', 'Sector', tam: 12),
            Metrica(cam.ptz ? '${cam.tipo} (con giro)' : cam.tipo, 'Tipo', tam: 12),
            Metrica(cam.resolucion, 'Resolución', tam: 12),
            Metrica(cam.ir ? 'IR activo' : 'No', 'Visión nocturna', tam: 12),
            Metrica(cam.enLinea ? 'En línea' : 'Sin señal', 'Estado',
                tam: 12, color: cam.enLinea ? Paleta.ok : Paleta.critico),
          ],
        ),
      );

  // ---------------------------------------------------------- notificaciones
  Widget _notificaciones() {
    final eventos = <EventoCamara>[];
    for (final c in _filtradas.take(14)) {
      eventos.addAll(grabacionCamara(c, _fecha).eventos);
    }
    eventos.sort((a, b) => b.minuto.compareTo(a.minuto));
    final lista = eventos.take(40).toList();

    return Panel(
      padding: const EdgeInsets.all(13),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.notifications_none, size: 15),
              const SizedBox(width: 7),
              const Text('Notificaciones',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 3),
          Etiqueta(_esHoy ? 'Hoy' : fechaLarga(_fecha)),
          const SizedBox(height: 9),
          Expanded(
            child: lista.isEmpty
                ? const Center(
                    child: Text('Sin eventos registrados.',
                        style: TextStyle(fontSize: 12, color: Paleta.texto3)))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: lista.length,
                    itemBuilder: (_, i) {
                      final e = lista[i];
                      final t = tipoCamaraPorId(e.tipo);
                      return InkWell(
                        onTap: () => setState(() {
                          _seleccionada = e.camara;
                          _modo = ModoVisor.reproduccion;
                          _minuto = e.minuto.toDouble();
                          _reproduciendo = true;
                        }),
                        borderRadius: BorderRadius.circular(9),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 3),
                                child: Punto(t.color, tam: 7),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.nombre,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(
                                        '${e.camara.nombre} · ${e.camara.ubicacion}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: etiqueta()),
                                  ],
                                ),
                              ),
                              Text(e.hora,
                                  style: mono(tam: 11, color: Paleta.texto3)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _saltar(int segundos) => setState(() =>
      _minuto = (_minuto + segundos / 60).clamp(0, _topeMinuto.toDouble()));

  void _cambiarDia(int delta) {
    final nueva = _fecha.add(Duration(days: delta));
    if (nueva.isAfter(DateTime.now())) return;
    setState(() {
      _fecha = nueva;
      _minuto = 0;
    });
  }
}

class _SelectorSector extends StatelessWidget {
  const _SelectorSector({
    required this.ciudadela,
    required this.valor,
    required this.onCambio,
  });

  final Ciudadela ciudadela;
  final String valor;
  final ValueChanged<String> onCambio;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _boton('todos', 'Todos los sectores', null),
          for (final s in ciudadela.sectores)
            _boton(s.id, s.nombre, Paleta.porRiesgo[s.riesgo]),
        ],
      );

  Widget _boton(String id, String texto, Color? color) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Material(
          color: id == valor
              ? Colors.white.withValues(alpha: 0.11)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: () => onCambio(id),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: id == valor ? Paleta.texto : Paleta.texto2,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
