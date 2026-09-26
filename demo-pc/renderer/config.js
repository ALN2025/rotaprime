/** ID fixo deste simulador (copie em Configurações → Licença no demo). */
export const DEMO_DEVICE_ID = 'demo7a9f3e2b1c84d56e78f90ab';

/** Licença PRO válida para o ID acima (gerada com tool/generate_license.dart). */
export const DEMO_LICENSE_TOKEN =
  'Mnxwcm98ZGVtbzdhOWYzZTJiMWM4NGQ1NmU3OGY5MGFifERlbW9uc3RyYWNhbyBWaWRlbw.ltFda2Noi6izBXZy9UJ1P99QTDtPssXiGab7L2ZoltSkGLMp6fqvkzadfkJ0bwkorP0Swt6FTnFrtAB_GsrYBw';

export const DEMO_ROUTE = {
  titulo: '22/09/2026 · ROTA DEMO · 14:32',
  totalPacotes: 12,
  paradas: [
    { id: 1, ordem: 12, stop: 10, address: 'Rua Os Dezoito do Forte, 550', lat: -29.1682, lng: -51.1794, entregue: false },
    { id: 2, ordem: 11, stop: 9, address: 'Av. Júlio de Castilhos, 1200', lat: -29.1655, lng: -51.1821, entregue: false },
    { id: 3, ordem: 10, stop: 8, address: 'Rua Pinheiro Machado, 890', lat: -29.1628, lng: -51.1756, entregue: true },
    { id: 4, ordem: 9, stop: 7, address: 'Rua Ernesto Alves, 45', lat: -29.1601, lng: -51.1712, entregue: true },
    { id: 5, ordem: 8, stop: 6, address: 'Rua Coronel Chicuta, 310', lat: -29.1574, lng: -51.1688, entregue: false },
    { id: 6, ordem: 7, stop: 5, address: 'Rua Sinimbu, 720 — Empresa', lat: -29.1550, lng: -51.1655, entregue: false, comercial: true },
  ],
};
