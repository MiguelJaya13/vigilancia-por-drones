import { useState } from 'react';
import { IcoAterrizar, IcoRTH, IcoPlay, IcoPausa } from './Icons.jsx';

/** Joystick visual: el pomo sigue al puntero mientras se arrastra. */
function Joystick({ etiqueta, ejes }) {
  const [pos, setPos] = useState({ x: 0, y: 0 });

  const mover = (e) => {
    if (e.buttons !== 1) return;
    const r = e.currentTarget.getBoundingClientRect();
    const dx = e.clientX - (r.left + r.width / 2);
    const dy = e.clientY - (r.top + r.height / 2);
    const max = r.width / 2 - 16;
    const d = Math.min(Math.hypot(dx, dy), max);
    const a = Math.atan2(dy, dx);
    setPos({ x: Math.cos(a) * d, y: Math.sin(a) * d });
  };

  return (
    <div className="joy-wrap">
      <div
        className="joy"
        onPointerMove={mover}
        onPointerDown={mover}
        onPointerUp={() => setPos({ x: 0, y: 0 })}
        onPointerLeave={() => setPos({ x: 0, y: 0 })}
      >
        <span className="joy-eje joy-v" />
        <span className="joy-eje joy-h" />
        <span className="joy-pomo" style={{ transform: `translate(${pos.x}px, ${pos.y}px)` }} />
      </div>
      <span className="label">{etiqueta}</span>
      <span className="joy-ejes label">{ejes}</span>
    </div>
  );
}

export default function ControlesVuelo({ dron, onAccion, pausado, onTogglePausa }) {
  return (
    <div className="panel controles">
      <Joystick etiqueta="Altitud / Giro" ejes="THR · YAW" />

      <div className="ctrl-centro">
        <button className="btn sm" onClick={onTogglePausa}>
          {pausado ? <IcoPlay width={13} height={13} /> : <IcoPausa width={13} height={13} />}
          {pausado ? 'Reanudar' : 'Pausar'}
        </button>
        <button className="btn sm" onClick={() => onAccion?.('aterrizar')}>
          <IcoAterrizar width={13} height={13} /> Aterrizar
        </button>
        <button className="btn sm danger" onClick={() => onAccion?.('rth')}>
          <IcoRTH width={13} height={13} /> RTH
        </button>
        {dron && <span className="ctrl-dron label">{dron.nombre} · {dron.estado}</span>}
      </div>

      <Joystick etiqueta="Desplazamiento" ejes="PITCH · ROLL" />
    </div>
  );
}
