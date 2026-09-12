// Ciudadelas monitoreadas en Guayas, Ecuador.
// Centros verificados contra la imagen satelital (tiles Esri z16) y nombrados
// por geocodificación inversa de OpenStreetMap: caen sobre manzanas
// urbanizadas, no sobre el río Daule ni el Babahoyo.
// Las coordenadas son [lng, lat] (orden GeoJSON / MapLibre).

const M_POR_GRADO_LAT = 110540;
const M_POR_GRADO_LNG = 111320;

/** Metros a grados en el punto dado (la longitud se acorta con la latitud). */
function aGrados(metrosX, metrosY, lat) {
  return {
    dLng: metrosX / (M_POR_GRADO_LNG * Math.cos((lat * Math.PI) / 180)),
    dLat: metrosY / M_POR_GRADO_LAT,
  };
}

/** Rectángulo centrado en `c`, de `w` x `h` metros. */
function rect(c, w, h) {
  const { dLng, dLat } = aGrados(w / 2, h / 2, c[1]);
  return [[
    [c[0] - dLng, c[1] - dLat],
    [c[0] + dLng, c[1] - dLat],
    [c[0] + dLng, c[1] + dLat],
    [c[0] - dLng, c[1] + dLat],
    [c[0] - dLng, c[1] - dLat],
  ]];
}

/** Divide el rectángulo de la ciudadela en 4 sectores (cuadrantes). */
function construirSectores(c, w, h, defs) {
  const qw = w / 2, qh = h / 2;
  const { dLng, dLat } = aGrados(qw / 2, qh / 2, c[1]);
  const centros = [
    [c[0] - dLng, c[1] + dLat], // A: noroeste
    [c[0] + dLng, c[1] + dLat], // B: noreste
    [c[0] - dLng, c[1] - dLat], // C: suroeste
    [c[0] + dLng, c[1] - dLat], // D: sureste
  ];
  return defs.map((d, i) => ({
    ...d,
    centro: centros[i],
    poligono: rect(centros[i], qw - 26, qh - 26),
  }));
}

/** Ruta de patrullaje: perímetro interior del sector. */
function rutaPatrulla(centro, w, h) {
  const { dLng, dLat } = aGrados(w / 2, h / 2, centro[1]);
  return [
    [centro[0] - dLng, centro[1] - dLat],
    [centro[0] + dLng, centro[1] - dLat],
    [centro[0] + dLng, centro[1] + dLat],
    [centro[0] - dLng, centro[1] + dLat],
  ];
}

function build(cfg) {
  const { id, codigo, nombre, direccion, centro, ancho, alto, sectoresDef, dronesDef, camaras, viviendas } = cfg;
  const secs = construirSectores(centro, ancho, alto, sectoresDef);
  const drones = dronesDef.map((d) => {
    const sec = secs.find((s) => s.id === d.sector) || secs[0];
    return {
      ...d,
      ciudadela: id,
      base: centro,
      ruta: rutaPatrulla(sec.centro, ancho / 2 - 70, alto / 2 - 70),
      posicion: sec.centro,
    };
  });
  return {
    id, codigo, nombre, direccion, centro, camaras, viviendas,
    perimetro: rect(centro, ancho, alto),
    geocerca: { centro, radio: Math.max(ancho, alto) * 0.6 },
    sectores: secs,
    drones,
  };
}

