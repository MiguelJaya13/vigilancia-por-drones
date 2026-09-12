import { useEffect, useState } from 'react';
import { useParams } from 'react-router-dom';
import { getCiudadela, RIESGO_COLOR } from '../data/ciudadelas.js';
import { useDroneSim } from '../hooks/useDroneSim.js';
import MapaVigilancia from '../components/MapaVigilancia.jsx';
import PanelFlota from '../components/PanelFlota.jsx';
import RegistroActividad from '../components/RegistroActividad.jsx';
import FeedVideo from '../components/FeedVideo.jsx';
import ControlesVuelo from '../components/ControlesVuelo.jsx';
import BarraSuperior from '../components/BarraSuperior.jsx';
import { IcoCapas } from '../components/Icons.jsx';
import '../styles/monitoreo.css';

export default function Monitoreo() {
  const { cdId } = useParams();
  const ciudadela = getCiudadela(cdId);

  const [pausado, setPausado] = useState(false);
  const [dronActivo, setDronActivo] = useState(ciudadela.drones[0].id);
  const [sectorActivo, setSectorActivo] = useState(null);
  const [capas, setCapas] = useState({ geocerca: true, sectores: true, rutas: true });

  const { flota, registro, setFlota } = useDroneSim(ciudadela, { activo: !pausado });

  useEffect(() => {
    setDronActivo(ciudadela.drones[0].id);
    setSectorActivo(null);
  }, [ciudadela.id]);

  const dron = flota.find((d) => d.id === dronActivo) || flota[0];
  const alertas = registro.filter((e) => e.tipo !== 'info').length;

  const accion = (tipo) => {
    setFlota((prev) => prev.map((d) => (d.id !== dronActivo ? d : {
      ...d, estado: tipo === 'rth' ? 'Retornando' : 'En base',
    })));
  };

  const toggleCapa = (k) => setCapas((c) => ({ ...c, [k]: !c[k] }));

  return (
    <div className="monitoreo">
      <MapaVigilancia
        ciudadela={ciudadela}
        flota={flota}
        dronActivo={dronActivo}
        sectorActivo={sectorActivo}
        onSeleccionarDron={setDronActivo}
        onSeleccionarSector={(s) => setSectorActivo((v) => (v === s ? null : s))}
        capas={capas}
      />

      <div className="hud">
        <div className="hud-top">
          <BarraSuperior ciudadelaId={ciudadela.id} alertas={alertas} />
        </div>

        <div className="hud-fila">
          <PanelFlota
            ciudadela={ciudadela}
            flota={flota}
            dronActivo={dronActivo}
            onSeleccionar={setDronActivo}
          />

          <div className="hud-centro">
            <div className="hud-cabecera">
              <div className="panel titulo-cd">
                <span className="tcd-codigo">{ciudadela.codigo}</span>
                <div>
                  <b>{ciudadela.nombre}</b>
                  <span className="label">{ciudadela.direccion}</span>
                </div>
              </div>
              <RegistroActividad registro={registro} />
            </div>

            <div className="hud-pie">
              <ControlesVuelo
                dron={dron}
                onAccion={accion}
                pausado={pausado}
                onTogglePausa={() => setPausado((v) => !v)}
              />
            </div>
          </div>

          <div className="hud-derecha">
            <FeedVideo dron={dron} ciudadela={ciudadela} />

            <div className="panel capas">
              <span className="label"><IcoCapas width={13} height={13} /> Capas</span>
              {[['geocerca', 'Geocerca'], ['sectores', 'Sectores'], ['rutas', 'Rutas']].map(([k, txt]) => (
                <label key={k} className="capa-item">
                  <input type="checkbox" checked={capas[k]} onChange={() => toggleCapa(k)} />
                  <span>{txt}</span>
                </label>
              ))}
            </div>

            <div className="panel sectores-mini">
              <span className="label">Sectores · nivel de riesgo</span>
              {ciudadela.sectores.map((s) => {
                const enSector = flota.filter((d) => d.sector === s.id).length;
                return (
                  <button
                    key={s.id}
                    className={'sm-item' + (sectorActivo === s.id ? ' on' : '')}
                    onClick={() => setSectorActivo((v) => (v === s.id ? null : s.id))}
                  >
                    <span className="sm-badge" style={{ background: RIESGO_COLOR[s.riesgo] }}>{s.id}</span>
                    <span className="sm-nombre">{s.nombre}</span>
                    <span className="label">{enSector} dron{enSector === 1 ? '' : 'es'}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
