import { useState } from 'react';
import { IcoAlerta, IcoX } from './Icons.jsx';

const COLOR = { info: 'var(--accent)', alerta: 'var(--warn)', critico: 'var(--bad)' };

export default function RegistroActividad({ registro }) {
  const [abierto, setAbierto] = useState(false);
  const ultimo = registro[0];
  const alertas = registro.filter((e) => e.tipo !== 'info').length;

  return (
    <div className={'registro' + (abierto ? ' abierto' : '')}>
      <div className="panel reg-barra">
        <span className="label">Registro de actividad</span>
        {ultimo && (
          <span className="reg-ultimo">
            <span className="dot pulse" style={{ background: COLOR[ultimo.tipo] }} />
            <b className="mono">{ultimo.hora}</b>
            <span className="reg-txt">{ultimo.dron} — {ultimo.texto}</span>
          </span>
        )}
        {alertas > 0 && (
          <span className="reg-badge"><IcoAlerta width={12} height={12} /> {alertas}</span>
        )}
        <button className="btn sm" onClick={() => setAbierto((v) => !v)}>
          {abierto ? 'Cerrar' : 'Ver todo'}
        </button>
      </div>

      {abierto && (
        <div className="panel reg-lista scroll">
          <header className="reg-head">
            <b>Eventos de la sesión</b>
            <button className="btn sm" onClick={() => setAbierto(false)}><IcoX width={13} height={13} /></button>
          </header>
          {registro.map((e) => (
            <div key={e.id} className="reg-item">
              <span className="dot" style={{ background: COLOR[e.tipo] }} />
              <b className="mono reg-hora">{e.hora}</b>
              <div className="reg-cuerpo">
                <span>{e.texto}</span>
                <span className="label">{e.dron} · Sector {e.sector}</span>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
