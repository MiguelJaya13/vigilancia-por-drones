import { useNavigate } from 'react-router-dom';
import { CIUDADELAS, RIESGO_COLOR } from '../data/ciudadelas.js';
import { grabacionesDe, hoyISO, resumenDia } from '../data/bitacora.js';
import BarraSuperior from '../components/BarraSuperior.jsx';
import { IcoMapa, IcoCalendario, IcoCamara, IcoDer } from '../components/Icons.jsx';
import '../styles/ciudadelas.css';

function FilaCiudadela({ cd, resumen }) {
  const nav = useNavigate();
  const enVuelo = cd.drones.filter((d) => d.estado === 'En vuelo' || d.estado === 'Retornando').length;
  const abrir = () => nav(`/monitoreo/${cd.id}`);

  return (
    <article className="cd-fila" onClick={abrir} role="button" tabIndex={0}
      onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && abrir()}>

      <span className="cdf-codigo">{cd.codigo}</span>

      <div className="cdf-id">
        <b>{cd.nombre}</b>
        <span className="label">{cd.direccion}</span>
      </div>

      <div className="cdf-sectores">
        <span className="label">Sectores</span>
        <div>
          {cd.sectores.map((s) => (
            <span key={s.id} className="cdf-sec" style={{ background: RIESGO_COLOR[s.riesgo] }}
              title={`${s.nombre} · riesgo ${s.riesgo}`}>{s.id}</span>
          ))}
        </div>
      </div>

      <div className="cdf-datos">
        <div className="cdf-dato">
          <b className="mono">{enVuelo}<em>/{cd.drones.length}</em></b>
          <span className="label">Drones</span>
        </div>
        <div className="cdf-dato">
          <b className="mono">{cd.viviendas}</b>
          <span className="label">Viviendas</span>
        </div>
        <div className={'cdf-dato' + (resumen.alertas ? ' alerta' : '')}>
          <b className="mono">{resumen.alertas}</b>
          <span className="label">Alertas hoy</span>
        </div>
      </div>

      <span className="chip cdf-estado">
        <span className={'dot ' + (enVuelo ? 'ok pulse' : 'idle')} />
        {enVuelo ? 'Operativa' : 'En base'}
      </span>

      <div className="cdf-acciones">
        <button className="btn primary" onClick={(e) => { e.stopPropagation(); abrir(); }}>
          <IcoMapa width={14} height={14} /> Monitorear
        </button>
        <button className="btn" onClick={(e) => { e.stopPropagation(); nav(`/camaras/${cd.id}`); }}>
          <IcoCamara width={14} height={14} /> Cámaras
        </button>
        <button className="btn" onClick={(e) => { e.stopPropagation(); nav(`/bitacora/${cd.id}`); }}>
          <IcoCalendario width={14} height={14} /> Bitácora
        </button>
        <IcoDer width={17} height={17} className="cdf-flecha" />
      </div>
    </article>
  );
}

export default function Ciudadelas() {
  const hoy = hoyISO();
  const filas = CIUDADELAS.map((cd) => ({ cd, resumen: resumenDia(grabacionesDe(cd.id, hoy)) }));

  const totales = filas.reduce((acc, { cd, resumen }) => {
    acc.drones += cd.drones.length;
    acc.enVuelo += cd.drones.filter((d) => d.estado === 'En vuelo' || d.estado === 'Retornando').length;
    acc.alertas += resumen.alertas;
    acc.criticas += resumen.criticas;
    acc.viviendas += cd.viviendas;
    acc.horas += +resumen.horas;
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

        <section className="panel cd-lista">
          <header className="cdl-head">
            <b>Ciudadelas monitoreadas</b>
            <span className="label">Elige una para abrir su pantalla de monitoreo</span>
          </header>
          {filas.map(({ cd, resumen }) => (
            <FilaCiudadela key={cd.id} cd={cd} resumen={resumen} />
          ))}
        </section>
      </main>
    </div>
  );
}
