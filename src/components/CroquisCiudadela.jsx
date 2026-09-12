import { RIESGO_COLOR } from '../data/ciudadelas.js';
import { DRON_SVG_INTERNO } from './IconoDron.jsx';

// Croquis cuadrado de la ciudadela: el recinto, sus cuatro sectores y los
// drones recorriendo la secuencia de patrullaje de la misión.
// El viewBox y la caja son cuadrados, así que nada se deforma.

// Rutas de la demostración, en coordenadas del viewBox (0-100).
const RONDA_PERIMETRAL = 'M 11,11 H 89 V 89 H 11 Z';
const BARRIDO = 'M 15,17 H 85 V 33 H 15 V 50 H 85 V 67 H 15 V 83 H 85';
const DIAGONALES = 'M 15,15 L 85,85 L 85,15 L 15,85 Z';
const CUADRANTE = {
  A: 'M 15,15 H 41 V 41 H 15 Z',
  B: 'M 59,15 H 85 V 41 H 59 Z',
  C: 'M 15,59 H 41 V 85 H 15 Z',
  D: 'M 59,59 H 85 V 85 H 59 Z',
};

// La secuencia: cada dron cumple un rol distinto dentro de la misión.
const SECUENCIA = [
  { ruta: RONDA_PERIMETRAL, dur: 16, etapas: 4 },
  { ruta: BARRIDO, dur: 19, etapas: 8 },
  { ruta: DIAGONALES, dur: 14, etapas: 4 },
];

const LETRA = { A: [10, 15], B: [90, 15], C: [10, 93], D: [90, 93] };
const EN_VUELO = new Set(['En vuelo', 'Retornando']);

/**
 * Avanza y se detiene en cada waypoint, como un vuelo por waypoints real:
 * el 80% de cada tramo desplazándose y el 20% en punto fijo.
 */
function porEtapas(n) {
  const puntos = [], tiempos = [];
  for (let i = 0; i <= n; i++) {
    const p = (i / n).toFixed(4);
    // Llega al waypoint…
    puntos.push(p);
    tiempos.push((i === 0 ? 0 : (i - 0.2) / n).toFixed(4));
    // …y se queda en punto fijo hasta que arranca el tramo siguiente.
    puntos.push(p);
    tiempos.push((i / n).toFixed(4));
  }
  // keyTimes tiene que empezar en 0 y terminar en 1: si no, el navegador
  // descarta la animación completa y el dron se queda en el origen.
  return { keyPoints: puntos.join(';'), keyTimes: tiempos.join(';') };
}

export default function CroquisCiudadela({ ciudadela, tamano = 92 }) {
  const enVuelo = ciudadela.drones.filter((d) => EN_VUELO.has(d.estado));
  const enBase = ciudadela.drones.length - enVuelo.length;

  // Los tres primeros cubren la ciudadela completa; el resto barre su sector.
  const plan = enVuelo.map((d, i) => (
    i < SECUENCIA.length
      ? { ...SECUENCIA[i], id: d.id }
      : { ruta: CUADRANTE[d.sector], dur: 12, etapas: 4, id: d.id }
  ));

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

      {/* trazas de la secuencia */}
      {plan.map((p) => (
        <path key={`ruta-${p.id}`} d={p.ruta} fill="none"
          stroke="rgba(255,255,255,.14)" strokeWidth="0.7" strokeDasharray="2 2.5" />
      ))}

      {/* base de despegue */}
      <circle cx="50" cy="50" r="3.4" fill="none" stroke="rgba(255,255,255,.45)" strokeWidth="1" />
      <circle cx="50" cy="50" r="1.3" fill="rgba(255,255,255,.6)" />

      {/* drones recorriendo su etapa de la misión */}
      {plan.map((p, i) => {
        const { keyPoints, keyTimes } = porEtapas(p.etapas);
        return (
          <g key={p.id} className="croquis-dron">
            <g>
              <animateMotion
                dur={`${p.dur}s`}
                repeatCount="indefinite"
                path={p.ruta}
                rotate="auto"
                calcMode="linear"
                keyPoints={keyPoints}
                keyTimes={keyTimes}
                begin={`${i * -3.1}s`}
              />
              {/* el ícono apunta al norte; +90° lo alinea con el sentido de vuelo */}
              <g transform="rotate(90) translate(-5,-5) scale(0.4167)"
                dangerouslySetInnerHTML={{ __html: DRON_SVG_INTERNO }} />
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
