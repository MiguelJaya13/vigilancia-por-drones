// Ciudadelas monitoreadas — zona Vía a Samborondón, Guayas, Ecuador.
// Las coordenadas son [lng, lat] (orden GeoJSON / MapLibre).

const M = 0.00001; // ~1.1 m en latitud

/** Rectángulo centrado en `c`, de `w` x `h` metros. */
function rect(c, w, h) {
  const dx = (w / 2) * M * 1.12; // corrección aprox. de longitud a -2° lat
  const dy = (h / 2) * M;
  return [[
    [c[0] - dx, c[1] - dy],
    [c[0] + dx, c[1] - dy],
    [c[0] + dx, c[1] + dy],
    [c[0] - dx, c[1] + dy],
    [c[0] - dx, c[1] - dy],
  ]];
}

/** Divide el rectángulo de la ciudadela en 4 sectores (cuadrantes). */
function construirSectores(c, w, h, defs) {
  const qw = w / 2, qh = h / 2;
  const dx = (qw / 2) * M * 1.12;
  const dy = (qh / 2) * M;
  const centros = [
    [c[0] - dx, c[1] + dy], // A: noroeste
    [c[0] + dx, c[1] + dy], // B: noreste
    [c[0] - dx, c[1] - dy], // C: suroeste
    [c[0] + dx, c[1] - dy], // D: sureste
  ];
  return defs.map((d, i) => ({
    ...d,
    centro: centros[i],
    poligono: rect(centros[i], qw - 40, qh - 40),
  }));
}

/** Ruta de patrullaje: perímetro interior del sector. */
function rutaPatrulla(centro, w, h) {
  const dx = (w / 2) * M * 1.12, dy = (h / 2) * M;
  return [
    [centro[0] - dx, centro[1] - dy],
    [centro[0] + dx, centro[1] - dy],
    [centro[0] + dx, centro[1] + dy],
    [centro[0] - dx, centro[1] + dy],
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
      ruta: rutaPatrulla(sec.centro, ancho / 2 - 90, alto / 2 - 90),
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
    nombre: 'Ciudadela La Puntilla',
    direccion: 'Km 1.5 Vía Samborondón',
    centro: [-79.8865, -2.1452],
    ancho: 900, alto: 700,
    camaras: 24, viviendas: 312,
    sectoresDef: [
      { id: 'A', nombre: 'Entrada principal', riesgo: 'medio' },
      { id: 'B', nombre: 'Área social', riesgo: 'bajo' },
      { id: 'C', nombre: 'Perímetro sur', riesgo: 'alto' },
      { id: 'D', nombre: 'Parqueaderos', riesgo: 'medio' },
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
    nombre: 'Ciudadela Entre Ríos',
    direccion: 'Km 6.5 Vía Samborondón',
    centro: [-79.8722, -2.1291],
    ancho: 1100, alto: 800,
    camaras: 31, viviendas: 448,
    sectoresDef: [
      { id: 'A', nombre: 'Garita norte', riesgo: 'bajo' },
      { id: 'B', nombre: 'Club house', riesgo: 'bajo' },
      { id: 'C', nombre: 'Ribera del río', riesgo: 'alto' },
      { id: 'D', nombre: 'Manzanas 8-14', riesgo: 'medio' },
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
    nombre: 'Ciudadela Villa Club',
    direccion: 'Km 12 Vía Samborondón',
    centro: [-79.8561, -2.0962],
    ancho: 1300, alto: 900,
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
    nombre: 'Ciudadela Ciudad Celeste',
    direccion: 'Km 4.5 Vía Samborondón',
    centro: [-79.8641, -2.1181],
    ancho: 1000, alto: 750,
    camaras: 28, viviendas: 385,
    sectoresDef: [
      { id: 'A', nombre: 'Ingreso vehicular', riesgo: 'medio' },
      { id: 'B', nombre: 'Áreas verdes', riesgo: 'bajo' },
      { id: 'C', nombre: 'Zona comercial', riesgo: 'alto' },
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
