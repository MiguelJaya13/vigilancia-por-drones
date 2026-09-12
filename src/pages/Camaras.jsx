import { useEffect, useMemo, useRef, useState } from 'react';
import { useParams } from 'react-router-dom';
import { getCiudadela, RIESGO_COLOR } from '../data/ciudadelas.js';
import { camarasDe, grabacionCamara, relojDia, TIPOS_EVENTO_CAM } from '../data/camaras.js';
import { hoyISO, formatoFechaLarga } from '../data/bitacora.js';
import BarraSuperior from '../components/BarraSuperior.jsx';
import CeldaCamara from '../components/CeldaCamara.jsx';
import LineaTiempoCamara from '../components/LineaTiempoCamara.jsx';
import {
  IcoBuscar, IcoGrilla, IcoIzq, IcoDer, IcoPlay, IcoPausa, IcoCamara,
  IcoDescarga, IcoAlerta, IcoX,
} from '../components/Icons.jsx';
import '../styles/camaras.css';

const REJILLAS = [1, 4, 9, 16];
const VELOCIDADES = [1, 2, 4, 8, 16];

const minutosDeHoy = () => new Date().getHours() * 60 + new Date().getMinutes();

export default function Camaras() {
  const { cdId } = useParams();
  const ciudadela = getCiudadela(cdId);

  const [fecha, setFecha] = useState(hoyISO());
  const [modo, setModo] = useState('directo');      // directo | reproduccion
  const [seleccionada, setSeleccionada] = useState(null);
  const [rejilla, setRejilla] = useState(4);
  const [pagina, setPagina] = useState(0);
  const [sector, setSector] = useState('todos');
  const [q, setQ] = useState('');

  const [minuto, setMinuto] = useState(0);          // posición en reproducción
  const [reproduciendo, setReproduciendo] = useState(false);
  const [vel, setVel] = useState(1);
  const [mute, setMute] = useState(true);
  const [zoom, setZoom] = useState(1);
  const [calidad, setCalidad] = useState('HD');
  const [aviso, setAviso] = useState(null);
  const avisoRef = useRef(null);

  const esHoy = fecha === hoyISO();
  const camaras = useMemo(() => camarasDe(ciudadela.id), [ciudadela.id]);

  const filtradas = useMemo(() => {
    const t = q.trim().toLowerCase();
    return camaras.filter((c) =>
      (sector === 'todos' || c.sectorId === sector) &&
      (!t || c.nombre.toLowerCase().includes(t) || c.ubicacion.toLowerCase().includes(t) || c.id.toLowerCase().includes(t)));
  }, [camaras, sector, q]);

  const camara = camaras.find((c) => c.id === seleccionada) || null;
  const grabacion = useMemo(
    () => (camara ? grabacionCamara(camara.id, fecha, esHoy) : null),
    [camara?.id, fecha, esHoy],
  );

  // Reloj de la vista en directo.
  const [ahora, setAhora] = useState(() => new Date());
  useEffect(() => {
    const id = setInterval(() => setAhora(new Date()), 1000);
    return () => clearInterval(id);
  }, []);

  // Avance de la reproducción.
  useEffect(() => {
    if (modo !== 'reproduccion' || !reproduciendo) return undefined;
    const id = setInterval(() => {
      setMinuto((m) => {
        const tope = esHoy ? minutosDeHoy() : 1440;
        const n = m + vel / 60;
        if (n >= tope) { setReproduciendo(false); return tope; }
        return n;
      });
    }, 1000);
    return () => clearInterval(id);
  }, [modo, reproduciendo, vel, esHoy]);

  useEffect(() => { setPagina(0); }, [rejilla, sector, q, ciudadela.id]);
  useEffect(() => { setSeleccionada(null); setModo('directo'); }, [ciudadela.id]);

  const mostrarAviso = (texto) => {
    setAviso(texto);
    clearTimeout(avisoRef.current);
    avisoRef.current = setTimeout(() => setAviso(null), 2200);
  };

  const irAModo = (m) => {
    setModo(m);
    if (m === 'reproduccion') {
      setMinuto(esHoy ? Math.max(0, minutosDeHoy() - 30) : 0);
      setReproduciendo(true);
    } else {
      setReproduciendo(false);
    }
  };

  const saltar = (segundos) => {
    setMinuto((m) => Math.min(esHoy ? minutosDeHoy() : 1440, Math.max(0, m + segundos / 60)));
  };

  const cambiarDia = (delta) => {
    const [a, m, d] = fecha.split('-').map(Number);
    const nueva = new Date(a, m - 1, d + delta);
    const iso = `${nueva.getFullYear()}-${String(nueva.getMonth() + 1).padStart(2, '0')}-${String(nueva.getDate()).padStart(2, '0')}`;
    if (iso > hoyISO()) return;
    setFecha(iso);
    setMinuto(0);
  };

  // Segundos del día que se estampan sobre la imagen.
  const segundosSello = modo === 'directo'
    ? ahora.getHours() * 3600 + ahora.getMinutes() * 60 + ahora.getSeconds()
    : minuto * 60;

  const porPagina = rejilla;
  const paginas = Math.max(1, Math.ceil(filtradas.length / porPagina));
  const visibles = filtradas.slice(pagina * porPagina, pagina * porPagina + porPagina);
  const enLinea = camaras.filter((c) => c.estado === 'online').length;

  return (
    <div className="pagina camaras">
      <BarraSuperior ciudadelaId={ciudadela.id} alertas={camaras.length - enLinea} />

      <div className="cam-cuerpo">
        {/* -------- lista lateral de cámaras -------- */}
        <aside className="panel cam-lista">
          <header className="cml-head">
            <h1>Cámaras fijas</h1>
            <p className="label">{enLinea} de {camaras.length} en línea · {ciudadela.codigo}</p>
          </header>

          <div className="cml-buscar">
            <IcoBuscar width={14} height={14} />
            <input className="field" placeholder="Buscar cámara o ubicación…"
              value={q} onChange={(e) => setQ(e.target.value)} />
          </div>

          <div className="cml-sectores">
            <button className={'bfs-btn' + (sector === 'todos' ? ' on' : '')} onClick={() => setSector('todos')}>
              Todos los sectores
            </button>
            {ciudadela.sectores.map((s) => (
              <button key={s.id} className={'bfs-btn' + (sector === s.id ? ' on' : '')}
                onClick={() => setSector(s.id)} style={{ '--c': RIESGO_COLOR[s.riesgo] }}>
                <span className="bfs-badge">{s.id}</span> {s.nombre}
              </button>
            ))}
          </div>

          <div className="cml-items scroll">
            {filtradas.map((c) => (
              <button
                key={c.id}
                className={'cml-item' + (seleccionada === c.id ? ' on' : '')}
                onClick={() => setSeleccionada(c.id)}
              >
                <span className={'dot ' + (c.estado === 'online' ? 'ok' : 'bad')} />
                <span className="cml-txt">
                  <b>{c.nombre}</b>
                  <span className="label">{c.ubicacion} · Sector {c.sectorId}</span>
                </span>
                <span className="cml-tipo">{c.tipo}</span>
              </button>
            ))}
            {!filtradas.length && <p className="pf-vacio">Sin cámaras para ese filtro.</p>}
          </div>
        </aside>

        {/* -------- visor -------- */}
        <main className="cam-visor">
          <div className="panel cam-barra">
            <div className="cb-modos">
              <button className={'fm-btn' + (modo === 'directo' ? ' on' : '')} onClick={() => irAModo('directo')}>
                Vista en directo
              </button>
              <button className={'fm-btn' + (modo === 'reproduccion' ? ' on' : '')} onClick={() => irAModo('reproduccion')}>
                Reproducción
              </button>
            </div>

            {modo === 'reproduccion' && (
              <div className="cb-fecha">
                <button className="icon-btn" onClick={() => cambiarDia(-1)}><IcoIzq width={15} height={15} /></button>
                <b>{esHoy ? 'Hoy' : formatoFechaLarga(fecha).replace(/ de \d{4}$/, '')}</b>
                <button className="icon-btn" onClick={() => cambiarDia(1)} disabled={esHoy}><IcoDer width={15} height={15} /></button>
              </div>
            )}

            {!camara && (
              <div className="cb-rejilla">
                <IcoGrilla width={14} height={14} />
                {REJILLAS.map((n) => (
                  <button key={n} className={'fm-btn' + (rejilla === n ? ' on' : '')} onClick={() => setRejilla(n)}>
                    {n === 1 ? '1' : `${Math.sqrt(n)}×${Math.sqrt(n)}`}
                  </button>
                ))}
              </div>
            )}

            <div className="cb-der">
              {camara ? (
                <button className="btn sm" onClick={() => { setSeleccionada(null); setZoom(1); }}>
                  <IcoGrilla width={13} height={13} /> Volver al mosaico
                </button>
              ) : (
                <>
                  <button className="icon-btn" onClick={() => setPagina((p) => Math.max(0, p - 1))} disabled={pagina === 0}>
                    <IcoIzq width={15} height={15} />
                  </button>
                  <span className="label mono">{pagina + 1}/{paginas}</span>
                  <button className="icon-btn" onClick={() => setPagina((p) => Math.min(paginas - 1, p + 1))} disabled={pagina >= paginas - 1}>
                    <IcoDer width={15} height={15} />
                  </button>
                </>
              )}
            </div>
          </div>

          {/* mosaico */}
          {!camara && (
            <div className={'panel cam-mosaico g' + rejilla}>
              {visibles.map((c) => (
                <CeldaCamara
                  key={c.id} camara={c} fecha={fecha} segundos={segundosSello}
                  calidad={calidad}
                  onClick={() => setSeleccionada(c.id)}
                />
              ))}
              {Array.from({ length: Math.max(0, porPagina - visibles.length) }, (_, i) => (
                <div key={`hueco-${i}`} className="celda-cam vacia"><span>Sin cámara</span></div>
              ))}
            </div>
          )}

          {/* detalle de una cámara */}
          {camara && (
            <>
              <div className="panel cam-detalle">
                <CeldaCamara
                  camara={camara} fecha={fecha} segundos={segundosSello}
                  zoom={zoom} calidad={calidad} activa
                />

                <div className="cd-superpuesto">
                  <span className="cd-vivo">
                    {modo === 'directo'
                      ? <><span className="dot bad pulse" /> EN VIVO</>
                      : <>REPRODUCCIÓN {vel}×</>}
                  </span>
                  <span className="mono cd-bitrate">{camara.bitrate} kb/s · {calidad}</span>
                </div>
              </div>

              <div className="panel cam-controles">
                <button className="btn primary" onClick={() => {
                  if (modo === 'directo') irAModo('reproduccion');
                  else setReproduciendo((v) => !v);
                }}>
                  {modo === 'reproduccion' && reproduciendo
                    ? <><IcoPausa width={14} height={14} /> Pausa</>
                    : <><IcoPlay width={14} height={14} /> Reproducir</>}
                </button>

                {modo === 'reproduccion' && (
                  <>
                    <button className="btn sm" onClick={() => saltar(-10)}>−10 s</button>
                    <span className="mono cd-reloj">{relojDia(minuto * 60)}</span>
                    <button className="btn sm" onClick={() => saltar(10)}>+10 s</button>
                    <div className="rep-vel">
                      {VELOCIDADES.map((v) => (
                        <button key={v} className={'fm-btn' + (vel === v ? ' on' : '')} onClick={() => setVel(v)}>{v}×</button>
                      ))}
                    </div>
                  </>
                )}

                <div className="cd-sep" />

                <button className={'btn sm' + (mute ? '' : ' activo')} onClick={() => setMute((v) => !v)}
                  disabled={!camara.audio} title={camara.audio ? 'Audio' : 'Cámara sin micrófono'}>
                  {mute ? 'Audio off' : 'Audio on'}
                </button>
                <div className="rep-vel">
                  {['HD', 'SD'].map((c) => (
                    <button key={c} className={'fm-btn' + (calidad === c ? ' on' : '')} onClick={() => setCalidad(c)}>{c}</button>
                  ))}
                </div>
                <button className="btn sm" onClick={() => setZoom((z) => Math.min(3, +(z + 0.35).toFixed(2)))}>Zoom +</button>
                <button className="btn sm" onClick={() => setZoom(1)} disabled={zoom === 1}>Reset</button>

                <div className="cd-sep" />

                <button className="btn sm" onClick={() => mostrarAviso(`Captura guardada · ${camara.nombre} ${relojDia(segundosSello)}`)}>
                  <IcoCamara width={13} height={13} /> Captura
                </button>
                <button className="btn sm danger" onClick={() => mostrarAviso(`Grabando clip manual de ${camara.nombre}…`)}>
                  <span className="dot bad" /> Grabar
                </button>
                <button className="btn sm" onClick={() => mostrarAviso(`Descarga en cola · ${camara.id} ${fecha}`)}>
                  <IcoDescarga width={13} height={13} /> Descargar
                </button>
              </div>

              {modo === 'reproduccion' && grabacion && (
                <div className="panel cam-timeline">
                  <header className="ct-head">
                    <span className="label">{camara.nombre} · {camara.ubicacion}</span>
                    <span className="label">
                      {(grabacion.minutosGrabados / 60).toFixed(1)} h grabadas · {grabacion.eventos.length} eventos
                    </span>
                  </header>
                  <LineaTiempoCamara
                    grabacion={grabacion}
                    minuto={minuto}
                    onBuscar={(m) => setMinuto(Math.min(esHoy ? minutosDeHoy() : 1440, m))}
                    onEvento={(e) => { setMinuto(e.minuto); setReproduciendo(true); }}
                  />
                </div>
              )}

              <div className="panel cam-ficha">
                <div><span className="label">Ubicación</span><b>{camara.ubicacion}</b></div>
                <div><span className="label">Sector</span><b>{camara.sectorId} · {camara.sectorNombre}</b></div>
                <div><span className="label">Tipo</span><b>{camara.tipo}{camara.ptz ? ' (con giro)' : ''}</b></div>
                <div><span className="label">Resolución</span><b className="mono">{camara.resolucion}</b></div>
                <div><span className="label">Visión nocturna</span><b>{camara.ir ? 'IR activo' : 'No'}</b></div>
                <div><span className="label">Estado</span>
                  <b style={{ color: camara.estado === 'online' ? 'var(--ok)' : 'var(--bad)' }}>
                    {camara.estado === 'online' ? 'En línea' : 'Sin señal'}
                  </b>
                </div>
              </div>
            </>
          )}
        </main>

        {/* -------- notificaciones -------- */}
        <aside className="panel cam-eventos">
          <header className="ce-head">
            <b><IcoAlerta width={14} height={14} /> Notificaciones</b>
            <span className="label">{esHoy ? 'Hoy' : formatoFechaLarga(fecha)}</span>
          </header>
          <EventosDelDia
            camaras={filtradas}
            fecha={fecha}
            esHoy={esHoy}
            onIr={(cam, ev) => {
              setSeleccionada(cam.id);
              setModo('reproduccion');
              setMinuto(Math.max(0, ev.minuto - 0.25));
              setReproduciendo(true);
            }}
          />
        </aside>
      </div>

      {aviso && (
        <div className="cam-aviso panel">
          <span>{aviso}</span>
          <button className="icon-btn" onClick={() => setAviso(null)}><IcoX width={13} height={13} /></button>
        </div>
      )}
    </div>
  );
}

