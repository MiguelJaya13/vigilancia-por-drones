import { useMemo, useState } from 'react';
import { ESTADO_TIPO } from '../data/ciudadelas.js';
import { IcoBuscar, IcoDron, IcoMas, IcoRuta, IcoEscudo, IcoLista } from './Icons.jsx';

const TABS = [
  { id: 'vuelo', nombre: 'Vuelo', Ico: IcoDron },
  { id: 'mision', nombre: 'Misión', Ico: IcoRuta },
  { id: 'checklist', nombre: 'Checklist', Ico: IcoLista },
  { id: 'geocerca', nombre: 'Geocerca', Ico: IcoEscudo },
];

function colorBateria(b) {
  if (b >= 60) return 'var(--ok)';
  if (b >= 25) return 'var(--warn)';
  return 'var(--bad)';
}

function TarjetaDron({ d, activo, onClick }) {
  return (
    <button className={'dron-card' + (activo ? ' activo' : '')} onClick={onClick}>
      <div className="dc-head">
        <span className={'dot ' + (ESTADO_TIPO[d.estado] || 'idle') + (d.estado === 'En vuelo' ? ' pulse' : '')} />
        <span className="dc-nombre">{d.nombre}</span>
        <span className="dc-bateria mono" style={{ color: colorBateria(d.bateria) }}>
          {Math.round(d.bateria)}%
        </span>
      </div>

      <div className="dc-sub">
        <span className="chip-mini">Sector {d.sector}</span>
        <span className="dc-estado">{d.estado}</span>
      </div>

      <div className="dc-metricas">
        <div><b className="mono">{Math.round(d.altitud)} m</b><span className="label">Altitud</span></div>
        <div><b className="mono">{d.velocidad.toFixed(1)} m/s</b><span className="label">Velocidad</span></div>
        <div><b className="mono">{d.distanciaBase} m</b><span className="label">Desde base</span></div>
      </div>

      <div className="bar"><i style={{ width: `${d.bateria}%`, background: colorBateria(d.bateria) }} /></div>
    </button>
  );
}

export default function PanelFlota({ ciudadela, flota, dronActivo, onSeleccionar }) {
  const [tab, setTab] = useState('vuelo');
  const [q, setQ] = useState('');

  const filtrada = useMemo(() => {
    const t = q.trim().toLowerCase();
    if (!t) return flota;
    return flota.filter((d) =>
      d.nombre.toLowerCase().includes(t) || d.id.toLowerCase().includes(t) || d.sector.toLowerCase() === t);
  }, [flota, q]);

  const enVuelo = flota.filter((d) => d.estado === 'En vuelo' || d.estado === 'Retornando').length;

  return (
    <aside className="panel panel-flota">
      <nav className="pf-tabs">
        {TABS.map(({ id, nombre, Ico }) => (
          <button key={id} className={'pf-tab' + (tab === id ? ' on' : '')} onClick={() => setTab(id)}>
            <Ico width={17} height={17} />
            <span>{nombre}</span>
          </button>
        ))}
      </nav>

      <div className="pf-cuerpo">
        {tab === 'vuelo' && (
          <>
            <header className="pf-head">
              <h2>Flota</h2>
              <p className="label">{enVuelo} de {flota.length} en vuelo · {ciudadela.codigo}</p>
            </header>

            <button className="btn primary pf-add"><IcoMas width={15} height={15} /> Añadir dron</button>

            <div className="pf-buscar">
              <IcoBuscar width={14} height={14} />
              <input
                className="field" placeholder="Buscar dron o sector…"
                value={q} onChange={(e) => setQ(e.target.value)}
              />
            </div>

            <p className="label pf-conteo">Drones añadidos: {flota.length}/8</p>

            <div className="pf-lista scroll">
              {filtrada.map((d) => (
                <TarjetaDron
                  key={d.id} d={d}
                  activo={d.id === dronActivo}
                  onClick={() => onSeleccionar(d.id)}
                />
              ))}
              {!filtrada.length && <p className="pf-vacio">Sin resultados para «{q}»</p>}
            </div>
          </>
        )}

        {tab === 'mision' && (
          <div className="pf-simple scroll">
            <header className="pf-head"><h2>Misión activa</h2><p className="label">Patrullaje perimetral</p></header>
            {ciudadela.sectores.map((s, i) => (
              <div key={s.id} className="mision-paso">
                <span className="mp-num mono">{i + 1}</span>
                <div>
                  <b>Sector {s.id} · {s.nombre}</b>
                  <span className="label">Barrido RGB + térmico · 6 waypoints</span>
                </div>
              </div>
            ))}
            <div className="pf-nota">Ciclo completo estimado: <b className="mono">24 min</b></div>
          </div>
        )}

        {tab === 'checklist' && (
          <div className="pf-simple scroll">
            <header className="pf-head"><h2>Checklist pre-vuelo</h2><p className="label">{ciudadela.codigo}</p></header>
            {[
              ['Baterías sobre 80%', true], ['Hélices sin daño', true], ['Enlace RC y video', true],
              ['GPS ≥ 12 satélites', true], ['Clima apto (viento < 8 m/s)', true],
              ['Permiso DGAC vigente', true], ['Tarjeta de grabación con espacio', false],
            ].map(([txt, ok]) => (
              <label key={txt} className="check-item">
                <input type="checkbox" defaultChecked={ok} />
                <span>{txt}</span>
              </label>
            ))}
          </div>
        )}

        {tab === 'geocerca' && (
          <div className="pf-simple scroll">
            <header className="pf-head"><h2>Geocerca</h2><p className="label">Límites operativos</p></header>
            <div className="geo-dato"><span className="label">Radio autorizado</span><b className="mono">{Math.round(ciudadela.geocerca.radio)} m</b></div>
            <div className="geo-dato"><span className="label">Altura máxima</span><b className="mono">120 m AGL</b></div>
            <div className="geo-dato"><span className="label">Retorno automático</span><b className="mono">Batería &lt; 20%</b></div>
            <div className="geo-dato"><span className="label">Cámaras fijas enlazadas</span><b className="mono">{ciudadela.camaras}</b></div>
            <div className="geo-dato"><span className="label">Viviendas cubiertas</span><b className="mono">{ciudadela.viviendas}</b></div>
            <div className="pf-nota">La violación de geocerca dispara alerta inmediata al puesto de guardia.</div>
          </div>
        )}
      </div>
    </aside>
  );
}
