// Utilidades para componer la "vista de cámara" a partir de tiles satelitales.

export const ZOOM_CAMARA = 18;

/** Coordenadas de tile (fraccionarias) para un punto [lng, lat]. */
export function tileXY([lng, lat], z = ZOOM_CAMARA) {
  const n = 2 ** z;
  const x = ((lng + 180) / 360) * n;
  const r = (lat * Math.PI) / 180;
  const y = ((1 - Math.log(Math.tan(r) + 1 / Math.cos(r)) / Math.PI) / 2) * n;
  return { x, y };
}

export const tileURL = (x, y, z = ZOOM_CAMARA) =>
  `https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/${z}/${y}/${x}`;

/** Mosaico 3x3 centrado en `pos`, con el desplazamiento sub-tile en %. */
export function mosaico(pos, z = ZOOM_CAMARA) {
  const { x, y } = tileXY(pos, z);
  const bx = Math.floor(x), by = Math.floor(y);
  const tiles = [];
  for (let dy = -1; dy <= 1; dy++) {
    for (let dx = -1; dx <= 1; dx++) tiles.push([bx + dx, by + dy]);
  }
  return { tiles, offX: (x - bx - 0.5) * 100, offY: (y - by - 0.5) * 100, z };
}
