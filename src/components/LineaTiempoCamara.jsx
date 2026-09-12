import { useRef } from 'react';
import { TIPOS_EVENTO_CAM } from '../data/camaras.js';

/**
 * Línea de tiempo del NVR: franja azul con lo grabado, marcas rojas de
 * evento y cursor arrastrable. Trabaja en minutos del día (0-1440).
 */
export default function LineaTiempoCamara({ grabacion, minuto, onBuscar, onEvento }) {
  const pista = useRef(null);

  const posicionar = (e) => {
    const r = pista.current.getBoundingClientRect();
    const p = Math.min(1, Math.max(0, (e.clientX - r.left) / r.width));
    onBuscar(Math.round(p * 1440));
  };

  const arrastrar = (e) => { if (e.buttons === 1) posicionar(e); };

  return (
    <div className="ltc">
      <div className="ltc-horas">
        {Array.from({ length: 9 }, (_, i) => i * 3).map((h) => (
          <span key={h} className="mono" style={{ left: `${(h / 24) * 100}%` }}>
            {String(h).padStart(2, '0')}:00
          </span>
        ))}
      </div>

      <div className="ltc-pista" ref={pista} onPointerDown={posicionar} onPointerMove={arrastrar}>
        {grabacion.segmentos.map((s, i) => (
          <span
            key={i}
            className="ltc-grabado"
            style={{ left: `${(s.inicio / 1440) * 100}%`, width: `${((s.fin - s.inicio) / 1440) * 100}%` }}
            title={`Grabado ${String(Math.floor(s.inicio / 60)).padStart(2, '0')}:${String(s.inicio % 60).padStart(2, '0')} → ${String(Math.floor(s.fin / 60)).padStart(2, '0')}:${String(s.fin % 60).padStart(2, '0')}`}
          />
        ))}

        {grabacion.eventos.map((e) => {
          const t = TIPOS_EVENTO_CAM[e.tipo];
          return (
            <button
              key={e.id}
              className="ltc-evento"
              style={{ left: `${(e.minuto / 1440) * 100}%`, background: t.color }}
              title={`${t.nombre} · ${String(Math.floor(e.minuto / 60)).padStart(2, '0')}:${String(e.minuto % 60).padStart(2, '0')}`}
              onClick={(ev) => { ev.stopPropagation(); onEvento(e); }}
            />
          );
        })}

        <span className="ltc-cursor" style={{ left: `${(minuto / 1440) * 100}%` }} />
      </div>

      <div className="ltc-leyenda">
        <span className="ltcl"><i className="ltcl-barra" /> Grabado</span>
        {Object.entries(TIPOS_EVENTO_CAM).map(([id, t]) => (
          <span key={id} className="ltcl"><i className="ltcl-marca" style={{ background: t.color }} /> {t.nombre}</span>
        ))}
      </div>
    </div>
  );
}
