import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show relojDia;
import '../sim/simulador.dart';
import '../tema.dart';
import 'comunes.dart';

Color colorEvento(TipoEvento t) => switch (t) {
      TipoEvento.info => Paleta.acento,
      TipoEvento.alerta => Paleta.alerta,
      TipoEvento.critico => Paleta.critico,
    };

int _segundosDe(DateTime d) => d.hour * 3600 + d.minute * 60 + d.second;

/// Registro de actividad como panel lateral. Se abre solo cuando el operador
/// lo pide, para no robarle espacio permanente al mapa.
class PanelActividad extends StatelessWidget {
  const PanelActividad({super.key, required this.sim, required this.onCerrar});

  final Simulador sim;
  final VoidCallback onCerrar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) {
        final eventos = sim.registro;

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 12, 12),
          child: Panel(
            padding: EdgeInsets.zero,
            hijo: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(13, 11, 8, 11),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Paleta.linea)),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Registro de actividad',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      if (sim.alertas > 0)
                        Ficha(
                          texto: '${sim.alertas}',
                          icono: Icons.warning_amber_rounded,
                          color: Paleta.alerta,
                        ),
                      IconButton(
                        onPressed: onCerrar,
                        icon: const Icon(Icons.close, size: 17),
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Cerrar',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: eventos.isEmpty
                      ? const Center(
                          child: Text('Sin eventos todavía.',
                              style:
                                  TextStyle(fontSize: 12, color: Paleta.texto3)),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: eventos.length,
                          itemBuilder: (_, i) {
                            final e = eventos[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Punto(colorEvento(e.tipo), tam: 7),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(e.texto,
                                            style:
                                                const TextStyle(fontSize: 12.5)),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Text(relojDia(_segundosDe(e.hora)),
                                                style: mono(
                                                    tam: 10,
                                                    color: Paleta.texto3)),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Etiqueta(
                                                  '${e.dron} · Sector ${e.sector}'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