/** Eventos del día de todas las cámaras visibles, del más reciente al más antiguo. */
function EventosDelDia({ camaras, fecha, esHoy, onIr }) {
  const eventos = useMemo(() => {
    const out = [];
    for (const c of camaras.slice(0, 14)) {
      const g = grabacionCamara(c.id, fecha, esHoy);
      for (const e of g.eventos) out.push({ ...e, camara: c });
    }
    return out.sort((a, b) => b.minuto - a.minuto).slice(0, 40);
  }, [camaras, fecha, esHoy]);

  if (!eventos.length) return <p className="pf-vacio">Sin eventos registrados.</p>;

  return (
    <div className="ce-lista scroll">
      {eventos.map((e) => {
        const t = TIPOS_EVENTO_CAM[e.tipo];
        return (
          <button key={e.id} className="ce-item" onClick={() => onIr(e.camara, e)}>
            <span className="dot" style={{ background: t.color }} />
            <span className="ce-txt">
              <b>{t.nombre}</b>
              <span className="label">{e.camara.nombre} · {e.camara.ubicacion}</span>
            </span>
            <span className="mono ce-hora">
              {String(Math.floor(e.minuto / 60)).padStart(2, '0')}:{String(e.minuto % 60).padStart(2, '0')}
            </span>
          </button>
        );
      })}
    </div>
  );
}
