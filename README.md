# FALCOM 360 · Vigilancia por Drones

Sistema web de monitoreo aéreo autónomo para ciudadelas y urbanizaciones cerradas.
Proyecto desarrollado para **Startup Weekend**.

## El problema

Las ciudadelas dependen de cámaras fijas con puntos ciegos y de guardias que no
pueden cubrir todo el perímetro a la vez. Cuando ocurre un incidente, revisar la
grabación significa buscar a mano en horas de video de una cámara que quizá no
apuntaba al lugar correcto.

## La solución

Drones en patrullaje autónomo por sectores, con video en vivo hacia una central de
monitoreo y una **bitácora indexada por día y por sector**: en dos clics se llega
a la grabación exacta del lugar y la hora del evento.

## Pantallas

| Ruta | Pantalla | Qué hace |
|---|---|---|
| `/` | **Centro de operaciones** | Las 4 ciudadelas (CD1–CD4) con estado de flota, alertas del día y accesos directos. |
| `/monitoreo/:cdId` | **Monitoreo en vivo** | Mapa satelital con drones moviéndose en tiempo real, telemetría por dron, feed de cámara (RGB / IR / térmica), registro de actividad, geocerca, sectores y controles de vuelo. Una vista por ciudadela. |
| `/bitacora/:cdId` | **Bitácora** | Calendario para elegir el día, filtro por sector y por tipo de evento, línea de tiempo de 24 h, reproductor de la grabación y tabla exportable a CSV. |

## Stack

- **React 18 + Vite** — SPA rápida, ideal para dashboards con estado en vivo.
- **MapLibre GL JS** — mapas sin API key ni tarjeta de crédito.
- **Esri World Imagery** — imágenes satelitales gratuitas para el prototipo.
- **CSS propio** — sin framework de UI, para controlar el look de sala de control.

Sin backend: la telemetría y las grabaciones se simulan de forma **determinista**
(la misma fecha y sector devuelven siempre los mismos registros), así la demo
nunca falla por falta de conexión a un servidor.

## Cómo correrlo

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # genera dist/
```

> Nota: `npm install` debe ejecutarse en un disco local. Google Drive (unidad `G:`)
> no soporta `node_modules` y falla con `EBADF`.

## Estructura

```
src/
  data/ciudadelas.js   Ciudadelas, sectores, geocercas y flota
  data/bitacora.js     Generador determinista de grabaciones y eventos
  hooks/useDroneSim.js Simulación de telemetría en vivo
  components/          Mapa, panel de flota, feed, reproductor, calendario…
  pages/               Ciudadelas · Monitoreo · Bitácora
  styles/              Sistema de estilos
```

## Camino a producción

1. **Backend**: API REST/WebSocket para telemetría (MQTT desde el dock del dron).
2. **Video**: HLS/WebRTC en lugar del feed simulado; almacenamiento en S3 con
   índice por `ciudadela + sector + timestamp`.
3. **Detección**: modelo de visión sobre el stream para clasificar los eventos
   que hoy están simulados (persona, vehículo, escalamiento).
4. **Integración DGAC**: registro de vuelos y cumplimiento de altura máxima.
5. **App para residentes**: alertas y botón de pánico enlazado al dron más cercano.

## Datos del prototipo

Cuatro ciudadelas de la Vía a Samborondón (Guayas, Ecuador): La Puntilla,
Entre Ríos, Villa Club y Ciudad Celeste — 1.835 viviendas y 125 cámaras fijas
enlazadas en total.
