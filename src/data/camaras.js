// Cámaras fijas por ciudadela (el NVR de cada urbanización) y su grabación diaria.
// Igual que la bitácora, todo es determinista: misma cámara + fecha = mismos datos.

import { CIUDADELAS } from './ciudadelas.js';

function rng(semilla) {
  let h = 1779033703 ^ semilla.length;
  for (let i = 0; i < semilla.length; i++) {
    h = Math.imul(h ^ semilla.charCodeAt(i), 3432918353);
    h = (h << 13) | (h >>> 19);
  }
  let a = h >>> 0;
  return function () {
    a |= 0; a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

const UBICACIONES = [
  'Carril de ingreso', 'Carril de salida', 'Garita — peatonal', 'Muro perimetral',
  'Vía interna', 'Área de juegos', 'Cancha múltiple', 'Piscina', 'Parqueadero de visitas',
  'Portón vehicular', 'Esquina norte', 'Esquina sur', 'Callejón de servicio',
  'Acceso a bodegas', 'Zona de basura', 'Puerta de servicio', 'Ciclovía',
  'Plazoleta central', 'Ingreso al club', 'Paso peatonal',
];

const TIPOS = ['Fija', 'Fija', 'Fija', 'PTZ', 'LPR', 'Térmica'];

/** Todas las cámaras fijas de una ciudadela. */
export function camarasDe(ciudadelaId) {
  const cd = CIUDADELAS.find((c) => c.id === ciudadelaId);
  if (!cd) return [];
  const r = rng(`cam|${ciudadelaId}`);

  return Array.from({ length: cd.camaras }, (_, i) => {
    const sector = cd.sectores[i % cd.sectores.length];
    const tipo = TIPOS[Math.floor(r() * TIPOS.length)];
    const offline = r() < 0.07;
    // Dispersa la cámara dentro de su sector.
    const jx = (r() - 0.5) * 0.0016;
    const jy = (r() - 0.5) * 0.0011;

    return {
      id: `${cd.codigo}-CAM${String(i + 1).padStart(2, '0')}`,
      nombre: `Cámara ${String(i + 1).padStart(2, '0')}`,
      ubicacion: UBICACIONES[Math.floor(r() * UBICACIONES.length)],
      ciudadela: cd.id,
      sectorId: sector.id,
      sectorNombre: sector.nombre,
      tipo,
      ptz: tipo === 'PTZ',
      audio: r() > 0.45,
      ir: r() > 0.3,
      resolucion: r() > 0.4 ? '4MP · 2560×1440' : '1080p · 1920×1080',
      bitrate: Math.round(1400 + r() * 3200),
      estado: offline ? 'offline' : 'online',
      posicion: [sector.centro[0] + jx, sector.centro[1] + jy],
    };
  });
}

export const TIPOS_EVENTO_CAM = {
  movimiento: { nombre: 'Movimiento', color: '#a78bfa' },
  persona: { nombre: 'Persona detectada', color: '#f59e0b' },
  vehiculo: { nombre: 'Vehículo', color: '#22d3ee' },
  linea: { nombre: 'Cruce de línea', color: '#fb923c' },
  manipulacion: { nombre: 'Manipulación de cámara', color: '#ef4444' },
};

const IDS_EVENTO = Object.keys(TIPOS_EVENTO_CAM);

/**
 * Grabación de una cámara en un día: tramos grabados (el NVR graba en
 * continuo, con cortes por reinicio o pérdida de enlace) y marcas de evento.
 */
export function grabacionCamara(camaraId, fechaISO, esHoy = false) {
  const r = rng(`${camaraId}|${fechaISO}`);
  const finDia = esHoy
    ? new Date().getHours() * 60 + new Date().getMinutes()
    : 1440;

  // Tramos grabados con 0-3 cortes.
  const cortes = Math.floor(r() * 4);
  const huecos = Array.from({ length: cortes }, () => {
    const inicio = Math.floor(r() * Math.max(1, finDia - 40));
    return { inicio, fin: inicio + 4 + Math.floor(r() * 26) };
  }).sort((a, b) => a.inicio - b.inicio);

  const segmentos = [];
  let cursor = 0;
  for (const h of huecos) {
    if (h.inicio > cursor) segmentos.push({ inicio: cursor, fin: Math.min(h.inicio, finDia) });
    cursor = Math.max(cursor, Math.min(h.fin, finDia));
  }
  if (cursor < finDia) segmentos.push({ inicio: cursor, fin: finDia });

  // Marcas de evento (más densas de noche).
  const total = 6 + Math.floor(r() * 16);
  const eventos = Array.from({ length: total }, (_, i) => {
    let minuto = Math.floor(r() * finDia);
    if (r() < 0.35) minuto = Math.floor(r() * Math.min(360, finDia)); // madrugada
    const tipo = IDS_EVENTO[Math.floor(r() * IDS_EVENTO.length)];
    return { id: `${camaraId}-${fechaISO}-${i}`, minuto, tipo, duracion: 20 + Math.floor(r() * 160) };
  }).filter((e) => segmentos.some((s) => e.minuto >= s.inicio && e.minuto < s.fin))
    .sort((a, b) => a.minuto - b.minuto);

  const grabado = segmentos.reduce((s, x) => s + (x.fin - x.inicio), 0);

  return { segmentos, eventos, finDia, minutosGrabados: grabado };
}

/** hh:mm:ss a partir de los segundos transcurridos del día. */
export function relojDia(segundos) {
  const s = Math.max(0, Math.floor(segundos));
  return [Math.floor(s / 3600) % 24, Math.floor(s / 60) % 60, s % 60]
    .map((n) => String(n).padStart(2, '0')).join(':');
}

/** Fecha con día de semana abreviado, como la marca de agua del NVR. */
export function selloFecha(fechaISO, segundos) {
  const [a, m, d] = fechaISO.split('-');
  const dias = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
  const dow = dias[new Date(+a, +m - 1, +d).getDay()];
  return `${d}-${m}-${a} ${dow} ${relojDia(segundos)}`;
}
