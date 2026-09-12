import { Link, useNavigate } from 'react-router-dom';
import { CIUDADELAS } from '../data/ciudadelas.js';
import { IcoCampana, IcoAjustes, IcoUsuario, IcoGrilla, IcoCalendario, IcoEscudo, IcoCamara } from './Icons.jsx';

export default function BarraSuperior({ ciudadelaId, alertas = 0 }) {
  const nav = useNavigate();
  // En la vista general no hay ciudadela activa: la bitácora abre en la primera.
  const destinoBitacora = ciudadelaId || CIUDADELAS[0].id;

  return (
    <header className="panel barra-sup">
      <Link to="/" className="marca">
        <span className="marca-logo"><IcoEscudo width={17} height={17} /></span>
        <span className="marca-txt">FALCOM<b>360</b></span>
      </Link>

      <nav className="cd-switch">
        {CIUDADELAS.map((c) => (
          <button
            key={c.id}
            className={'cds-btn' + (c.id === ciudadelaId ? ' on' : '')}
            onClick={() => nav(`/monitoreo/${c.id}`)}
            title={c.nombre}
          >
            {c.codigo}
          </button>
        ))}
      </nav>

      <div className="barra-acc">
        <Link to="/" className="btn sm"><IcoGrilla width={14} height={14} /> Ciudadelas</Link>
        <Link to={`/camaras/${destinoBitacora}`} className="btn sm">
          <IcoCamara width={14} height={14} /> Cámaras
        </Link>
        <Link to={`/bitacora/${destinoBitacora}`} className="btn sm">
          <IcoCalendario width={14} height={14} /> Bitácora
        </Link>
        <button className="icon-btn" title="Alertas">
          <IcoCampana width={16} height={16} />
          {alertas > 0 && <span className="badge">{alertas}</span>}
        </button>
        <button className="icon-btn" title="Configuración"><IcoAjustes width={16} height={16} /></button>
        <span className="usuario">
          <IcoUsuario width={15} height={15} />
          <span>Central de Monitoreo</span>
        </span>
      </div>
    </header>
  );
}
