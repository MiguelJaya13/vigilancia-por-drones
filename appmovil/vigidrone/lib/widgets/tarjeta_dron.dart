import 'package:flutter/material.dart';

import '../datos/ciudadela.dart';
import '../tema.dart';
import 'comunes.dart';

/// Tarjeta de un dron con su telemetría. Se usa tanto en la rejilla de la
/// flota como en la tira de selección rápida.
class TarjetaDron extends StatelessWidget {
  const TarjetaDron({
    super.key,
    required this.dron,
    required this.activo,
    required this.onTap,
    this.compacta = false,
  });

  final Dron dron;
  final bool activo;
  final VoidCallback onTap;
  final bool compacta;

  @override
  Widget build(BuildContext context) {
    final colorBateria = Paleta.deBateria(dron.bateria);

    return Material(
      color: activo
          ? Paleta.acento.withValues(alpha: 0.14)
          : Colors.white.withValues(alpha: 0.035),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(compacta ? 10 : 13),
          decoration: BoxDecoration(
            border: Border.all(color: activo ? Paleta.acento : Paleta.linea),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
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
                        style: TextStyle(
                            fontSize: compacta ? 13 : 14.5,
                            fontWeight: FontWeight.w600)),
                  ),
                  Text('${dron.bateria.round()}%',
                      style: mono(
                          tam: compacta ? 12 : 13.5,
                          peso: FontWeight.w700,
                          color: colorBateria)),
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
                    child: Etiqueta('Sector ${dron.sectorId}',
                        color: Paleta.texto2),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(dron.estado.texto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Paleta.texto3)),
                  ),
                ],
              ),
              SizedBox(height: compacta ? 8 : 11),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Metrica('${dron.altitud.round()} m', 'Altitud',
                      tam: compacta ? 12 : 14),
                  Metrica('${dron.velocidad.toStringAsFixed(1)} m/s', 'Velocidad',
                      tam: compacta ? 12 : 14),
                  Metrica('${dron.distanciaBase} m', 'Desde base',
                      tam: compacta ? 12 : 14),
                  if (!compacta)
                    Metrica('${dron.senal}%', 'Señal', tam: 14),
                ],
              ),
              SizedBox(height: compacta ? 8 : 11),
              Barra(valor: dron.bateria / 100, color: colorBateria),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botón compacto de la tira inferior: identifica al dron sin ocupar espacio.
class FichaDron extends StatelessWidget {
  const FichaDron({
    super.key,
    required this.dron,
    required this.activo,
    required this.onTap,
  });

  final Dron dron;
  final bool activo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: activo
            ? Paleta.acento.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(
                  color: activo ? Paleta.acento : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Punto(Paleta.deEstado(dron.estado),
                    tam: 7, pulsa: dron.estado == EstadoDron.enVuelo),
                const SizedBox(width: 7),
                Text(dron.codigo,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: activo ? Paleta.acento : Paleta.texto)),
                const SizedBox(width: 7),
                Text('${dron.bateria.round()}%',
                    style: mono(
                        tam: 11, color: Paleta.deBateria(dron.bateria))),
              ],
            ),
          ),
        ),
      );
}
