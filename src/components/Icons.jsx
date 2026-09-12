// Íconos SVG inline — sin dependencias externas.
const base = {
  width: 16, height: 16, viewBox: '0 0 24 24', fill: 'none',
  stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round',
};

const mk = (path) => function Icon(props) {
  return <svg {...base} {...props}>{path}</svg>;
};

export const IcoDron = mk(<>
  <circle cx="12" cy="12" r="2.4" /><path d="M10 10 6.5 6.5M14 10l3.5-3.5M10 14l-3.5 3.5M14 14l3.5 3.5" />
  <circle cx="5" cy="5" r="2.2" /><circle cx="19" cy="5" r="2.2" />
  <circle cx="5" cy="19" r="2.2" /><circle cx="19" cy="19" r="2.2" />
</>);

export const IcoMapa = mk(<>
  <path d="M9 4 3 6.5v13L9 17l6 2.5 6-2.5v-13L15 6.5 9 4Z" /><path d="M9 4v13M15 6.5v13" />
</>);

export const IcoVideo = mk(<>
  <rect x="2.5" y="6" width="13" height="12" rx="2.5" /><path d="m15.5 11 6-3.5v9l-6-3.5Z" />
</>);

export const IcoCalendario = mk(<>
  <rect x="3" y="5" width="18" height="16" rx="2.5" /><path d="M3 10h18M8 3v4M16 3v4" />
</>);

export const IcoBuscar = mk(<><circle cx="11" cy="11" r="7" /><path d="m20 20-3.6-3.6" /></>);

export const IcoCampana = mk(<>
  <path d="M18 9a6 6 0 1 0-12 0c0 5-2 6-2 6h16s-2-1-2-6Z" /><path d="M13.7 20a2 2 0 0 1-3.4 0" />
</>);

export const IcoAjustes = mk(<>
  <circle cx="12" cy="12" r="3" />
  <path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7.5 19.4l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 3 14.6a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 7.5l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 10 3.2V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.5 1.4l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1Z" />
</>);

export const IcoBateria = mk(<>
  <rect x="2" y="7" width="17" height="10" rx="2.5" /><path d="M22 11v2" />
</>);

export const IcoInicio = mk(<><path d="m3 10 9-7 9 7v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" /><path d="M9 21v-7h6v7" /></>);

export const IcoCapas = mk(<>
  <path d="m12 2 9 5-9 5-9-5 9-5Z" /><path d="m3 12 9 5 9-5M3 17l9 5 9-5" />
</>);

export const IcoPlay = mk(<><path d="M6 4.5 19 12 6 19.5v-15Z" fill="currentColor" /></>);
export const IcoPausa = mk(<><rect x="6" y="4.5" width="4" height="15" rx="1" fill="currentColor" /><rect x="14" y="4.5" width="4" height="15" rx="1" fill="currentColor" /></>);

export const IcoIzq = mk(<><path d="m15 5-7 7 7 7" /></>);
export const IcoDer = mk(<><path d="m9 5 7 7-7 7" /></>);
export const IcoAbajo = mk(<><path d="m5 9 7 7 7-7" /></>);

export const IcoAlerta = mk(<>
  <path d="M10.3 3.9 2.5 17.4A2 2 0 0 0 4.2 20.4h15.6a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z" />
  <path d="M12 9v4.5M12 17.2h.01" />
</>);

export const IcoEscudo = mk(<>
  <path d="M12 22s8-3.5 8-10V5.5L12 2 4 5.5V12c0 6.5 8 10 8 10Z" /><path d="m9 12 2 2 4-4" />
</>);

export const IcoReloj = mk(<><circle cx="12" cy="12" r="9" /><path d="M12 7v5.2l3.2 2" /></>);

export const IcoDescarga = mk(<>
  <path d="M12 3v12" /><path d="m7.5 10.5 4.5 4.5 4.5-4.5" /><path d="M4 20h16" />
</>);

export const IcoGrilla = mk(<>
  <rect x="3" y="3" width="7.5" height="7.5" rx="1.6" /><rect x="13.5" y="3" width="7.5" height="7.5" rx="1.6" />
  <rect x="3" y="13.5" width="7.5" height="7.5" rx="1.6" /><rect x="13.5" y="13.5" width="7.5" height="7.5" rx="1.6" />
</>);

export const IcoFiltro = mk(<><path d="M3 5h18l-7 8v6l-4 2v-8L3 5Z" /></>);
export const IcoX = mk(<><path d="M6 6 18 18M18 6 6 18" /></>);
export const IcoMas = mk(<><path d="M12 5v14M5 12h14" /></>);
export const IcoSenal = mk(<><path d="M4 20v-4M9.3 20v-8M14.7 20v-12M20 20V4" /></>);
export const IcoSatelite = mk(<>
  <circle cx="12" cy="12" r="3" /><ellipse cx="12" cy="12" rx="10" ry="4.5" transform="rotate(-28 12 12)" />
</>);
export const IcoAterrizar = mk(<><path d="M12 3v11" /><path d="m8 10 4 4 4-4" /><path d="M5 20h14" /></>);
export const IcoRTH = mk(<><path d="M9 20v-6h6v6" /><path d="m3 10 9-7 9 7v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2Z" /><path d="M12 3v4" /></>);
export const IcoCamara = mk(<>
  <path d="M4 19h16a2 2 0 0 0 2-2V9a2 2 0 0 0-2-2h-2.5l-1.4-2.2A1.5 1.5 0 0 0 14.8 4H9.2a1.5 1.5 0 0 0-1.3.8L6.5 7H4a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2Z" />
  <circle cx="12" cy="13" r="3.4" />
</>);
export const IcoUsuario = mk(<><circle cx="12" cy="8" r="4" /><path d="M4 21c0-4 3.6-6.5 8-6.5S20 17 20 21" /></>);
export const IcoLista = mk(<><path d="M8 6h13M8 12h13M8 18h13M3.5 6h.01M3.5 12h.01M3.5 18h.01" /></>);
export const IcoRuta = mk(<>
  <circle cx="6" cy="19" r="2.5" /><circle cx="18" cy="5" r="2.5" />
  <path d="M8.5 19h5a4 4 0 0 0 0-8h-3a4 4 0 0 1 0-8h5" />
</>);
