import { useEffect, useRef } from 'react';
import maplibregl from 'maplibre-gl';
import 'maplibre-gl/dist/maplibre-gl.css';
import { RIESGO_COLOR } from '../data/ciudadelas.js';

// Imágenes satelitales de Esri World Imagery: sin API key ni tarjeta,
// suficiente para demo y prototipo.
const ESTILO = {
  version: 8,
  sources: {
    satelite: {
      type: 'raster',
      tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'],
      tileSize: 256,
      attribution: 'Esri, Maxar, Earthstar Geographics',
    },
    etiquetas: {
      type: 'raster',
      tiles: ['https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}'],
      tileSize: 256,
    },
  },
  layers: [
    { id: 'fondo', type: 'background', paint: { 'background-color': '#0a1016' } },
    { id: 'satelite', type: 'raster', source: 'satelite' },
    { id: 'etiquetas', type: 'raster', source: 'etiquetas', paint: { 'raster-opacity': 0.75 } },
  ],
};

/** Polígono circular aproximado, radio en metros. */
function circulo(centro, radioM, pasos = 64) {
  const coords = [];
  const dLat = radioM / 110540;
  const dLng = radioM / (111320 * Math.cos((centro[1] * Math.PI) / 180));
  for (let i = 0; i <= pasos; i++) {
    const a = (i / pasos) * 2 * Math.PI;
    coords.push([centro[0] + dLng * Math.cos(a), centro[1] + dLat * Math.sin(a)]);
  }
  return { type: 'Feature', geometry: { type: 'Polygon', coordinates: [coords] }, properties: {} };
}

const fc = (features) => ({ type: 'FeatureCollection', features });

function elementoDron(dron, activo) {
  const el = document.createElement('div');
  el.className = 'marcador-dron' + (activo ? ' activo' : '');
  el.innerHTML = `
    <div class="md-halo"></div>
    <div class="md-icono" style="transform: rotate(${dron.rumbo || 0}deg)">
      <svg viewBox="0 0 24 24" width="17" height="17" fill="none" stroke="currentColor"
           stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 3.5 17 20l-5-3.2L7 20 12 3.5Z" fill="currentColor" fill-opacity=".9"/>
      </svg>
    </div>
    <div class="md-etiqueta">
      <b>${dron.nombre}</b>
      <span>${Math.round(dron.altitud)} m · ${Math.round(dron.bateria)}%</span>
    </div>`;
  return el;
}

export default function MapaVigilancia({
  ciudadela,
  flota,
  dronActivo,
  sectorActivo,
  onSeleccionarDron,
  onSeleccionarSector,
  capas = { geocerca: true, sectores: true, rutas: true },
}) {
  const cont = useRef(null);
  const mapa = useRef(null);
  const marcadores = useRef(new Map());
  const etiquetasSector = useRef([]);
  const listo = useRef(false);

  // --- init ---
  useEffect(() => {
    if (mapa.current) return undefined;
    const m = new maplibregl.Map({
      container: cont.current,
      style: ESTILO,
      center: ciudadela.centro,
      zoom: 16.1,
      pitch: 45,
      bearing: -12,
      attributionControl: { compact: true },
    });
    m.addControl(new maplibregl.NavigationControl({ visualizePitch: true }), 'bottom-right');
    mapa.current = m;

    m.on('load', () => {
      listo.current = true;
      pintarCiudadela(m, ciudadela, onSeleccionarSector, etiquetasSector);
    });

    return () => { m.remove(); mapa.current = null; listo.current = false; };
  }, []);

  // --- cambio de ciudadela ---
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo.current) return;
    marcadores.current.forEach((mk) => mk.remove());
    marcadores.current.clear();
    pintarCiudadela(m, ciudadela, onSeleccionarSector, etiquetasSector);
    m.flyTo({ center: ciudadela.centro, zoom: 16.1, pitch: 45, bearing: -12, duration: 1200 });
  }, [ciudadela.id]);

  // --- capas visibles ---
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo.current) return;
    const set = (id, on) => m.getLayer(id) && m.setLayoutProperty(id, 'visibility', on ? 'visible' : 'none');
    set('geocerca-fill', capas.geocerca);
    set('geocerca-line', capas.geocerca);
    set('sectores-fill', capas.sectores);
    set('sectores-line', capas.sectores);
    set('rutas-line', capas.rutas);
    etiquetasSector.current.forEach((mk) => {
      mk.getElement().style.display = capas.sectores ? '' : 'none';
    });
  }, [capas.geocerca, capas.sectores, capas.rutas, ciudadela.id]);

  // --- resaltado del sector seleccionado ---
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo.current || !m.getLayer('sectores-fill')) return;
    m.setPaintProperty('sectores-fill', 'fill-opacity', [
      'case', ['==', ['get', 'id'], sectorActivo || '—'], 0.42, 0.13,
    ]);
    m.setPaintProperty('sectores-line', 'line-width', [
      'case', ['==', ['get', 'id'], sectorActivo || '—'], 3, 1.4,
    ]);
  }, [sectorActivo, ciudadela.id]);

  // --- marcadores de drones ---
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo.current) return;
    flota.forEach((d) => {
      const activo = d.id === dronActivo;
      let mk = marcadores.current.get(d.id);
      if (!mk) {
        const el = elementoDron(d, activo);
        el.addEventListener('click', (ev) => { ev.stopPropagation(); onSeleccionarDron?.(d.id); });
        mk = new maplibregl.Marker({ element: el, anchor: 'center' })
          .setLngLat(d.posicion).addTo(m);
        marcadores.current.set(d.id, mk);
      } else {
        mk.setLngLat(d.posicion);
        const el = mk.getElement();
        el.classList.toggle('activo', activo);
        el.classList.toggle('en-base', d.estado === 'En base' || d.estado === 'Cargando');
        const ico = el.querySelector('.md-icono');
        if (ico) ico.style.transform = `rotate(${d.rumbo || 0}deg)`;
        const et = el.querySelector('.md-etiqueta span');
        if (et) et.textContent = `${Math.round(d.altitud)} m · ${Math.round(d.bateria)}%`;
      }
    });
  }, [flota, dronActivo]);

  // --- centrar en el dron activo ---
  useEffect(() => {
    const m = mapa.current;
    if (!m || !listo.current || !dronActivo) return;
    const d = flota.find((x) => x.id === dronActivo);
    if (d) m.easeTo({ center: d.posicion, duration: 900 });
  }, [dronActivo]);

  return <div ref={cont} className="mapa-lienzo" />;
}

