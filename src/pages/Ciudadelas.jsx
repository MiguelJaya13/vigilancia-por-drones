import { Link } from 'react-router-dom';
import { CIUDADELAS, RIESGO_COLOR } from '../data/ciudadelas.js';
import { grabacionesDe, hoyISO, resumenDia } from '../data/bitacora.js';
import BarraSuperior from '../components/BarraSuperior.jsx';
import { IcoDron, IcoCamara, IcoInicio, IcoAlerta, IcoMapa, IcoCalendario } from '../components/Icons.jsx';
import '../styles/ciudadelas.css';

function TarjetaCiudadela({ cd }) {
  const hoy = hoyISO();
  const r = resumenDia(grabacionesDe(cd.id, hoy));
  const enVuelo = cd.drones.filter((d) => d.estado === 'En vuelo' || d.estado === 'Retornando').length;

  return (
    <article className="panel cd-card">
      <header className="cdc-head">
        <span className="cdc-codigo">{cd.codigo}</span>
        <div className="cdc-titulo">
          <b>{cd.nombre}</b>
          <span className="label">{cd.direccion}</span>
        </div>
        <span className="chip">
          <span className={'dot ' + (enVuelo ? 'ok pulse' : 'idle')} />
          {enVuelo ? 'Operativa' : 'En base'}
        </span>
      </header>

      <div className="cdc-mapa">
        <svg viewBox="0 0 200 120" preserveAspectRatio="none" aria-hidden="true">
          <rect x="2" y="2" width="196" height="116" rx="6" fill="rgba(34,211,238,.05)" stroke="rgba(34,211,238,.35)" strokeDasharray="4 3" />
          {cd.sectores.map((s, i) => {
            const x = 10 + (i % 2) * 94;
            const y = 10 + Math.floor(i / 2) * 51;
            return (
              <g key={s.id}>
                <rect x={x} y={y} width="86" height="43" rx="4"
                  fill={RIESGO_COLOR[s.riesgo]} fillOpacity=".16"
                  stroke={RIESGO_COLOR[s.riesgo]} strokeOpacity=".7" />
                <text x={x + 8} y={y + 18} fill={RIESGO_COLOR[s.riesgo]} fontSize="13" fontWeight="800">{s.id}</text>
                <text x={x + 8} y={y + 32} fill="rgba(255,255,255,.65)" fontSize="7.5">{s.nombre}</text>
              </g>
            );
          })}
          {cd.drones.slice(0, 5).map((d, i) => (
            <circle key={d.id} r="3.2" fill="#22d3ee" stroke="#04141a" strokeWidth="1"
              cx={26 + (i % 2) * 94 + (i * 11) % 60} cy={26 + Math.floor(i / 2) * 51}>
              <animate attributeName="opacity" values="1;.35;1" dur="2.4s" begin={`${i * 0.4}s`} repeatCount="indefinite" />
            </circle>
          ))}
        </svg>
      </div>

      <div className="cdc-stats">
        <div><IcoDron width={14} height={14} /><b className="mono">{enVuelo}/{cd.drones.length}</b><span className="label">Drones</span></div>
        <div><IcoCamara width={14} height={14} /><b className="mono">{cd.camaras}</b><span className="label">Cámaras</span></div>
        <div><IcoInicio width={14} height={14} /><b className="mono">{cd.viviendas}</b><span className="label">Viviendas</span></div>
        <div className={r.criticas ? 'alerta' : ''}>
          <IcoAlerta width={14} height={14} /><b className="mono">{r.alertas}</b><span className="label">Alertas hoy</span>
        </div>
      </div>

      <footer className="cdc-pie">
        <Link className="btn primary" to={`/monitoreo/${cd.id}`}>
          <IcoMapa width={14} height={14} /> Monitorear
        </Link>
        <Link className="btn" to={`/bitacora/${cd.id}`}>
          <IcoCalendario width={14} height={14} /> Bitácora
        </Link>
        <span className="label cdc-horas">{r.horas} h grabadas hoy</span>
      </footer>
    </article>
  );
}

export default function Ciudadelas() {
  const hoy = hoyISO();
  const totales = CIUDADELAS.reduce((acc, cd) => {
    const r = resumenDia(grabacionesDe(cd.id, hoy));
    acc.drones += cd.drones.length;
    acc.enVuelo += cd.drones.filter((d) => d.estado === 'En vuelo' || d.estado === 'Retornando').length;
    acc.alertas += r.alertas;
    acc.criticas += r.criticas;
    acc.viviendas += cd.viviendas;
    acc.horas += +r.horas;
    return acc;
  }, { drones: 0, enVuelo: 0, alertas: 0, criticas: 0, viviendas: 0, horas: 0 });

  return (
    <div className="pagina">
      <BarraSuperior ciudadelaId={null} alertas={totales.criticas} />

      <main className="cd-main scroll">
        <section className="cd-intro">
          <h1>Centro de operaciones</h1>
          <p>Vigilancia aérea autónoma sobre {CIUDADELAS.length} ciudadelas · Vía a Samborondón</p>
        </section>

        <section className="cd-kpis">
          {[
            ['Drones en vuelo', `${totales.enVuelo}/${totales.drones}`, 'ok'],
            ['Viviendas cubiertas', totales.viviendas, ''],
            ['Alertas del día', totales.alertas, 'warn'],
            ['Eventos críticos', totales.criticas, 'bad'],
            ['Horas grabadas hoy', totales.horas.toFixed(1), ''],
          ].map(([txt, val, tono]) => (
            <div key={txt} className={'panel kpi ' + tono}>
              <b className="mono">{val}</b>
              <span className="label">{txt}</span>
            </div>
          ))}
        </section>

        <section className="cd-grid">
          {CIUDADELAS.map((cd) => <TarjetaCiudadela key={cd.id} cd={cd} />)}
        </section>
      </main>
    </div>
  );
}
