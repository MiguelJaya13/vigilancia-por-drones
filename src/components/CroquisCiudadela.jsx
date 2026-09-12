import { RIESGO_COLOR } from '../data/ciudadelas.js';
import { DRON_SVG_INTERNO } from './IconoDron.jsx';

// Croquis cuadrado de la ciudadela: el recinto, sus cuatro sectores y los
// drones recorriendo la secuencia de patrullaje de su propio sector.
// Cada ícono lleva el código del dron, de modo que el croquis y la ficha
// de la flota digan lo mismo: el dron del sector B se ve en el sector B.

// Límites de cada cuadrante en el viewBox (0-100).
const CUADRANTE = { A: [8, 8], B: [56, 8], C: [8, 56], D: [56, 56] };
const LADO = 36;

/**
 * Barrido en serpentina dentro del sector: el patrón real de levantamiento
 * aéreo. `variante` separa a dos drones que comparten sector.
 */
function rutaSector(sector, variante = 0) {
  const [bx, by] = CUADRANTE[sector] || CUADRANTE.A;
  const m = 4 + variante * 4.5;
  const x0 = bx + m, x1 = bx + LADO - m;
  const y0 = by + m, y1 = by + LADO - m;
  const ym = (y0 + y1) / 2;
  return `M ${x0},${y0} H ${x1} V ${ym} H ${x0} V ${y1} H ${x1}`;
}

const LETRA = { A: [10, 15], B: [90, 15], C: [10, 93], D: [90, 93] };
const EN_VUELO = new Set(['En vuelo', 'Retornando']);

/** Código corto del dron: 'CD1-D2' → 'D2'. */
const codigoCorto = (id) => id.split('-').pop();

/**
 * Avanza y se detiene en cada waypoint, como un vuelo programado:
 * el 80% de cada tramo desplazándose y el 20% en punto fijo.
 */
function porEtapas(n) {
  const puntos = [], tiempos = [];
  for (let i = 0; i <= n; i++) {
    const p = (i / n).toFixed(4);
    puntos.push(p);
    tiempos.push((i === 0 ? 0 : (i - 0.2) / n).toFixed(4));
    puntos.push(p);
    tiempos.push((i / n).toFixed(4));
  }
  // keyTimes tiene que empezar en 0 y terminar en 1: si no, el navegador
  // descarta la animación completa y el dron se queda en el origen.
  return { keyPoints: puntos.join(';'), keyTimes: tiempos.join(';') };
}

const ETAPAS = 5;

export default function CroquisCiudadela({ ciudadela, tamano = 92 }) {
  const enVuelo = ciudadela.drones.filter((d) => EN_VUELO.has(d.estado));
  const enBase = ciudadela.drones.length - enVuelo.length;
  const { keyPoints, keyTimes } = porEtapas(ETAPAS);

  // Cuántos drones lleva ya cada sector, para separarlos si coinciden.
  const usados = {};
  const plan = enVuelo.map((d, i) => {
    const v = usados[d.sector] = (usados[d.sector] ?? -1) + 1;
    return {
      id: d.id,
      codigo: codigoCorto(d.id),
      nombre: d.nombre,
      sector: d.sector,
      ruta: rutaSector(d.sector, v),
      dur: 13 + v * 3 + (i % 3),
      inicio: -3.1 * i,
    };
  });

  return (
    <svg
      className="croquis"
      width={tamano}
      height={tamano}
      viewBox="0 0 100 100"
      role="img"
      aria-label={`Croquis de ${ciudadela.nombre}: ${enVuelo.length} drones en patrullaje`}
    >
      {/* recinto */}
      <rect x="3" y="3" width="94" height="94" rx="7"
        fill="rgba(34,211,238,.05)" stroke="rgba(34,211,238,.4)" strokeWidth="1.4" />

      {/* división de sectores */}
      <path d="M50,6 V94 M6,50 H94" stroke="rgba(255,255,255,.14)" strokeWidth="1" strokeDasharray="3 3" />

      {/* cuadrantes teñidos según riesgo */}
      {ciudadela.sectores.map((s) => (
        <rect key={s.id}
          x={s.id === 'B' || s.id === 'D' ? 51 : 6}
          y={s.id === 'C' || s.id === 'D' ? 51 : 6}
          width="43" height="43" rx="4"
          fill={RIESGO_COLOR[s.riesgo]} fillOpacity=".12" />
      ))}

      {/* letra del sector */}
      {ciudadela.sectores.map((s) => {
        const [x, y] = LETRA[s.id];
        return (
          <text key={s.id} x={x} y={y}
            fill={RIESGO_COLOR[s.riesgo]} fontSize="9" fontWeight="800"
            textAnchor={x > 50 ? 'end' : 'start'}>{s.id}</text>
        );
      })}

      {/* traza del barrido de cada dron */}
      {plan.map((p) => (
        <path key={`ruta-${p.id}`} d={p.ruta} fill="none"
          stroke="rgba(255,255,255,.13)" strokeWidth="0.7" strokeDasharray="2 2.5" />
      ))}

      {/* base de despegue */}
      <circle cx="50" cy="50" r="3.4" fill="none" stroke="rgba(255,255,255,.45)" strokeWidth="1" />
      <circle cx="50" cy="50" r="1.3" fill="rgba(255,255,255,.6)" />

      {plan.map((p) => {
        const motion = (extra) => (
          <animateMotion
            dur={`${p.dur}s`} begin={`${p.inicio}s`} repeatCount="indefinite"
            path={p.ruta} calcMode="linear" keyPoints={keyPoints} keyTimes={keyTimes}
            {...extra}
          />
        );
        return (
          <g key={p.id} className="croquis-dron">
            <title>{p.nombre} · sector {p.sector}</title>

            {/* el ícono gira hacia el sentido de vuelo */}
            <g>
              {motion({ rotate: 'auto' })}
              {/* el dibujo apunta al norte; +90° lo alinea con el eje de avance */}
              <g transform="rotate(90) translate(-5,-5) scale(0.4167)"
                dangerouslySetInnerHTML={{ __html: DRON_SVG_INTERNO }} />
            </g>

            {/* el rótulo viaja con el dron pero se mantiene horizontal */}
            <g>
              {motion()}
              <text className="croquis-rotulo" x="0" y="-7" textAnchor="middle">{p.codigo}</text>
            </g>
          </g>
        );
      })}

      {enBase > 0 && (
        <text x="50" y="62" fill="rgba(255,255,255,.5)" fontSize="7" textAnchor="middle">
          {enBase} en base
        </text>
      )}
    </svg>
  );
}
