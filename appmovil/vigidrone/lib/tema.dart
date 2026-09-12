import 'package:flutter/material.dart';
import 'datos/ciudadela.dart';

/// Paleta y estilos de sala de control: fondo oscuro, acento cian y
/// números en tipografía monoespaciada para que la telemetría no baile.
class Paleta {
  static const fondo = Color(0xFF070A0F);
  static const panel = Color(0xFF0D121A);
  static const panelAlto = Color(0xFF161D28);
  static const linea = Color(0x17FFFFFF);
  static const lineaFuerte = Color(0x2EFFFFFF);
  static const texto = Color(0xFFE8EEF7);
  static const texto2 = Color(0xFF93A3B8);
  static const texto3 = Color(0xFF5C6B80);
  static const acento = Color(0xFF22D3EE);
  static const ok = Color(0xFF10B981);
  static const alerta = Color(0xFFF59E0B);
  static const critico = Color(0xFFEF4444);
  static const violeta = Color(0xFFA78BFA);
  static const naranja = Color(0xFFFB923C);

  static const Map<Riesgo, Color> porRiesgo = {
    Riesgo.bajo: ok,
    Riesgo.medio: alerta,
    Riesgo.alto: critico,
  };

  static Color deEstado(EstadoDron e) => switch (e) {
        EstadoDron.enVuelo => ok,
        EstadoDron.manual => acento,
        EstadoDron.retornando || EstadoDron.cargando => alerta,
        EstadoDron.sinSenal => critico,
        EstadoDron.enBase => texto3,
      };

  static Color deBateria(double b) =>
      b >= 60 ? ok : (b >= 25 ? alerta : critico);
}

const String fuenteMono = 'monospace';

/// Texto pequeño en versalitas para los rótulos de campo.
TextStyle etiqueta([Color? color]) => TextStyle(
      fontSize: 9,
      height: 1.3,
      letterSpacing: 0.9,
      fontWeight: FontWeight.w600,
      color: color ?? Paleta.texto3,
    );

TextStyle mono({
  double tam = 12,
  FontWeight peso = FontWeight.w600,
  Color? color,
}) =>
    TextStyle(
      fontFamily: fuenteMono,
      fontFamilyFallback: const ['Consolas', 'Courier New'],
      fontSize: tam,
      fontWeight: peso,
      color: color ?? Paleta.texto,
      letterSpacing: -0.2,
    );

ThemeData temaVigiDrone() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Paleta.fondo,
    colorScheme: base.colorScheme.copyWith(
      primary: Paleta.acento,
      secondary: Paleta.acento,
      surface: Paleta.panel,
      error: Paleta.critico,
      onPrimary: const Color(0xFF04141A),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: Paleta.texto,
      displayColor: Paleta.texto,
    ),
    dividerColor: Paleta.linea,
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: Paleta.acento,
      inactiveTrackColor: Paleta.lineaFuerte,
      thumbColor: Paleta.acento,
      trackHeight: 3,
      overlayShape: SliderComponentShape.noOverlay,
    ),
    checkboxTheme: base.checkboxTheme.copyWith(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? Paleta.acento
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(Color(0xFF04141A)),
      side: const BorderSide(color: Paleta.lineaFuerte, width: 1.4),
    ),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Paleta.panelAlto,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      textStyle: TextStyle(fontSize: 11, color: Paleta.texto),
    ),
  );
}
