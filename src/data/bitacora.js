// Generador determinista de la bitácora de vuelos y grabaciones.
// La misma fecha + ciudadela + sector siempre devuelve los mismos registros,
// así la demo es reproducible sin backend.

import { CIUDADELAS } from './ciudadelas.js';

/** PRNG determinista (mulberry32) a partir de una semilla de texto. */
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

export const TIPOS_EVENTO = [
  { id: 'patrullaje', nombre: 'Patrullaje rutinario', color: '#22d3ee', peso: 58 },
  { id: 'movimiento', nombre: 'Movimiento detectado', color: '#a78bfa', peso: 18 },
  { id: 'vehiculo', nombre: 'Vehículo no registrado', color: '#f59e0b', peso: 12 },
  { id: 'perimetro', nombre: 'Alerta perimetral', color: '#fb923c', peso: 8 },
  { id: 'intrusion', nombre: 'Intrusión confirmada', color: '#ef4444', peso: 4 },
];

const TIPO_POR_ID = Object.fromEntries(TIPOS_EVENTO.map((t) => [t.id, t]));
export const getTipo = (id) => TIPO_POR_ID[id] || TIPOS_EVENTO[0];

const DETALLES = {
  patrullaje: [
    'Recorrido perimetral completo sin novedad',
    'Barrido térmico programado, sin hallazgos',
    'Verificación de puntos ciegos de cámaras fijas',
    'Ronda nocturna con iluminación IR',
  ],
  movimiento: [
    'Movimiento detectado en zona verde, descartado (fauna)',
    'Persona no identificada caminando por vía interna',
    'Actividad detectada fuera de horario en área común',
    'Grupo de personas en cancha fuera de horario',
  ],
  vehiculo: [
    'Vehículo sin registro en garita, placa capturada',
    'Camioneta estacionada en zona prohibida 14 min',
    'Motocicleta circulando sin autorización',
    'Vehículo de carga sin orden de ingreso',
  ],
  perimetro: [
    'Cruce de geocerca en muro perimetral',
    'Objeto arrojado sobre el cerramiento',
    'Escalamiento detectado en muro posterior',
    'Apertura no autorizada de puerta de servicio',
  ],
  intrusion: [
    'Intrusión confirmada, alerta enviada a guardia',
    'Persona dentro del predio sin autorización, 911 notificado',
    'Ingreso forzado detectado, seguimiento activo',
  ],
};

function pick(r, arr) {
  return arr[Math.floor(r() * arr.length)];
}

function tipoPonderado(r) {
  const total = TIPOS_EVENTO.reduce((s, t) => s + t.peso, 0);
  let v = r() * total;
  for (const t of TIPOS_EVENTO) {
    v -= t.peso;
    if (v <= 0) return t.id;
  }
  return 'patrullaje';
}

const dosDig = (n) => String(n).padStart(2, '0');

/** Fecha ISO (YYYY-MM-DD) de hoy en local. */
export function hoyISO(d = new Date()) {
  return `${d.getFullYear()}-${dosDig(d.getMonth() + 1)}-${dosDig(d.getDate())}`;
}

export function formatoFechaLarga(iso) {
  const [a, m, d] = iso.split('-').map(Number);
  const fecha = new Date(a, m - 1, d);
  return fecha.toLocaleDateString('es-EC', {
    weekday: 'long', day: 'numeric', month: 'long', year: 'numeric',
  });
}

/** Últimos `n` días como ISO, del más reciente al más antiguo. */
export function ultimosDias(n = 30, desde = new Date()) {
  const out = [];
  for (let i = 0; i < n; i++) {
    const d = new Date(desde);
    d.setDate(d.getDate() - i);
    out.push(hoyISO(d));
  }
  return out;
}

/**
 * Grabaciones de un día para una ciudadela.
 * Cada registro es un segmento de video con su evento asociado.
 */
export function grabacionesDe(ciudadelaId, fechaISO) {
  const cd = CIUDADELAS.find((c) => c.id === ciudadelaId);
  if (!cd) return [];
  const r = rng(`${ciudadelaId}|${fechaISO}`);
  const total = 26 + Math.floor(r() * 18); // 26-43 segmentos por día
  const registros = [];

  for (let i = 0; i < total; i++) {
    const minutoDia = Math.floor(r() * 1440);
    const hora = Math.floor(minutoDia / 60);
    const min = minutoDia % 60;
    const sector = cd.sectores[Math.floor(r() * cd.sectores.length)];
    const dron = cd.drones[Math.floor(r() * cd.drones.length)];
    let tipo = tipoPonderado(r);
    // De madrugada suben las alertas; de día predomina el patrullaje.
    if (hora >= 1 && hora <= 5 && r() < 0.4) tipo = pick(r, ['movimiento', 'perimetro', 'intrusion']);
    if (hora >= 9 && hora <= 16 && r() < 0.5) tipo = 'patrullaje';

    const duracion = tipo === 'patrullaje'
      ? 240 + Math.floor(r() * 900)
      : 45 + Math.floor(r() * 420);

    registros.push({
      id: `${ciudadelaId}-${fechaISO}-${i}`,
      fecha: fechaISO,
      hora: `${dosDig(hora)}:${dosDig(min)}`,
      minutoDia,
      duracion, // segundos
      ciudadela: ciudadelaId,
      sectorId: sector.id,
      sectorNombre: sector.nombre,
      dronId: dron.id,
      dronNombre: dron.nombre,
      tipo,
      detalle: pick(r, DETALLES[tipo]),
      resolucion: r() > 0.35 ? '4K · 30fps' : '1080p · 60fps',
      camara: r() > 0.5 ? 'RGB + Térmica' : 'RGB',
      pesoMB: Math.round((duracion / 60) * (r() > 0.35 ? 210 : 95)),
      revisado: r() > 0.45,
    });
  }

  return registros.sort((a, b) => a.minutoDia - b.minutoDia);
}

/** Resumen de un día para las tarjetas de estadísticas. */
export function resumenDia(registros) {
  const seg = registros.reduce((s, g) => s + g.duracion, 0);
  const alertas = registros.filter((g) => g.tipo !== 'patrullaje').length;
  const criticas = registros.filter((g) => g.tipo === 'intrusion' || g.tipo === 'perimetro').length;
  const gb = registros.reduce((s, g) => s + g.pesoMB, 0) / 1024;
  return {
    segmentos: registros.length,
    horas: (seg / 3600).toFixed(1),
    alertas,
    criticas,
    almacenamiento: gb.toFixed(1),
    pendientes: registros.filter((g) => !g.revisado).length,
  };
}

export function duracionTexto(seg) {
  const m = Math.floor(seg / 60);
  const s = seg % 60;
  return `${m}:${dosDig(s)}`;
}
