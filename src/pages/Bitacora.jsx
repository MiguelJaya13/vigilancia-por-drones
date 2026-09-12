import { useEffect, useMemo, useRef, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import { CIUDADELAS, getCiudadela, RIESGO_COLOR } from '../data/ciudadelas.js';
import {
  TIPOS_EVENTO, getTipo, grabacionesDe, resumenDia,
  hoyISO, formatoFechaLarga, duracionTexto,
} from '../data/bitacora.js';
import BarraSuperior from '../components/BarraSuperior.jsx';
import Calendario from '../components/Calendario.jsx';
import ReproductorGrabacion from '../components/ReproductorGrabacion.jsx';
import { IcoDescarga, IcoFiltro, IcoReloj, IcoAlerta, IcoVideo } from '../components/Icons.jsx';
import '../styles/bitacora.css';

export default function Bitacora() {
  const { cdId } = useParams();
  const nav = useNavigate();
  const ciudadela = getCiudadela(cdId);

  const [fecha, setFecha] = useState(hoyISO());
  const [sector, setSector] = useState('todos');
  const [tipos, setTipos] = useState(() => new Set(TIPOS_EVENTO.map((t) => t.id)));
  const [seleccion, setSeleccion] = useState(null);
  const listaRef = useRef(null);

  const delDia = useMemo(() => grabacionesDe(ciudadela.id, fecha), [ciudadela.id, fecha]);

  const filtradas = useMemo(() => delDia.filter((g) =>
    (sector === 'todos' || g.sectorId === sector) && tipos.has(g.tipo)), [delDia, sector, tipos]);

  const resumen = useMemo(() => resumenDia(filtradas), [filtradas]);

  // Al cambiar los filtros, selecciona la primera grabación disponible.
  useEffect(() => {
    setSeleccion(filtradas[0] || null);
    listaRef.current?.scrollTo({ top: 0 });
  }, [ciudadela.id, fecha, sector, tipos]);

  const toggleTipo = (id) => setTipos((prev) => {
    const s = new Set(prev);
    if (s.has(id)) { if (s.size > 1) s.delete(id); } else s.add(id);
    return s;
  });

  const exportar = () => {
    const cab = 'fecha,hora,duracion_seg,ciudadela,sector,dron,tipo,detalle,resolucion,peso_mb,revisado';
    const filas = filtradas.map((g) => [
      g.fecha, g.hora, g.duracion, ciudadela.codigo, `${g.sectorId} - ${g.sectorNombre}`,
      g.dronNombre, getTipo(g.tipo).nombre, `"${g.detalle}"`, g.resolucion, g.pesoMB, g.revisado ? 'si' : 'no',
    ].join(','));
    const blob = new Blob([[cab, ...filas].join('\n')], { type: 'text/csv;charset=utf-8' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `bitacora_${ciudadela.codigo}_${fecha}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
  };

  return (
    <div className="pagina bitacora">
      <BarraSuperior ciudadelaId={ciudadela.id} alertas={resumen.criticas} />

      <div className="bit-cuerpo">
        {/* ---------- columna de filtros ---------- */}
        <aside className="panel bit-filtros scroll">
          <header className="bit-head">
            <h1>Bitácora</h1>
            <p className="label">Grabaciones por día y sector</p>
          </header>

          <div className="bf-bloque">
            <span className="label">Ciudadela</span>
            <select
              className="field" value={ciudadela.id}
              onChange={(e) => nav(`/bitacora/${e.target.value}`)}
            >
              {CIUDADELAS.map((c) => (
                <option key={c.id} value={c.id}>{c.codigo} · {c.nombre}</option>
              ))}
            </select>
          </div>

          <div className="bf-bloque">
            <span className="label">Día</span>
            <Calendario
              valor={fecha}
              onCambio={setFecha}
              intensidad={(iso) => grabacionesDe(ciudadela.id, iso).filter((g) => g.tipo !== 'patrullaje').length}
            />
          </div>

          <div className="bf-bloque">
            <span className="label">Sector</span>
            <div className="bf-sectores">
              <button
                className={'bfs-btn' + (sector === 'todos' ? ' on' : '')}
                onClick={() => setSector('todos')}
              >Todos</button>
              {ciudadela.sectores.map((s) => (
                <button
                  key={s.id}
                  className={'bfs-btn' + (sector === s.id ? ' on' : '')}
                  onClick={() => setSector(s.id)}
                  style={{ '--c': RIESGO_COLOR[s.riesgo] }}
                >
                  <span className="bfs-badge">{s.id}</span> {s.nombre}
                </button>
              ))}
            </div>
          </div>

          <div className="bf-bloque">
            <span className="label"><IcoFiltro width={12} height={12} /> Tipo de evento</span>
            {TIPOS_EVENTO.map((t) => (
              <label key={t.id} className="bf-tipo">
                <input type="checkbox" checked={tipos.has(t.id)} onChange={() => toggleTipo(t.id)} />
                <span className="dot" style={{ background: t.color }} />
                <span>{t.nombre}</span>
                <b className="mono">{delDia.filter((g) => g.tipo === t.id).length}</b>
              </label>
            ))}
          </div>

          <button className="btn bf-export" onClick={exportar}>
            <IcoDescarga width={14} height={14} /> Exportar CSV
          </button>
        </aside>

        {/* ---------- columna principal ---------- */}
        <main className="bit-main scroll">
          <header className="bit-titulo">
            <div>
              <h2>{formatoFechaLarga(fecha)}</h2>
              <p className="label">
                {ciudadela.codigo} · {ciudadela.nombre} ·{' '}
                {sector === 'todos' ? 'todos los sectores' : `Sector ${sector}`}
              </p>
            </div>
            <div className="bit-stats">
              <span className="chip"><IcoVideo width={13} height={13} /> {resumen.segmentos} segmentos</span>
              <span className="chip"><IcoReloj width={13} height={13} /> {resumen.horas} h</span>
              <span className="chip" style={{ color: resumen.alertas ? 'var(--warn)' : undefined }}>
                <IcoAlerta width={13} height={13} /> {resumen.alertas} alertas
              </span>
              <span className="chip">{resumen.almacenamiento} GB</span>
            </div>
          </header>

          <ReproductorGrabacion
            grabacion={seleccion}
            ciudadela={ciudadela}
            onSiguiente={() => {
              const i = filtradas.findIndex((g) => g.id === seleccion?.id);
              if (i >= 0 && i < filtradas.length - 1) setSeleccion(filtradas[i + 1]);
            }}
            onAnterior={() => {
              const i = filtradas.findIndex((g) => g.id === seleccion?.id);
              if (i > 0) setSeleccion(filtradas[i - 1]);
            }}
          />

          <LineaTiempo
            grabaciones={filtradas}
            seleccion={seleccion}
            onSeleccionar={setSeleccion}
          />

          <section className="panel bit-lista-wrap">
            <header className="bl-head">
              <b>Grabaciones del día</b>
              <span className="label">{filtradas.length} resultado{filtradas.length === 1 ? '' : 's'} · {resumen.pendientes} sin revisar</span>
            </header>

            <div className="bl-tabla" ref={listaRef}>
              <div className="bl-fila bl-cab label">
                <span>Hora</span><span>Sector</span><span>Dron</span>
                <span>Evento</span><span>Duración</span><span>Video</span><span />
              </div>

              {filtradas.map((g) => {
                const t = getTipo(g.tipo);
                return (
                  <button
                    key={g.id}
                    className={'bl-fila bl-item' + (seleccion?.id === g.id ? ' on' : '')}
                    onClick={() => setSeleccion(g)}
                  >
                    <span className="mono bl-hora">{g.hora}</span>
                    <span className="bl-sector"><b>{g.sectorId}</b> {g.sectorNombre}</span>
                    <span className="bl-dron">{g.dronNombre}</span>
                    <span className="bl-evento">
                      <span className="dot" style={{ background: t.color }} />
                      <span>
                        <b>{t.nombre}</b>
                        <em>{g.detalle}</em>
                      </span>
                    </span>
                    <span className="mono">{duracionTexto(g.duracion)}</span>
                    <span className="mono bl-video">{g.resolucion}</span>
                    <span className={'bl-estado' + (g.revisado ? ' ok' : '')}>
                      {g.revisado ? 'Revisado' : 'Pendiente'}
                    </span>
                  </button>
                );
              })}

              {!filtradas.length && (
                <p className="bl-vacio">No hay grabaciones con los filtros seleccionados.</p>
              )}
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}

/** Línea de tiempo de 24 h con un marcador por grabación. */
function LineaTiempo({ grabaciones, seleccion, onSeleccionar }) {
  return (
    <section className="panel linea-tiempo">
      <header className="lt-head">
        <span className="label">Línea de tiempo · 24 h</span>
        <div className="lt-leyenda">
          {TIPOS_EVENTO.map((t) => (
            <span key={t.id} className="lt-leg">
              <span className="dot" style={{ background: t.color }} />{t.nombre}
            </span>
          ))}
        </div>
      </header>

      <div className="lt-pista">
        {Array.from({ length: 25 }, (_, h) => (
          <span key={h} className="lt-marca" style={{ left: `${(h / 24) * 100}%` }}>
            {h % 3 === 0 && <em className="mono">{String(h).padStart(2, '0')}</em>}
          </span>
        ))}

        {grabaciones.map((g) => {
          const izq = (g.minutoDia / 1440) * 100;
          const ancho = Math.max(0.45, (g.duracion / 60 / 1440) * 100);
          const t = getTipo(g.tipo);
          return (
            <button
              key={g.id}
              className={'lt-seg' + (seleccion?.id === g.id ? ' on' : '')}
              style={{ left: `${izq}%`, width: `${ancho}%`, background: t.color }}
              title={`${g.hora} · ${t.nombre} · Sector ${g.sectorId}`}
              onClick={() => onSeleccionar(g)}
            />
          );
        })}
      </div>

      <div className="lt-franjas">
        <span>Madrugada</span><span>Mañana</span><span>Tarde</span><span>Noche</span>
      </div>
    </section>
  );
}
