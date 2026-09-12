import 'package:flutter/material.dart';

import 'datos/ciudadela.dart';
import 'pantallas/bitacora.dart';
import 'pantallas/camaras.dart';
import 'pantallas/monitoreo.dart';
import 'sim/simulador.dart';
import 'tema.dart';
import 'widgets/comunes.dart';

class VigiDroneApp extends StatelessWidget {
  const VigiDroneApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'VigiDrone',
        debugShowCheckedModeBanner: false,
        theme: temaVigiDrone(),
        home: const Consola(),
      );
}

/// Consola de la ciudadela. Cada instalación de VigiDrone vigila una sola
/// urbanización, así que no hay selector: la ciudadela es la del contrato.
class Consola extends StatefulWidget {
  const Consola({super.key});

  @override
  State<Consola> createState() => _ConsolaState();
}

class _ConsolaState extends State<Consola> {
  late final Ciudadela _ciudadela = construirCiudadela();
  late final Simulador _sim = Simulador(_ciudadela);
  int _seccion = 0;

  @override
  void dispose() {
    _sim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final extendido = ancho >= 1180;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _Riel(
              seccion: _seccion,
              extendido: extendido,
              ciudadela: _ciudadela,
              sim: _sim,
              onCambio: (i) => setState(() => _seccion = i),
            ),
            Expanded(
              child: switch (_seccion) {
                0 => PantallaMonitoreo(sim: _sim),
                1 => PantallaCamaras(ciudadela: _ciudadela),
                _ => PantallaBitacora(ciudadela: _ciudadela),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Riel extends StatelessWidget {
  const _Riel({
    required this.seccion,
    required this.extendido,
    required this.ciudadela,
    required this.sim,
    required this.onCambio,
  });

  final int seccion;
  final bool extendido;
  final Ciudadela ciudadela;
  final Simulador sim;
  final ValueChanged<int> onCambio;

  static const _secciones = [
    (Icons.flight, 'Monitoreo'),
    (Icons.videocam_outlined, 'Cámaras'),
    (Icons.event_note_outlined, 'Bitácora'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extendido ? 196 : 78,
      decoration: const BoxDecoration(
        color: Paleta.panel,
        border: Border(right: BorderSide(color: Paleta.linea)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marca y ciudadela vigilada.
          Padding(
            padding: EdgeInsets.fromLTRB(extendido ? 16 : 12, 18, 12, 16),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Paleta.acento, Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.shield_outlined,
                      size: 19, color: Color(0xFF04141A)),
                ),
                if (extendido) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                            fontSize: 15.5,
                            color: Paleta.texto,
                            letterSpacing: -0.3),
                        children: [
                          TextSpan(text: 'Vigi'),
                          TextSpan(
                            text: 'Drone',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Paleta.acento),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (extendido)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ciudadela.nombre,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 3),
                  Etiqueta(ciudadela.direccion),
                ],
              ),
            ),

          const Divider(height: 1),
          const SizedBox(height: 10),

          for (var i = 0; i < _secciones.length; i++)
            _Item(
              icono: _secciones[i].$1,
              texto: _secciones[i].$2,
              activo: i == seccion,
              extendido: extendido,
              onTap: () => onCambio(i),
            ),

          const Spacer(),

          // Estado de la flota, siempre visible.
          ListenableBuilder(
            listenable: sim,
            builder: (context, _) {
              final enVuelo =
                  ciudadela.drones.where((d) => d.estado.volando).length;
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: extendido ? 14 : 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (extendido) ...[
                      const Etiqueta('Flota'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Punto(enVuelo > 0 ? Paleta.ok : Paleta.texto3,
                              pulsa: enVuelo > 0),
                          const SizedBox(width: 8),
                          Text('$enVuelo de ${ciudadela.drones.length} en vuelo',
                              style: const TextStyle(fontSize: 11.5)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (sim.alertas > 0)
                        Ficha(
                          texto: '${sim.alertas} alertas',
                          icono: Icons.warning_amber_rounded,
                          color: Paleta.alerta,
                        ),
                    ] else
                      Center(
                        child: Punto(enVuelo > 0 ? Paleta.ok : Paleta.texto3,
                            pulsa: enVuelo > 0),
                      ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: extendido ? 14 : 10),
            child: Row(
              mainAxisAlignment:
                  extendido ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_outline, size: 16, color: Paleta.texto3),
                if (extendido) ...[
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Garita · Entre Ríos',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: Paleta.texto2)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icono,
    required this.texto,
    required this.activo,
    required this.extendido,
    required this.onTap,
  });

  final IconData icono;
  final String texto;
  final bool activo;
  final bool extendido;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(horizontal: extendido ? 10 : 12, vertical: 3),
        child: Material(
          color: activo ? Paleta.acento.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(11),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: extendido ? 12 : 0, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: activo ? Paleta.acento.withValues(alpha: 0.4) : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    extendido ? MainAxisAlignment.start : MainAxisAlignment.center,
                children: [
                  Icon(icono,
                      size: 20, color: activo ? Paleta.acento : Paleta.texto2),
                  if (extendido) ...[
                    const SizedBox(width: 11),
                    Text(
                      texto,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                        color: activo ? Paleta.acento : Paleta.texto2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
}
