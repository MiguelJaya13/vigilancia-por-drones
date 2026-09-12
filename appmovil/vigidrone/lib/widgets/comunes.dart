import 'package:flutter/material.dart';
import '../tema.dart';

/// Tarjeta base de la interfaz: fondo translúcido, borde fino y esquinas suaves.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.hijo,
    this.padding = const EdgeInsets.all(12),
    this.color,
    this.borde,
    this.recorte = false,
  });

  final Widget hijo;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borde;
  final bool recorte;

  @override
  Widget build(BuildContext context) {
    final caja = Container(
      padding: recorte ? EdgeInsets.zero : padding,
      decoration: BoxDecoration(
        color: color ?? Paleta.panel.withValues(alpha: 0.94),
        border: Border.all(color: borde ?? Paleta.linea),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x8C000000), blurRadius: 26, offset: Offset(0, 10)),
        ],
      ),
      child: recorte
          ? ClipRRect(borderRadius: BorderRadius.circular(13), child: hijo)
          : hijo,
    );
    return caja;
  }
}

/// Punto de estado, con pulso opcional.
class Punto extends StatefulWidget {
  const Punto(this.color, {super.key, this.tam = 8, this.pulsa = false});

  final Color color;
  final double tam;
  final bool pulsa;

  @override
  State<Punto> createState() => _PuntoState();
}

class _PuntoState extends State<Punto> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsa) _c.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant Punto old) {
    super.didUpdateWidget(old);
    if (widget.pulsa && !_c.isAnimating) {
      _c.repeat(reverse: true);
    } else if (!widget.pulsa && _c.isAnimating) {
      _c.stop();
      _c.value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final punto = Container(
      width: widget.tam,
      height: widget.tam,
      decoration: BoxDecoration(
        color: widget.color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: widget.color.withValues(alpha: 0.6), blurRadius: 7),
        ],
      ),
    );
    if (!widget.pulsa) return punto;
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.32).animate(_c),
      child: punto,
    );
  }
}

/// Cápsula compacta para estados y métricas sueltas.
class Ficha extends StatelessWidget {
  const Ficha({super.key, required this.texto, this.color, this.icono, this.punto});

  final String texto;
  final Color? color;
  final IconData? icono;
  final Color? punto;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Paleta.texto2;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: c.withValues(alpha: 0.32)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (punto != null) ...[Punto(punto!, tam: 7), const SizedBox(width: 6)],
          if (icono != null) ...[Icon(icono, size: 13, color: c), const SizedBox(width: 5)],
          Text(texto,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: c)),
        ],
      ),
    );
  }
}

/// Rótulo en versalitas.
class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key, this.color});

  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) =>
      Text(texto.toUpperCase(), style: etiqueta(color));
}

/// Dato con valor grande y rótulo debajo.
class Metrica extends StatelessWidget {
  const Metrica(this.valor, this.rotulo, {super.key, this.color, this.tam = 13});

  final String valor;
  final String rotulo;
  final Color? color;
  final double tam;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(valor, style: mono(tam: tam, peso: FontWeight.w700, color: color)),
          const SizedBox(height: 2),
          Etiqueta(rotulo),
        ],
      );
}

/// Barra de progreso fina (batería, avance de reproducción).
class Barra extends StatelessWidget {
  const Barra({super.key, required this.valor, required this.color, this.alto = 4});

  final double valor;
  final Color color;
  final double alto;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: valor.clamp(0, 1),
          minHeight: alto,
          backgroundColor: Colors.white.withValues(alpha: 0.09),
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
}

/// Botón compacto con ícono y texto, en dos intensidades.
class BotonAccion extends StatelessWidget {
  const BotonAccion({
    super.key,
    required this.texto,
    this.icono,
    this.onTap,
    this.principal = false,
    this.peligro = false,
    this.activo = false,
  });

  final String texto;
  final IconData? icono;
  final VoidCallback? onTap;
  final bool principal;
  final bool peligro;
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final habilitado = onTap != null;
    Color fondo, tinta, borde;
    if (principal) {
      fondo = Paleta.acento;
      tinta = const Color(0xFF04141A);
      borde = Colors.transparent;
    } else if (peligro) {
      fondo = Paleta.critico.withValues(alpha: 0.16);
      tinta = const Color(0xFFFCA5A5);
      borde = Paleta.critico.withValues(alpha: 0.35);
    } else if (activo) {
      fondo = Paleta.acento.withValues(alpha: 0.16);
      tinta = Paleta.acento;
      borde = Paleta.acento;
    } else {
      fondo = Colors.white.withValues(alpha: 0.06);
      tinta = Paleta.texto;
      borde = Paleta.linea;
    }

    return Opacity(
      opacity: habilitado ? 1 : 0.4,
      child: Material(
        color: fondo,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: borde),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icono != null) ...[Icon(icono, size: 15, color: tinta), const SizedBox(width: 7)],
                Text(texto,
                    style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600, color: tinta)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Grupo de botones tipo segmento (modo de cámara, velocidad, rejilla).
class Segmentos<T> extends StatelessWidget {
  const Segmentos({
    super.key,
    required this.opciones,
    required this.valor,
    required this.onCambio,
  });

  final Map<T, String> opciones;
  final T valor;
  final ValueChanged<T> onCambio;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in opciones.entries)
              Padding(
                padding: const EdgeInsets.only(right: 3),
                child: Material(
                  color: e.key == valor
                      ? Colors.white.withValues(alpha: 0.13)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  child: InkWell(
                    onTap: () => onCambio(e.key),
                    borderRadius: BorderRadius.circular(7),
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: e.key == valor ? Paleta.texto : Paleta.texto3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// Encabezado de panel: título y una línea de contexto.
class TituloPanel extends StatelessWidget {
  const TituloPanel(this.titulo, {super.key, this.detalle, this.accion});

  final String titulo;
  final String? detalle;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(titulo,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, height: 1.2)),
                if (detalle != null) ...[
                  const SizedBox(height: 3),
                  Etiqueta(detalle!),
                ],
              ],
            ),
          ),
          ?accion,
        ],
      );
}
