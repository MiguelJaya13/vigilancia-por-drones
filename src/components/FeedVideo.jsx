import { useMemo, useState } from 'react';
import { IcoCamara, IcoSenal, IcoSatelite } from './Icons.jsx';
import { mosaico, tileURL } from '../utils/tiles.js';

const MODOS = [
  { id: 'rgb', nombre: 'RGB', filtro: 'saturate(1.1) contrast(1.05)' },
  { id: 'ir', nombre: 'IR', filtro: 'grayscale(1) invert(1) contrast(1.5) brightness(0.9)' },
  { id: 'termica', nombre: 'Térmica', filtro: 'grayscale(1) contrast(1.6) sepia(1) hue-rotate(160deg) saturate(6)' },
];

export default function FeedVideo({ dron, ciudadela }) {
  const [modo, setModo] = useState('rgb');
  const [gimbal, setGimbal] = useState(-60);

  const { tiles, offX, offY } = useMemo(
    () => mosaico(dron?.posicion || ciudadela.centro),
    [dron?.posicion?.[0], dron?.posicion?.[1], ciudadela.id],
  );

  const filtro = MODOS.find((m) => m.id === modo).filtro;
  const sinSenal = !dron || dron.estado === 'En base';

  return (
    <div className="panel feed">
      <header className="feed-head">
        <span className="feed-rec"><span className="dot bad pulse" /> REC</span>
        <b className="feed-titulo">{dron ? dron.nombre : 'Sin dron'}</b>
        <span className="label">{dron ? `Sector ${dron.sector}` : '—'}</span>
      </header>

      <div className="feed-video">
        {sinSenal ? (
          <div className="feed-off"><IcoCamara width={22} height={22} /><span>Cámara en base</span></div>
        ) : (
          <div
            className="feed-lienzo"
            style={{ filter: filtro, transform: `translate(${-offX}%, ${-offY}%) scale(${1 + (gimbal + 90) / 260})` }}
          >
            {tiles.map(([tx, ty]) => (
              <img key={`${tx}-${ty}`} src={tileURL(tx, ty)} alt="" draggable="false" loading="lazy" />
            ))}
          </div>
        )}

        <div className="feed-hud">
          <span className="fh-tl mono">{ciudadela.codigo} · {modo.toUpperCase()}</span>
          <span className="fh-tr mono">{new Date().toLocaleTimeString('es-EC', { hour12: false })}</span>
          <span className="fh-bl mono">
            {dron ? `${dron.posicion[1].toFixed(5)}, ${dron.posicion[0].toFixed(5)}` : '—'}
          </span>
          <span className="fh-br mono">GIM {gimbal}°</span>
          <svg className="fh-mira" viewBox="0 0 100 100" aria-hidden="true">
            <path d="M50 34v-9M50 75v-9M34 50h-9M75 50h-9" stroke="rgba(255,255,255,.75)" strokeWidth="1.4" />
            <rect x="34" y="34" width="32" height="32" fill="none" stroke="rgba(34,211,238,.7)" strokeWidth="1.2" />
          </svg>
          <div className="fh-scan" />
        </div>
      </div>

      <div className="feed-ctrl">
        <div className="feed-modos">
          {MODOS.map((m) => (
            <button
              key={m.id}
              className={'fm-btn' + (modo === m.id ? ' on' : '')}
              onClick={() => setModo(m.id)}
            >{m.nombre}</button>
          ))}
        </div>
        <label className="feed-gimbal">
          <span className="label">Gimbal</span>
          <input
            type="range" min="-90" max="0" value={gimbal}
            onChange={(e) => setGimbal(+e.target.value)}
          />
        </label>
      </div>

      {dron && (
        <footer className="feed-pie">
          <span className="mono"><IcoSenal width={12} height={12} /> {dron.senal}%</span>
          <span className="mono"><IcoSatelite width={12} height={12} /> {dron.satelites}</span>
          <span className="mono">{dron.modelo}</span>
        </footer>
      )}
    </div>
  );
}