function pintarCiudadela(m, cd, onSeleccionarSector, refEtiquetas) {
  // Limpieza previa
  ['geocerca-fill', 'geocerca-line', 'sectores-fill', 'sectores-line', 'perimetro-line', 'rutas-line']
    .forEach((id) => m.getLayer(id) && m.removeLayer(id));
  ['geocerca', 'sectores', 'perimetro', 'rutas']
    .forEach((id) => m.getSource(id) && m.removeSource(id));
  refEtiquetas.current.forEach((mk) => mk.remove());
  refEtiquetas.current = [];

  m.addSource('geocerca', { type: 'geojson', data: circulo(cd.geocerca.centro, cd.geocerca.radio) });
  m.addLayer({
    id: 'geocerca-fill', type: 'fill', source: 'geocerca',
    paint: { 'fill-color': '#22d3ee', 'fill-opacity': 0.1 },
  });
  m.addLayer({
    id: 'geocerca-line', type: 'line', source: 'geocerca',
    paint: { 'line-color': '#22d3ee', 'line-width': 2, 'line-opacity': 0.65, 'line-dasharray': [3, 2] },
  });

  m.addSource('perimetro', {
    type: 'geojson',
    data: { type: 'Feature', geometry: { type: 'Polygon', coordinates: cd.perimetro }, properties: {} },
  });
  m.addLayer({
    id: 'perimetro-line', type: 'line', source: 'perimetro',
    paint: { 'line-color': '#e8eef7', 'line-width': 2.2, 'line-opacity': 0.9 },
  });

  m.addSource('sectores', {
    type: 'geojson',
    data: fc(cd.sectores.map((s) => ({
      type: 'Feature',
      geometry: { type: 'Polygon', coordinates: s.poligono },
      properties: { id: s.id, nombre: s.nombre, color: RIESGO_COLOR[s.riesgo] },
    }))),
  });
  m.addLayer({
    id: 'sectores-fill', type: 'fill', source: 'sectores',
    paint: { 'fill-color': ['get', 'color'], 'fill-opacity': 0.13 },
  });
  m.addLayer({
    id: 'sectores-line', type: 'line', source: 'sectores',
    paint: { 'line-color': ['get', 'color'], 'line-width': 1.4, 'line-opacity': 0.9 },
  });

  m.addSource('rutas', {
    type: 'geojson',
    data: fc(cd.drones.map((d) => ({
      type: 'Feature',
      geometry: { type: 'LineString', coordinates: [...d.ruta, d.ruta[0]] },
      properties: { id: d.id },
    }))),
  });
  m.addLayer({
    id: 'rutas-line', type: 'line', source: 'rutas',
    paint: {
      'line-color': '#ffffff', 'line-width': 1.1, 'line-opacity': 0.45, 'line-dasharray': [2, 3],
    },
  });

  m.on('click', 'sectores-fill', (e) => {
    const f = e.features?.[0];
    if (f) onSeleccionarSector?.(f.properties.id);
  });
  m.on('mouseenter', 'sectores-fill', () => { m.getCanvas().style.cursor = 'pointer'; });
  m.on('mouseleave', 'sectores-fill', () => { m.getCanvas().style.cursor = ''; });

  // Etiquetas de sector como marcadores HTML (el estilo raster no trae glyphs).
  cd.sectores.forEach((s) => {
    const el = document.createElement('div');
    el.className = 'etiqueta-sector';
    el.style.setProperty('--c', RIESGO_COLOR[s.riesgo]);
    el.innerHTML = `<b>${s.id}</b><span>${s.nombre}</span>`;
    el.addEventListener('click', () => onSeleccionarSector?.(s.id));
    refEtiquetas.current.push(new maplibregl.Marker({ element: el }).setLngLat(s.centro).addTo(m));
  });
}
