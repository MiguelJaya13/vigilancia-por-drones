import { RIESGO_COLOR } from '../data/ciudadelas.js';

// Croquis cuadrado de la ciudadela: el recinto, sus cuatro sectores y un
// punto rojo por dron recorriendo su ruta de patrullaje.
// El viewBox es cuadrado y la caja también, así nada se deforma.

// Recorrido de patrullaje dentro de cada cuadrante (coordenadas del viewBox).
const RUTAS = {
  A: 'M 15,15 H 41 V 41 H 15 Z',
  B: 'M 59,15 H 85 V 41 H 59 Z',
  C: 'M 15,59 H 41 V 85 H 15 Z',
  D: 'M 59,59 H 85 V 85 H 59 Z',
};

const LETRA = { A: [10, 15], B: [90, 15], C: [10, 93], D: [90, 93] };
const EN_VUELO = new Set(['En vuelo', 'Retornando']);

export default function CroquisCiudadela({ ciudadela, tamano = 76 }) {
  const enVuelo = ciudadela.drones.filter((d) => EN_VUELO.has(d.estado));
  const enBase = ciudadela.drones.length - enVuelo.length;

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
      {ciudadela.sectores.map((s) => {
        const x = s.id === 'B' || s.id === 'D' ? 51 : 6;
        const y = s.id === 'C' || s.id === 'D' ? 51 : 6;
        return (
          <rect key={s.id} x={x} y={y} width="43" height="43" rx="4"
            fill={RIESGO_COLOR[s.riesgo]} fillOpacity=".12" />
        );
      })}

      {/* letra del sector */}
      {ciudadela.sectores.map((s) => {
        const [x, y] = LETRA[s.id];
        return (
          <text key={s.id} x={x} y={y}
            fill={RIESGO_COLOR[s.riesgo]} fontSize="9" fontWeight="800"
            textAnchor={x > 50 ? 'end' : 'start'}>{s.id}</text>
        );
      })}

      {/* rutas de patrullaje */}
      {[...new Set(enVuelo.map((d) => d.sector))].map((sec) => (
        <path key={sec} d={RUTAS[sec]} fill="none"
          stroke="rgba(255,255,255,.16)" strokeWidth="0.8" strokeDasharray="2 2.5" />
      ))}

      {/* drones: punto rojo recorriendo la ruta */}
      {enVuelo.map((d, i) => (
        <g key={d.id}>
          <circle r="5.2" fill="#ef4444" opacity=".22">
            <animateMotion dur={`${11 + (i % 4) * 2.5}s`} repeatCount="indefinite"
              path={RUTAS[d.sector]} begin={`${i * -2.4}s`} rotate="auto" />
            <animate attributeName="r" values="4;7;4" dur="1.8s" repeatCount="indefinite" />
          </circle>
          <circle r="2.9" fill="#ef4444" stroke="#1a0505" strokeWidth="0.7">
            <animateMotion dur={`${11 + (i % 4) * 2.5}s`} repeatCount="indefinite"
              path={RUTAS[d.sector]} begin={`${i * -2.4}s`} rotate="auto" />
          </circle>
        </g>
      ))}

      {/* base de despegue */}
      <circle cx="50" cy="50" r="3.4" fill="none" stroke="rgba(255,255,255,.45)" strokeWidth="1" />
      <circle cx="50" cy="50" r="1.3" fill="rgba(255,255,255,.6)" />
      {enBase > 0 && (
        <text x="50" y="62" fill="rgba(255,255,255,.5)" fontSize="7" textAnchor="middle">
          {enBase} en base
        </text>
      )}
    </svg>
  );
}
