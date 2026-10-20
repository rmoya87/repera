// Pictogramas SVG accesibles, 20x20: mismo lenguaje visual en todos los perfiles.
const paths={
 dashboard:'<rect x="3" y="3" width="8" height="8" rx="2"/><rect x="13" y="3" width="8" height="5" rx="2"/><rect x="13" y="10" width="8" height="11" rx="2"/><rect x="3" y="13" width="8" height="8" rx="2"/>',
 clients:'<path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75"/>',
 planning:'<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18M8 14h3M8 18h3M15 14h2"/>',
 groups:'<circle cx="8" cy="8" r="3"/><path d="M2 21v-2a6 6 0 0 1 12 0v2M17 5a3 3 0 0 1 0 6M16 16a5 5 0 0 1 6 5"/>',
 agenda:'<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18M8 14h3M8 18h6"/>',
 calendar:'<rect x="3" y="4" width="18" height="17" rx="2"/><path d="M8 2v4M16 2v4M3 10h18M8 15h3M15 15h3"/>',
 operations:'<path d="M9 11l3 3L22 4"/><path d="M20 13v7a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V5a1 1 0 0 1 1-1h11"/>',
 products:'<path d="M20 13l-7 7a2 2 0 0 1-3 0L2 12V3h9l9 9a2 2 0 0 1 0 1Z"/><circle cx="7" cy="8" r="1"/>',
 billing:'<path d="M4 3h16v18l-4-2-4 2-4-2-4 2Z"/><path d="M8 8h8M8 12h8M8 16h4"/>',
 analytics:'<path d="M3 3v18h18M7 16v-4M12 16V8M17 16V5"/>',
 notifications:'<path d="M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9M10 21h4"/>',
 team:'<rect x="4" y="2" width="16" height="20" rx="2"/><path d="M9 6h6M9 10h6M9 14h6M9 18h6"/>',
 settings:'<path d="M12 2a2 2 0 0 1 2 2l.4 1.5 1.5.6 1.4-.8a2 2 0 0 1 2.7.7l.5.9a2 2 0 0 1-.7 2.7l-1.1 1.1v1.6l1.1 1.1a2 2 0 0 1 .7 2.7l-.5.9a2 2 0 0 1-2.7.7l-1.4-.8-1.5.6L14 20a2 2 0 0 1-4 0l-.4-1.5-1.5-.6-1.4.8a2 2 0 0 1-2.7-.7l-.5-.9a2 2 0 0 1 .7-2.7l1.1-1.1v-1.6L4.2 10.6a2 2 0 0 1-.7-2.7l.5-.9a2 2 0 0 1 2.7-.7l1.4.8 1.5-.6L10 4a2 2 0 0 1 2-2Z"/><circle cx="12" cy="12" r="3"/>',
 admin:'<path d="M12 22s8-4 8-11V5l-8-3-8 3v6c0 7 8 11 8 11Z"/><path d="m9 12 2 2 4-4"/>'
};
export function navIcon(name){return `<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.85" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${paths[name]||paths.dashboard}</svg>`;}