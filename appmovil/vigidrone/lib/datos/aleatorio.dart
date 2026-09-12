/// Generador pseudoaleatorio determinista (mulberry32).
///
/// La misma semilla siempre produce la misma secuencia, así la bitácora y
/// las grabaciones de un día son idénticas en cada arranque: la demo es
/// reproducible sin necesidad de un servidor.
class Aleatorio {
  Aleatorio(String semilla) : _estado = _hash(semilla);

  int _estado;

  static int _hash(String s) {
    var h = 1779033703 ^ s.length;
    for (var i = 0; i < s.length; i++) {
      h = (h ^ s.codeUnitAt(i)) * 3432918353;
      h = h & 0xFFFFFFFF;
      h = ((h << 13) | (h >>> 19)) & 0xFFFFFFFF;
    }
    return h & 0xFFFFFFFF;
  }

  /// Siguiente valor en [0, 1).
  double siguiente() {
    _estado = (_estado + 0x6D2B79F5) & 0xFFFFFFFF;
    var t = _estado;
    t = (t ^ (t >>> 15)) * (t | 1) & 0xFFFFFFFF;
    t = (t ^ (t + ((t ^ (t >>> 7)) * (t | 61) & 0xFFFFFFFF))) & 0xFFFFFFFF;
    return ((t ^ (t >>> 14)) & 0xFFFFFFFF) / 4294967296.0;
  }

  /// Entero en [0, tope).
  int entero(int tope) => (siguiente() * tope).floor();

  /// Un elemento cualquiera de la lista.
  T elemento<T>(List<T> lista) => lista[entero(lista.length)];

  /// Verdadero con probabilidad [p].
  bool probabilidad(double p) => siguiente() < p;

  /// Decimal en [min, max).
  double rango(double min, double max) => min + siguiente() * (max - min);
}
