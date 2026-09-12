import 'package:flutter/material.dart';

import '../datos/bitacora.dart' show relojDia;
import '../sim/simulador.dart';
import '../tema.dart';
import 'comunes.dart';

Color _colorEvento(TipoEvento t) => switch (t) {
      TipoEvento.info => Paleta.acento,
      TipoEvento.alerta => Paleta.alerta,
      TipoEvento.critico => Paleta.critico,
    };

int _segundosDe(DateTime d) => d.hour * 3600 + d.minute * 60 + d.second;

/// Barra flotante con el último evento; se despliega al tocarla.
class RegistroActividad extends StatefulWidget {
  const RegistroActividad({super.key, required this.eventos});

  final List<EventoRegistro> eventos;

  @override
  State<RegistroActividad> createState() => _RegistroActividadState();
}

class _RegistroActividadState extends State<RegistroActividad> {
  bool _abierto = false;

  @override
  Widget build(BuildContext context) {
    final ultimo = widget.eventos.isEmpty ? null : widget.eventos.first;
    final alertas =
        widget.eventos.where((e) => e.tipo != TipoEvento.info).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 8, 9, 8),
          hijo: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Etiqueta('Registro de actividad'),
              const SizedBox(width: 12),
              if (ultimo != null) ...[
                Punto(_colorEvento(ultimo.tipo), tam: 7, pulsa: true),
                const SizedBox(width: 7),
                Text(relojDia(_segundosDe(ultimo.hora)),
                    style: mono(tam: 11, color: Paleta.texto2)),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Text(
                    '${ultimo.dron} — ${ultimo.texto}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              if (alertas > 0) ...[
                const SizedBox(width: 10),
                Ficha(
                  texto: '$alertas',
                  color: Paleta.alerta,
                  icono: Icons.warning_amber_rounded,
                ),
              ],
              const SizedBox(width: 10),
              BotonAccion(
                texto: _abierto ? 'Cerrar' : 'Ver todo',
                onTap: () => setState(() => _abierto = !_abierto),
              ),
            ],
          ),
        ),
        if (_abierto) ...[
          const SizedBox(height: 8),
          Panel(
            padding: const EdgeInsets.all(6),
            hijo: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 620),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: widget.eventos.length,
                itemBuilder: (_, i) {
                  final e = widget.eventos[i];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Punto(_colorEvento(e.tipo), tam: 7),
                        ),
                        const SizedBox(width: 9),
                        Text(relojDia(_segundosDe(e.hora)),
                            style: mono(tam: 11, color: Paleta.texto3)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.texto,
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 2),
                              Etiqueta('${e.dron} · Sector ${e.sector}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
