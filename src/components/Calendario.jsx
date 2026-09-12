import { useMemo, useState } from 'react';
import { IcoIzq, IcoDer } from './Icons.jsx';

const DIAS = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
const MESES = ['enero', 'febrero', 'marzo', 'abril', 'mayo', 'junio',
  'julio', 'agosto', 'septiembre', 'octubre', 'noviembre', 'diciembre'];

const iso = (a, m, d) => `${a}-${String(m + 1).padStart(2, '0')}-${String(d).padStart(2, '0')}`;

/**
 * Calendario mensual. `intensidad(iso)` devuelve el número de alertas del día
 * y pinta un indicador bajo la fecha; los días futuros quedan deshabilitados.
 */
export default function Calendario({ valor, onCambio, intensidad }) {
  const [a0, m0] = valor.split('-').map(Number);
  const [vista, setVista] = useState({ anio: a0, mes: m0 - 1 });
  const hoy = new Date();
  const hoyISO = iso(hoy.getFullYear(), hoy.getMonth(), hoy.getDate());

  const celdas = useMemo(() => {
    const primero = new Date(vista.anio, vista.mes, 1);
    const offset = (primero.getDay() + 6) % 7; // semana empieza en lunes
    const total = new Date(vista.anio, vista.mes + 1, 0).getDate();
    const out = Array.from({ length: offset }, () => null);
    for (let d = 1; d <= total; d++) out.push(d);
    return out;
  }, [vista.anio, vista.mes]);

  const mover = (delta) => setVista((v) => {
    const d = new Date(v.anio, v.mes + delta, 1);
    return { anio: d.getFullYear(), mes: d.getMonth() };
  });

  return (
    <div className="cal">
      <header className="cal-head">
        <button className="icon-btn" onClick={() => mover(-1)}><IcoIzq width={15} height={15} /></button>
        <b>{MESES[vista.mes]} {vista.anio}</b>
        <button className="icon-btn" onClick={() => mover(1)}><IcoDer width={15} height={15} /></button>
      </header>

      <div className="cal-grid">
        {DIAS.map((d, i) => <span key={i} className="cal-dow label">{d}</span>)}

        {celdas.map((d, i) => {
          if (!d) return <span key={`v${i}`} />;
          const f = iso(vista.anio, vista.mes, d);
          const futuro = f > hoyISO;
          const alertas = futuro ? 0 : (intensidad?.(f) ?? 0);
          const nivel = alertas > 12 ? 'alta' : alertas > 6 ? 'media' : alertas > 0 ? 'baja' : '';
          return (
            <button
              key={f}
              className={'cal-dia' + (f === valor ? ' on' : '') + (f === hoyISO ? ' hoy' : '')}
              disabled={futuro}
              onClick={() => onCambio(f)}
              title={futuro ? 'Sin registros' : `${alertas} alertas`}
            >
              {d}
              {nivel && <i className={'cal-punto ' + nivel} />}
            </button>
          );
        })}
      </div>

      <footer className="cal-pie">
        <button className="btn sm" onClick={() => { onCambio(hoyISO); setVista({ anio: hoy.getFullYear(), mes: hoy.getMonth() }); }}>
          Hoy
        </button>
        <span className="cal-leyenda label">
          <i className="cal-punto baja" /> baja
          <i className="cal-punto media" /> media
          <i className="cal-punto alta" /> alta
        </span>
      </footer>
    </div>
  );
}
