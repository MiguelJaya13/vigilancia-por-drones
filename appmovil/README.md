# VigiDrone · app de ciudadela

Consola de vigilancia por drones **para una sola ciudadela**, pensada para la
tablet de la garita. Es la versión descentralizada del sistema: en vez de un
centro de monitoreo que ve las cuatro urbanizaciones, cada ciudadela opera la
suya desde su propia tablet.

Hecha en **Flutter** (Android + Web), con las mismas funcionalidades que la
versión web del centro de operaciones.

## Pantallas

| Sección | Qué hace |
|---|---|
| **Monitoreo** | Mapa satelital con la flota moviéndose en vivo, telemetría por dron, geocerca, sectores por nivel de riesgo, cámara del dron (RGB / IR / térmica) con gimbal, registro de actividad y consola de vuelo con joysticks táctiles. |
| **Cámaras** | Mosaico del NVR (1 / 2×2 / 3×3 / 4×4) con paginación, sello de fecha-hora quemado en el frame, estado sin señal, vista en directo y reproducción con línea de tiempo del día, saltos de ±10 s, 1×–16×, HD/SD, zoom, captura, grabación y descarga. Panel de notificaciones que salta a la cámara, el día y el minuto del evento. |
| **Bitácora** | Calendario del mes con densidad de alertas, filtro por sector y tipo de evento, línea de tiempo de 24 h, reproductor y tabla de grabaciones. |

## Correr la app

```bash
cd appmovil/vigidrone
flutter pub get

flutter run -d chrome          # demo rápida en el navegador
flutter run -d <tablet>        # en la tablet conectada por USB
flutter build apk --release    # APK para instalar en la tablet
```

El APK queda en `build/app/outputs/flutter-apk/app-release.apk`.

## Cómo está armado

```
lib/
  datos/       ciudadela, cámaras, bitácora y el generador determinista
  sim/         telemetría en vivo de la flota (ChangeNotifier + Timer)
  pantallas/   monitoreo · cámaras · bitácora
  widgets/     mapa, panel de flota, feed, croquis, reproductor, calendario
  util/        cálculo de tiles satelitales
  tema.dart    paleta y estilos de sala de control
```

**Sin backend.** La telemetría se simula y las grabaciones se generan de forma
determinista: la misma fecha y el mismo sector devuelven siempre los mismos
registros, así la demo no depende de la red ni de un servidor. Para conectar
datos reales solo cambia la fuente: `Simulador` pasaría a leer el enlace MQTT
del dock y `grabacionesDe` a consultar la API — la interfaz no cambia.

## Cambiar de ciudadela

Cada instalación atiende una urbanización. Está definida en
`lib/datos/ciudadela.dart`: centro, tamaño del recinto, sectores y flota.
Cambiar esas constantes despliega la app en otra ciudadela.

El centro actual (Ciudadela Entre Ríos, Vía a Samborondón) está verificado
contra la imagen satelital y nombrado por geocodificación inversa de
OpenStreetMap, así el recinto cae sobre manzanas urbanizadas.

## Mapas

MapLibre no aplica aquí: se usa **flutter_map** con imágenes satelitales de
**Esri World Imagery**, sin API key ni tarjeta de crédito, para que la demo no
dependa de una cuenta de facturación.