export const CIUDADELAS = [
  build({
    id: 'cd1',
    codigo: 'CD1',
    nombre: 'Ciudadela Entre Ríos',
    direccion: 'Vía a Samborondón · Samborondón',
    centro: [-79.867859, -2.150069],
    ancho: 460, alto: 340,
    camaras: 24, viviendas: 312,
    sectoresDef: [
      { id: 'A', nombre: 'Garita principal', riesgo: 'medio' },
      { id: 'B', nombre: 'Área social y club', riesgo: 'bajo' },
      { id: 'C', nombre: 'Ribera del río', riesgo: 'alto' },
      { id: 'D', nombre: 'Manzanas 12-20', riesgo: 'medio' },
    ],
    dronesDef: [
      { id: 'CD1-D1', nombre: 'HalcónCat', modelo: 'DJI Matrice 30T', bateria: 72, sector: 'A', estado: 'En vuelo' },
      { id: 'CD1-D2', nombre: 'Vigía 02', modelo: 'DJI Mavic 3E', bateria: 64, sector: 'B', estado: 'En vuelo' },
      { id: 'CD1-D3', nombre: 'Vigía 03', modelo: 'DJI Mavic 3E', bateria: 91, sector: 'C', estado: 'En vuelo' },
      { id: 'CD1-D4', nombre: 'Centinela 04', modelo: 'Autel EVO II', bateria: 38, sector: 'D', estado: 'Retornando' },
      { id: 'CD1-D5', nombre: 'Centinela 05', modelo: 'Autel EVO II', bateria: 100, sector: 'A', estado: 'En base' },
    ],
  }),
  build({
    id: 'cd2',
    codigo: 'CD2',
    nombre: 'Ciudadela Los Guayacanes',
    direccion: '2ª Etapa · Tarqui, Guayaquil',
    centro: [-79.889832, -2.117133],
    ancho: 460, alto: 340,
    camaras: 31, viviendas: 448,
    sectoresDef: [
      { id: 'A', nombre: 'Ingreso Paseo 20', riesgo: 'medio' },
      { id: 'B', nombre: 'Parque central', riesgo: 'bajo' },
      { id: 'C', nombre: 'Zona comercial', riesgo: 'alto' },
      { id: 'D', nombre: 'Perímetro sur', riesgo: 'medio' },
    ],
    dronesDef: [
      { id: 'CD2-D1', nombre: 'Guardián 01', modelo: 'DJI Matrice 30T', bateria: 88, sector: 'A', estado: 'En vuelo' },
      { id: 'CD2-D2', nombre: 'Guardián 02', modelo: 'DJI Matrice 30T', bateria: 55, sector: 'C', estado: 'En vuelo' },
      { id: 'CD2-D3', nombre: 'Vigía 03', modelo: 'DJI Mavic 3E', bateria: 47, sector: 'D', estado: 'En vuelo' },
      { id: 'CD2-D4', nombre: 'Vigía 04', modelo: 'DJI Mavic 3E', bateria: 12, sector: 'B', estado: 'Cargando' },
    ],
  }),
  build({
    id: 'cd3',
    codigo: 'CD3',
    nombre: 'Urbanización Villa Club',
    direccion: 'La Aurora · Daule',
    centro: [-79.895325, -2.040279],
    ancho: 460, alto: 340,
    camaras: 42, viviendas: 690,
    sectoresDef: [
      { id: 'A', nombre: 'Etapa Cielo', riesgo: 'medio' },
      { id: 'B', nombre: 'Etapa Luna', riesgo: 'bajo' },
      { id: 'C', nombre: 'Etapa Sol', riesgo: 'medio' },
      { id: 'D', nombre: 'Perímetro este', riesgo: 'alto' },
    ],
    dronesDef: [
      { id: 'CD3-D1', nombre: 'Águila 01', modelo: 'DJI Matrice 350', bateria: 76, sector: 'A', estado: 'En vuelo' },
      { id: 'CD3-D2', nombre: 'Águila 02', modelo: 'DJI Matrice 350', bateria: 69, sector: 'B', estado: 'En vuelo' },
      { id: 'CD3-D3', nombre: 'Halcón 03', modelo: 'DJI Matrice 30T', bateria: 82, sector: 'C', estado: 'En vuelo' },
      { id: 'CD3-D4', nombre: 'Halcón 04', modelo: 'DJI Matrice 30T', bateria: 29, sector: 'D', estado: 'Retornando' },
      { id: 'CD3-D5', nombre: 'Centinela 05', modelo: 'Autel EVO II', bateria: 94, sector: 'D', estado: 'En vuelo' },
      { id: 'CD3-D6', nombre: 'Centinela 06', modelo: 'Autel EVO II', bateria: 100, sector: 'A', estado: 'En base' },
    ],
  }),
  build({
    id: 'cd4',
    codigo: 'CD4',
    nombre: 'Urbanización La Joya',
    direccion: 'Etapa Tiara · La Aurora, Daule',
    centro: [-79.917297, -2.034789],
    ancho: 460, alto: 340,
    camaras: 28, viviendas: 385,
    sectoresDef: [
      { id: 'A', nombre: 'Garita Tiara', riesgo: 'medio' },
      { id: 'B', nombre: 'Áreas verdes', riesgo: 'bajo' },
      { id: 'C', nombre: 'Centro comercial', riesgo: 'alto' },
      { id: 'D', nombre: 'Perímetro oeste', riesgo: 'medio' },
    ],
    dronesDef: [
      { id: 'CD4-D1', nombre: 'Sentry 01', modelo: 'DJI Matrice 30T', bateria: 61, sector: 'A', estado: 'En vuelo' },
      { id: 'CD4-D2', nombre: 'Sentry 02', modelo: 'DJI Mavic 3E', bateria: 78, sector: 'C', estado: 'En vuelo' },
      { id: 'CD4-D3', nombre: 'Sentry 03', modelo: 'DJI Mavic 3E', bateria: 44, sector: 'D', estado: 'En vuelo' },
      { id: 'CD4-D4', nombre: 'Sentry 04', modelo: 'Autel EVO II', bateria: 100, sector: 'B', estado: 'En base' },
    ],
  }),
];

export const getCiudadela = (id) => CIUDADELAS.find((c) => c.id === id) || CIUDADELAS[0];

export const RIESGO_COLOR = { bajo: '#10b981', medio: '#f59e0b', alto: '#ef4444' };

export const ESTADO_TIPO = {
  'En vuelo': 'ok',
  'Retornando': 'warn',
  'Cargando': 'warn',
  'En base': 'idle',
  'Sin señal': 'bad',
};
