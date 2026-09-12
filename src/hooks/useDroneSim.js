import { useEffect, useRef, useState } from 'react';

const VOLANDO = new Set(['En vuelo', 'Retornando']);

/** Interpola entre dos puntos [lng, lat]. */
function lerp(a, b, t) {
  return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t];
}

/** Rumbo en grados entre dos puntos, para rotar el ícono del dron. */
function rumbo(a, b) {
  const dx = (b[0] - a[0]) * 1.12;
  const dy = b[1] - a[1];
  return (Math.atan2(dx, dy) * 180) / Math.PI;
}

const EVENTOS_SIM = [
  { txt: 'Barrido térmico completado', tipo: 'info' },
  { txt: 'Movimiento detectado en vía interna', tipo: 'alerta' },
  { txt: 'Waypoint alcanzado, continuando ruta', tipo: 'info' },
  { txt: 'Vehículo no registrado en garita', tipo: 'alerta' },
  { txt: 'Señal de video estabilizada', tipo: 'info' },
  { txt: 'Cruce de geocerca detectado', tipo: 'critico' },
  { txt: 'Batería bajo el 30%, evaluando retorno', tipo: 'alerta' },
  { txt: 'Ronda perimetral sin novedad', tipo: 'info' },
];

/**
 * Simula la telemetría en vivo de la flota de una ciudadela:
 * mueve cada dron por su ruta de patrullaje, consume batería y
 * genera entradas del registro de actividad.
 */
export function useDroneSim(ciudadela, { activo = true } = {}) {
  const [flota, setFlota] = useState(() => inicializar(ciudadela));
  const [registro, setRegistro] = useState(() => registroInicial(ciudadela));
  const tickRef = useRef(0);

  // Reinicia al cambiar de ciudadela.
  useEffect(() => {
    setFlota(inicializar(ciudadela));
    setRegistro(registroInicial(ciudadela));
    tickRef.current = 0;
  }, [ciudadela.id]);

  useEffect(() => {
    if (!activo) return undefined;
    const id = setInterval(() => {
      tickRef.current += 1;
      const t = tickRef.current;

      setFlota((prev) => prev.map((d) => {
        if (!VOLANDO.has(d.estado)) {
          // En base o cargando: recupera batería.
          const bateria = Math.min(100, d.bateria + (d.estado === 'Cargando' ? 0.35 : 0));
          const estado = d.estado === 'Cargando' && bateria >= 99.5 ? 'En base' : d.estado;
          return { ...d, bateria, estado, velocidad: 0, altitud: 0 };
        }

        const avance = d.progreso + d.paso;
        const idx = Math.floor(avance) % d.ruta.length;
        const sig = (idx + 1) % d.ruta.length;
        const frac = avance % 1;
        const pos = lerp(d.ruta[idx], d.ruta[sig], frac);
        const bateria = Math.max(0, d.bateria - 0.05);
        const estado = bateria < 20 && d.estado === 'En vuelo' ? 'Retornando' : d.estado;

        return {
          ...d,
          progreso: avance,
          posicion: pos,
          rumbo: rumbo(d.ruta[idx], d.ruta[sig]),
          bateria,
          estado,
          altitud: +(d.altitudBase + Math.sin(t / 6 + d.fase) * 1.8).toFixed(1),
          velocidad: +(d.velBase + Math.sin(t / 4 + d.fase) * 0.9).toFixed(1),
          distanciaBase: Math.round(distanciaM(pos, d.base)),
          senal: 88 + Math.round(Math.sin(t / 9 + d.fase) * 10),
          satelites: 14 + (Math.round(Math.sin(t / 11 + d.fase) * 3)),
        };
      }));

      // Nueva entrada del registro cada ~7 s.
      if (t % 7 === 0) {
        setFlota((f) => {
          const activos = f.filter((d) => VOLANDO.has(d.estado));
          if (!activos.length) return f;
          const d = activos[Math.floor(Math.random() * activos.length)];
          const e = EVENTOS_SIM[Math.floor(Math.random() * EVENTOS_SIM.length)];
          setRegistro((r) => [{
            id: `${Date.now()}-${d.id}`,
            hora: new Date().toLocaleTimeString('es-EC', { hour12: false }),
            dron: d.nombre,
            sector: d.sector,
            texto: e.txt,
            tipo: e.tipo,
          }, ...r].slice(0, 60));
          return f;
        });
      }
    }, 1000);
    return () => clearInterval(id);
  }, [activo, ciudadela.id]);

  return { flota, registro, setFlota };
}

function inicializar(cd) {
  return cd.drones.map((d, i) => ({
    ...d,
    progreso: i * 0.7,
    paso: 0.012 + (i % 3) * 0.004,
    fase: i * 1.7,
    altitudBase: 38 + i * 7,
    velBase: 5.5 + (i % 4),
    altitud: VOLANDO.has(d.estado) ? 38 + i * 7 : 0,
    velocidad: VOLANDO.has(d.estado) ? 5.5 + (i % 4) : 0,
    distanciaBase: Math.round(distanciaM(d.posicion, cd.centro)),
    rumbo: 0,
    senal: 92,
    satelites: 15,
  }));
}

function registroInicial(cd) {
  const base = new Date();
  return [
    { dron: cd.drones[0]?.nombre, texto: 'Misión de patrullaje iniciada', tipo: 'info', sector: 'A' },
    { dron: cd.drones[1]?.nombre, texto: 'Enlace de video 4K establecido', tipo: 'info', sector: 'B' },
    { dron: cd.drones[2]?.nombre, texto: 'Ronda perimetral sin novedad', tipo: 'info', sector: 'C' },
  ].filter((e) => e.dron).map((e, i) => ({
    ...e,
    id: `init-${cd.id}-${i}`,
    hora: new Date(base.getTime() - (i + 1) * 95000).toLocaleTimeString('es-EC', { hour12: false }),
  }));
}

/** Distancia aproximada en metros entre dos puntos [lng, lat]. */
function distanciaM(a, b) {
  const dx = (a[0] - b[0]) * 111320 * Math.cos((a[1] * Math.PI) / 180);
  const dy = (a[1] - b[1]) * 110540;
  return Math.sqrt(dx * dx + dy * dy);
}
