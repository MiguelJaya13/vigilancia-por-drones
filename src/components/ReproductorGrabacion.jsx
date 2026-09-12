import { useEffect, useMemo, useRef, useState } from 'react';
import { mosaico, tileURL } from '../utils/tiles.js';
import { getTipo, duracionTexto } from '../data/bitacora.js';
import { IcoPlay, IcoPausa, IcoIzq, IcoDer, IcoDescarga, IcoVideo } from './Icons.jsx';

const VELOCIDADES = [1, 2, 4, 8];

/**
 * Reproductor de la grabación seleccionada. El "video" se compone con
 * imágenes satelitales del sector y una panorámica lenta; en producción
 * aquí iría el <video> con el HLS/MP4 del archivo grabado por el dron.
 */
export default function ReproductorGrabacion({ grabacion, ciudadela, onAnterior, onSiguiente }) {
  const [t, setT] = useState(0);
  const [reproduciendo, setReproduciendo] = useState(false);
  const [vel, setVel] = useState(1);
  const pista = useRef(null);

  const sector = ciudadela.sectores.find((s) => s.id === grabacion?.sectorId) || ciudadela.sectores[0];
  const { tiles, offX, offY } = useMemo(() => mosaico(sector.centro), [sector.centro[0], sector.centro[1]]);

  useEffect(() => { setT(0); setReproduciendo(false); }, [grabacion?.id]);

  useEffect(() => {
    if (!reproduciendo || !grabacion) return undefined;
    const id = setInterval(() => {
      setT((v) => {
        const n = v + vel;
        if (n >= grabacion.duracion) { setReproduciendo(false); return grabacion.duracion; }
        return n;
      });
    }, 1000);
    return () => clearInterval(id);
  }, [reproduciendo, vel, grabacion?.id, grabacion?.duracion]);

  if (!grabacion) {
    return (
      <section className="panel reproductor vacio">
        <IcoVideo width={26} height={26} />
        <p>Selecciona una grabación de la lista o de la línea de tiempo.</p>
      </section>
    );
  }

  const tipo = getTipo(grabacion.tipo);
  const avance = (t / grabacion.duracion) * 100;
  const critico = grabacion.tipo === 'intrusion' || grabacion.tipo === 'perimetro';

  const buscar = (e) => {
    const r = pista.current.getBoundingClientRect();
    const p = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
    setT(Math.round(p * grabacion.duracion));
  };

  // Hora real dentro del segmento, para el timecode del HUD.
  const [hh, mm] = grabacion.hora.split(':').map(Number);
  const seg = hh * 3600 + mm * 60 + t;
  const reloj = [Math.floor(seg / 3600) % 24, Math.floor(seg / 60) % 60, seg % 60]
    .map((n) => String(n).padStart(2, '0')).join(':');

  return (
    <section className="panel reproductor">
      <div className="rep-video">
        <div
          className="rep-lienzo"
          style={{
            transform: `translate(${-offX - 6 + (t / grabacion.duracion) * 12}%, ${-offY - 3}%) scale(1.45)`,
            filter: grabacion.camara.includes('Térmica') && grabacion.tipo !== 'patrullaje'
              ? 'grayscale(1) contrast(1.5) sepia(1) hue-rotate(165deg) saturate(5)'
              : 'saturate(1.08) contrast(1.06)',
          }}
        >
          {tiles.map(([x, y]) => <img key={`${x}-${y}`} src={tileURL(x, y)} alt="" draggable="false" />)}
        </div>

        <div className="rep-hud">
          <span className="rh-tl mono">
            <span className="dot bad pulse" /> {ciudadela.codigo} · SECTOR {grabacion.sectorId}
          </span>
          <span className="rh-tr mono">{grabacion.fecha} {reloj}</span>
          <span className="rh-bl mono">{grabacion.dronNombre} · {grabacion.camara}</span>
          <span className="rh-br mono">{grabacion.resolucion}</span>
          {critico && (
            <span className="rep-alerta" style={{ borderColor: tipo.color, color: tipo.color }}>
              {tipo.nombre.toUpperCase()}
            </span>
          )}
        </div>
      </div>

      <div className="rep-pista" ref={pista} onClick={buscar}>
        <i style={{ width: `${avance}%`, background: tipo.color }} />
        <span className="rep-pomo" style={{ left: `${avance}%` }} />
      </div>

      <div className="rep-ctrl">
        <button className="icon-btn" onClick={onAnterior} title="Anterior"><IcoIzq width={16} height={16} /></button>
        <button className="btn primary rep-play" onClick={() => setReproduciendo((v) => !v)}>
          {reproduciendo ? <IcoPausa width={14} height={14} /> : <IcoPlay width={14} height={14} />}
          {reproduciendo ? 'Pausa' : 'Reproducir'}
        </button>
        <button className="icon-btn" onClick={onSiguiente} title="Siguiente"><IcoDer width={16} height={16} /></button>

        <span className="mono rep-tiempo">{duracionTexto(t)} / {duracionTexto(grabacion.duracion)}</span>

        <div className="rep-vel">
          {VELOCIDADES.map((v) => (
            <button key={v} className={'fm-btn' + (vel === v ? ' on' : '')} onClick={() => setVel(v)}>{v}x</button>
          ))}
        </div>

        <button className="btn sm rep-desc" title="Descargar clip">
          <IcoDescarga width={13} height={13} /> {grabacion.pesoMB} MB
        </button>
      </div>

      <footer className="rep-meta">
        <span className="chip" style={{ color: tipo.color, borderColor: tipo.color + '55' }}>
          <span className="dot" style={{ background: tipo.color }} /> {tipo.nombre}
        </span>
        <span className="rep-detalle">{grabacion.detalle}</span>
        <span className="label">Inicio {grabacion.hora} · Sector {grabacion.sectorId} — {grabacion.sectorNombre}</span>
      </footer>
    </section>
  );
}
