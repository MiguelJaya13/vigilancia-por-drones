// Cuadricóptero visto desde arriba, con los cuatro rotores girando.
// El dibujo apunta hacia arriba (norte) y está centrado en 12,12 de un
// viewBox de 24, para poder rotarlo según el rumbo sin descuadrarlo.
// Usa currentColor, así el mismo ícono sirve cian en el mapa y rojo en el croquis.

export const DRON_VIEWBOX = '0 0 24 24';

export const DRON_SVG_INTERNO = `
  <g fill="none" stroke="currentColor" stroke-linecap="round">
    <path d="M8.2 8.2 5.4 5.4M15.8 8.2l2.8-2.8M8.2 15.8l-2.8 2.8M15.8 15.8l2.8 2.8" stroke-width="1.7"/>
    <g class="dron-rotores" stroke-width="1.1" opacity=".95">
      <circle cx="5.4" cy="5.4" r="3.1"/>
      <circle cx="18.6" cy="5.4" r="3.1"/>
      <circle cx="5.4" cy="18.6" r="3.1"/>
      <circle cx="18.6" cy="18.6" r="3.1"/>
    </g>
    <g class="dron-palas" stroke-width="1" opacity=".75">
      <path d="M3.1 5.4h4.6M5.4 3.1v4.6"/>
      <path d="M16.3 5.4h4.6M18.6 3.1v4.6"/>
      <path d="M3.1 18.6h4.6M5.4 16.3v4.6"/>
      <path d="M16.3 18.6h4.6M18.6 16.3v4.6"/>
    </g>
    <rect x="8.6" y="9" width="6.8" height="7.4" rx="2.4" fill="currentColor" stroke="none"/>
    <path d="M12 9V6.6" stroke-width="1.6"/>
    <circle cx="12" cy="13.4" r="1.5" fill="#04141a" stroke="none"/>
  </g>`;

/** Marcado completo listo para innerHTML (marcadores de MapLibre). */
export const dronSVG = (tam = 22) =>
  `<svg viewBox="${DRON_VIEWBOX}" width="${tam}" height="${tam}" class="dron-svg">${DRON_SVG_INTERNO}</svg>`;

/** Versión React del mismo ícono. */
export default function IconoDron({ tam = 22, className = '' }) {
  return (
    <svg
      viewBox={DRON_VIEWBOX}
      width={tam}
      height={tam}
      className={'dron-svg ' + className}
      dangerouslySetInnerHTML={{ __html: DRON_SVG_INTERNO }}
    />
  );
}
