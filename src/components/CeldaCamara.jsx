import { useMemo } from 'react';
import { mosaico, tileURL } from '../utils/tiles.js';
import { selloFecha } from '../data/camaras.js';

/**
 * Un cuadro de cámara: la imagen con la marca de fecha/hora y el nombre
 * quemados encima, igual que el frame que entrega un NVR.
 * En producción el contenido sería un <video> con el stream HLS/WebRTC.
 */
export default function CeldaCamara({
  camara, fecha, segundos, activa, onClick, zoom = 1, nocturna = true, calidad = 'HD',
}) {
  const { tiles, offX, offY } = useMemo(() => mosaico(camara.posicion), [camara.id]);

  // Cada cámara mira hacia un lado distinto: da variedad al mosaico.
  const giro = (camara.id.charCodeAt(camara.id.length - 1) % 4) * 3 - 4.5;

  if (camara.estado === 'offline') {
    return (
      <div className={'celda-cam offline' + (activa ? ' activa' : '')} onClick={onClick}>
        <div className="cc-ruido" />
        <div className="cc-sinsenal">
          <b>SIN SEÑAL</b>
          <span>Verificar alimentación PoE</span>
        </div>
        <span className="cc-nombre">{camara.nombre}</span>
      </div>
    );
  }

  return (
    <div className={'celda-cam' + (activa ? ' activa' : '')} onClick={onClick}>
      <div
        className="cc-lienzo"
        style={{
          transform: `translate(${-offX}%, ${-offY}%) rotate(${giro}deg) scale(${1.7 * zoom})`,
          filter: nocturna
            ? 'brightness(.52) contrast(1.35) saturate(.35)'
            : 'brightness(1.02) contrast(1.1) saturate(.9)',
          imageRendering: calidad === 'SD' ? 'pixelated' : 'auto',
        }}
      >
        {tiles.map(([x, y]) => <img key={`${x}-${y}`} src={tileURL(x, y)} alt="" draggable="false" />)}
      </div>

      <div className="cc-vineta" />
      <span className="cc-sello mono">{selloFecha(fecha, segundos)}</span>
      <span className="cc-nombre">{camara.nombre}</span>
      <span className="cc-marca mono">{camara.id}</span>
      {camara.ir && nocturna && <span className="cc-ir">IR</span>}
    </div>
  );
}
