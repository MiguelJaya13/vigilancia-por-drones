// Cuadricóptero visto desde arriba, con los cuatro rotores girando.
// El dibujo apunta hacia arriba (norte) y está centrado en 12,12 de un
// viewBox de 24, para poder rotarlo según el rumbo sin descuadrarlo.
// Usa currentColor, así el mismo ícono sirve cian en el mapa y rojo en el croquis.
//
// Las palas giran con SMIL (animateTransform) y no con CSS a propósito:
// una animación CSS de transform sobre un elemento SVG reemplaza a su
// atributo transform, así que las piezas se salían de su rotor.

export const DRON_VIEWBOX = '0 0 24 24';

const ROTORES = [[5.4, 5.4], [18.6, 5.4], [5.4, 18.6], [18.6, 18.6]];

const rotor = ([cx, cy], i) => `
    <g>
      <circle cx="${cx}" cy="${cy}" r="3.1" stroke-width="1.1" opacity=".55"/>
      <path d="M${cx - 2.3},${cy} h4.6 M${cx},${cy - 2.3} v4.6" stroke-width="1" opacity=".8">
        <animateTransform attributeName="transform" type="rotate"
          from="0 ${cx} ${cy}" to="360 ${cx} ${cy}"
          dur="0.${45 + i}s" repeatCount="indefinite"/>
      </path>
    </g>`;

export const DRON_SVG_INTERNO = `
  <g fill="none" stroke="currentColor" stroke-linecap="round">
    <path d="M8.4 8.4 6.2 6.2M15.6 8.4l2.2-2.2M8.4 15.6l-2.2 2.2M15.6 15.6l2.2 2.2" stroke-width="1.7"/>
    ${ROTORES.map(rotor).join('')}
    <rect x="8.7" y="9.1" width="6.6" height="7.2" rx="2.3" fill="currentColor" stroke="none"/>
    <path d="M12 9.1V6.4" stroke-width="1.6"/>
    <circle cx="12" cy="13.5" r="1.4" fill="#04141a" stroke="none"/>
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
