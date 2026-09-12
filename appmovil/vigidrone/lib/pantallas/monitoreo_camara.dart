import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../sim/simulador.dart';
import '../widgets/controles_vuelo.dart';
import '../widgets/feed_dron.dart';
import '../widgets/tarjeta_dron.dart';

/// Vista de cámara: el video del dron en grande y, debajo, la consola de
/// vuelo. Es la pantalla que se usa cuando el operador toma el control.
class VistaCamara extends StatelessWidget {
  const VistaCamara({
    super.key,
    required this.sim,
    required this.dronActivo,
    required this.onSeleccionar,
  });

  final Simulador sim;
  final Dron dronActivo;
  final ValueChanged<Dron> onSeleccionar;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sim,
      builder: (context, _) {
        final ancho = MediaQuery.sizeOf(context).width;
        final feed = SizedBox(
          width: ancho > 1180 ? 520 : 420,
          child: FeedDron(dron: dronActivo, ciudadela: sim.ciudadela),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sim.ciudadela.drones.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 7),
                  itemBuilder: (_, i) => FichaDron(
                    dron: sim.ciudadela.drones[i],
                    activo: sim.ciudadela.drones[i].id == dronActivo.id,
                    onTap: () => onSeleccionar(sim.ciudadela.drones[i]),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  feed,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        ControlesVuelo(
                          dron: dronActivo,
                          pausado: sim.pausado,
                          onPausa: sim.alternarPausa,
                          onAterrizar: () => sim.aterrizar(dronActivo),
                          onRetornar: () => sim.retornar(dronActivo),
                          onDespegar: () => sim.despegar(dronActivo),
                        ),
                        const SizedBox(height: 12),
                        TarjetaDron(
                          dron: dronActivo,
                          activo: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
