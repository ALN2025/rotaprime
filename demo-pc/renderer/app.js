const DEMO_DEVICE_ID = 'demo7a9f3e2b1c84d56e78f90ab';
const DEMO_LICENSE_TOKEN =
  'Mnxwcm98ZGVtbzdhOWYzZTJiMWM4NGQ1NmU3OGY5MGFifERlbW9uc3RyYWNhbyBWaWRlbw.ltFda2Noi6izBXZy9UJ1P99QTDtPssXiGab7L2ZoltSkGLMp6fqvkzadfkJ0bwkorP0Swt6FTnFrtAB_GsrYBw';
const DEMO_ROUTE = {
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

const STORAGE_KEY = 'rota-prime-demo-state';

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) return { ...defaultState(), ...JSON.parse(raw) };
  } catch (_) {}
  return defaultState();
}

function saveState(s) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify({
    isPro: s.isPro,
    paradas: s.paradas,
    screen: s.screen,
  }));
}

function defaultState() {
  return {
    screen: 'splash',
    isPro: false,
    paradas: DEMO_ROUTE.paradas.map((p) => ({ ...p })),
    mapTab: 'mapa',
    selectedId: null,
    basemap: 'streets',
  };
}

let state = loadState();
let mapInstance = null;
let routeLine = null;
let markersLayer = [];

const app = document.getElementById('app');

function pendingCount() {
  return state.paradas.filter((p) => !p.entregue && !p.falha).length;
}

function doneCount() {
  return state.paradas.filter((p) => p.entregue).length;
}

function currentStop() {
  return state.paradas.find((p) => !p.entregue && !p.falha) || state.paradas[0];
}

function normalizeLicense(input) {
  return input.replace(/\s+/g, '').trim();
}

function validateLicense(input) {
  const n = normalizeLicense(input);
  return n === normalizeLicense(DEMO_LICENSE_TOKEN);
}

function showToast(msg) {
  const old = document.querySelector('.toast');
  if (old) old.remove();
  const t = document.createElement('div');
  t.className = 'toast';
  t.textContent = msg;
  app.querySelector('.screen:not(.hidden)')?.appendChild(t);
  setTimeout(() => t.remove(), 2800);
}

function setScreen(name) {
  state.screen = name;
  saveState(state);
  render();
}

function render() {
  app.innerHTML = '';
  const screens = {
    splash: renderSplash,
    hub: renderHub,
    plan: renderPlanMap,
    delivery: renderDelivery,
    settings: renderSettings,
    license: renderLicense,
    compare: renderCompare,
  };
  (screens[state.screen] || renderHub)();
}

function renderSplash() {
  const el = document.createElement('div');
  el.className = 'screen splash';
  el.innerHTML = `
    <div class="logo">ROTA PRIME</div>
    <p class="sub">DEV ALN · otimização para entregadores</p>
    <p class="sub" style="margin-top:24px">Carregando demo…</p>
  `;
  app.appendChild(el);
  setTimeout(() => {
    if (state.screen === 'splash') setScreen('hub');
  }, 2200);
}

function renderHub() {
  const el = document.createElement('div');
  el.className = 'screen';
  el.innerHTML = `
    <div class="top-bar" style="position:relative;background:var(--sheet)">
      <button class="icon-btn" data-go="settings">☰</button>
      <span style="font-weight:800">Minhas rotas</span>
      ${state.isPro ? '<span class="pro-badge">PRO</span>' : ''}
    </div>
    <div class="hub-list">
      <div class="card" data-go="plan">
        <div class="card-title">${DEMO_ROUTE.titulo}</div>
        <div class="card-meta">${state.paradas.length} paradas · ${DEMO_ROUTE.totalPacotes} pacotes · demo</div>
        <div class="card-meta">${doneCount()} entregues · ${pendingCount()} pendentes</div>
      </div>
      <div class="card" data-go="delivery">
        <div class="card-title">▶ Continuar entrega</div>
        <div class="card-meta">Mapa + lista · Entregue / Não entregue</div>
      </div>
      <div class="card" data-go="compare">
        <div class="card-title">Grátis vs PRO</div>
        <div class="card-meta">Veja o que muda ao ativar licença</div>
      </div>
      <button class="btn btn-outline" data-go="license" style="margin-top:8px">Ativar licença PRO (demo)</button>
    </div>
  `;
  bindNav(el);
  app.appendChild(el);
}

function bindNav(root) {
  root.querySelectorAll('[data-go]').forEach((node) => {
    node.addEventListener('click', () => setScreen(node.dataset.go));
  });
}

function initMap(containerId, interactive = true) {
  if (mapInstance) {
    mapInstance.remove();
    mapInstance = null;
    routeLine = null;
    markersLayer = [];
  }
  const center = currentStop();
  mapInstance = L.map(containerId, {
    zoomControl: false,
    attributionControl: false,
  }).setView([center.lat, center.lng], 15);

  const esriStreets =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}';
  L.tileLayer(esriStreets, { maxZoom: 19 }).addTo(mapInstance);

  state.paradas.forEach((p) => {
    let color = '#78909c';
    if (p.entregue) color = '#4caf50';
    else if (p.falha) color = '#d32f2f';
    const isTarget = p.id === currentStop().id;
    if (isTarget && !p.entregue) color = '#ff6b00';

    const icon = L.divIcon({
      className: '',
      html: `<div style="
        width:${p.comercial ? 26 : 28}px;height:${p.comercial ? 26 : 28}px;
        background:${color};border:2px solid #fff;border-radius:${p.comercial ? 6 : 50}%;
        display:flex;align-items:center;justify-content:center;
        font-weight:800;font-size:11px;color:#fff;
        box-shadow:0 2px 6px rgba(0,0,0,.5);
      ">${p.ordem}</div>`,
      iconSize: [28, 28],
      iconAnchor: [14, 14],
    });
    const m = L.marker([p.lat, p.lng], { icon }).addTo(mapInstance);
    markersLayer.push(m);
  });

  if (state.isPro) {
    const pts = state.paradas.map((p) => [p.lat, p.lng]);
    routeLine = L.polyline(pts, {
      color: '#ff6b00',
      weight: 6,
      opacity: 0.55,
    }).addTo(mapInstance);
  }

  setTimeout(() => mapInstance?.invalidateSize(), 120);
}

function renderPlanMap() {
  const el = document.createElement('div');
  el.className = 'screen';
  el.innerHTML = `
    <div class="map-wrap">
      <div id="map-plan" class="map-leaflet"></div>
      <div class="top-bar">
        <button class="icon-btn" data-go="hub">←</button>
        <span style="font-size:12px;font-weight:600">${state.isPro ? 'Rota otimizada PRO' : 'Ordem da planilha'}</span>
        <span class="badge">${pendingCount()} pendentes</span>
      </div>
    </div>
    <div class="sheet">
      <div class="sheet-handle"></div>
      <h3 style="font-size:15px">${DEMO_ROUTE.titulo}</h3>
      <p style="color:var(--muted);font-size:12px;margin:0 0 12px">
        ${state.isPro ? 'Linha laranja OSRM · km/tempo estimados' : 'Ative PRO para traçado laranja e otimização'}
      </p>
      ${state.isPro ? '' : '<button class="btn btn-orange" data-go="license">Otimizar rota (PRO)</button>'}
      <button class="btn btn-green" style="margin-top:8px" data-go="delivery">Iniciar entrega</button>
    </div>
  `;
  bindNav(el);
  app.appendChild(el);
  requestAnimationFrame(() => initMap('map-plan'));
}

function renderDelivery() {
  const cur = currentStop();
  const el = document.createElement('div');
  el.className = 'screen';
  const listHtml = state.paradas
    .map(
      (p) => `
    <div class="list-item">
      <div class="pin-num ${p.entregue ? 'done' : p.falha ? 'fail' : ''}">${p.ordem}</div>
      <div>
        <div style="font-size:13px;font-weight:600">${p.address}</div>
        <div style="font-size:11px;color:var(--muted)">Parada ${p.stop}</div>
      </div>
    </div>`
    )
    .join('');

  el.innerHTML = `
    <div class="top-bar" style="position:relative;background:var(--sheet);z-index:1">
      <button class="icon-btn" data-go="hub">☰</button>
      <div class="toggle-map-list">
        <button class="${state.mapTab === 'mapa' ? 'active' : ''}" data-tab="mapa">Mapa</button>
        <button class="${state.mapTab === 'lista' ? 'active' : ''}" data-tab="lista">Lista</button>
      </div>
      <span class="badge">${doneCount()} de ${DEMO_ROUTE.totalPacotes} feitas</span>
    </div>
    <div class="map-wrap" style="display:${state.mapTab === 'mapa' ? 'block' : 'none'}">
      <div id="map-delivery" class="map-leaflet"></div>
    </div>
    <div class="scroll-body" style="display:${state.mapTab === 'lista' ? 'block' : 'none'};max-height:45%">
      ${listHtml}
    </div>
    <div class="sheet">
      <div class="sheet-handle"></div>
      <p style="color:var(--orange);font-size:10px;font-weight:800">PRÓXIMA PARADA</p>
      <h3 style="font-size:16px">Pacote ${cur.ordem} · ${cur.address}</h3>
      <button class="btn btn-orange" style="margin-top:10px">Abrir GPS</button>
      <div class="row-btns">
        <button class="btn" style="background:#222;color:#fff" data-fail>Falhou</button>
        <button class="btn btn-green" data-deliver>Entreguei</button>
      </div>
    </div>
  `;

  el.querySelectorAll('[data-tab]').forEach((btn) => {
    btn.addEventListener('click', () => {
      state.mapTab = btn.dataset.tab;
      render();
    });
  });
  el.querySelector('[data-deliver]')?.addEventListener('click', () => {
    const p = state.paradas.find((x) => x.id === cur.id);
    if (p) {
      p.entregue = true;
      saveState(state);
      showToast(`Pacote ${p.ordem} entregue`);
      render();
    }
  });
  el.querySelector('[data-fail]')?.addEventListener('click', () => {
    const p = state.paradas.find((x) => x.id === cur.id);
    if (p) {
      p.falha = true;
      saveState(state);
      showToast('Marcado como não entregue');
      render();
    }
  });
  bindNav(el);
  app.appendChild(el);
  if (state.mapTab === 'mapa') {
    requestAnimationFrame(() => initMap('map-delivery'));
  }
}

function renderSettings() {
  const el = document.createElement('div');
  el.className = 'screen';
  el.innerHTML = `
    <div class="top-bar" style="position:relative;background:var(--sheet)">
      <button class="icon-btn" data-go="hub">←</button>
      <span style="font-weight:700">Configurações</span>
    </div>
    <div class="scroll-body">
      <p class="label">ID do aparelho (demo PC)</p>
      <input class="field" readonly id="device-id" value="${DEMO_DEVICE_ID}" />
      <button class="btn btn-outline" id="copy-id">Copiar ID</button>
      <div class="card" style="margin-top:16px" data-go="license">
        <div class="card-title">Licença PRO</div>
        <div class="card-meta">${state.isPro ? 'Ativo · Demonstracao Video' : 'Não ativado'}</div>
      </div>
      <div class="card" data-go="compare">
        <div class="card-title">Comparar planos</div>
      </div>
      <button class="btn" style="margin-top:16px;background:#333;color:#fff" id="reset-demo">Resetar demo</button>
    </div>
  `;
  el.querySelector('#copy-id').addEventListener('click', async () => {
    await navigator.clipboard.writeText(DEMO_DEVICE_ID);
    showToast('ID copiado');
  });
  el.querySelector('#reset-demo').addEventListener('click', () => {
    state = defaultState();
    saveState(state);
    showToast('Demo resetada');
    setScreen('splash');
  });
  bindNav(el);
  app.appendChild(el);
}

function renderLicense() {
  const el = document.createElement('div');
  el.className = 'screen';
  el.innerHTML = `
    <div class="top-bar" style="position:relative;background:var(--sheet)">
      <button class="icon-btn" data-go="settings">←</button>
      <span style="font-weight:700">Ativar PRO</span>
    </div>
    <div class="scroll-body">
      <p style="color:var(--muted);font-size:13px;line-height:1.45">
        No APK real: Configurações → ID do aparelho → envie à DEV ALN.
        Neste simulador use o ID e a licença demo abaixo.
      </p>
      <p class="label">ID deste simulador</p>
      <input class="field" readonly value="${DEMO_DEVICE_ID}" />
      <p class="label">Cole a licença PRO</p>
      <textarea class="field" id="lic-input" rows="4" placeholder="Cole a chave…"></textarea>
      <button class="btn btn-orange" id="act-lic">Ativar</button>
      <button class="btn btn-outline" id="paste-demo" style="margin-top:8px">Colar licença demo</button>
    </div>
  `;
  el.querySelector('#paste-demo').addEventListener('click', () => {
    el.querySelector('#lic-input').value = DEMO_LICENSE_TOKEN;
  });
  el.querySelector('#act-lic').addEventListener('click', () => {
    const v = el.querySelector('#lic-input').value;
    if (validateLicense(v)) {
      state.isPro = true;
      saveState(state);
      showToast('PRO ativado neste aparelho!');
      setTimeout(() => setScreen('compare'), 800);
    } else {
      showToast('Licença inválida para este ID demo');
    }
  });
  bindNav(el);
  app.appendChild(el);
}

function renderCompare() {
  const rows = [
    ['Importar planilha XLSX', 1, 1],
    ['Mapa, paradas, Entregue / Não entregue', 1, 1],
    ['Ordem igual ao romaneio', 1, 1],
    ['Parada manual + CEP', 1, 1],
    ['Traçado laranja (ruas)', 0, 1],
    ['Otimização OSRM', 0, 1],
    ['Km e tempo estimados', 0, 1],
    ['Controle de gastos / lucro', 0, 1],
  ];
  const table = rows
    .map(
      ([name, free, pro]) => `
    <tr>
      <td style="text-align:left">${name}</td>
      <td>${free ? '<span class="check">✓</span>' : '<span class="cross">—</span>'}</td>
      <td>${pro ? '<span class="check">✓</span>' : '<span class="cross">—</span>'}</td>
    </tr>`
    )
    .join('');

  const el = document.createElement('div');
  el.className = 'screen';
  el.innerHTML = `
    <div class="top-bar" style="position:relative;background:var(--sheet)">
      <button class="icon-btn" data-go="hub">←</button>
      <span style="font-weight:700">Planos</span>
    </div>
    <div class="scroll-body">
      <p style="font-size:13px;color:var(--muted);line-height:1.45">
        Grátis: importa, mapa e registra entregas. PRO: rota pelas ruas, linha laranja e financeiro.
      </p>
      <table class="compare-table" style="margin-top:12px">
        <tr><th>Recurso</th><th>Grátis</th><th>PRO</th></tr>
        ${table}
      </table>
      ${state.isPro ? '<p style="color:var(--green);margin-top:16px;font-weight:700">✓ PRO ativo nesta demo</p>' : '<button class="btn btn-orange" style="margin-top:16px" data-go="license">Ativar PRO</button>'}
    </div>
  `;
  bindNav(el);
  app.appendChild(el);
}

document.addEventListener('keydown', (e) => {
  const map = { '1': 'hub', '2': 'plan', '3': 'delivery', '4': 'license', '5': 'compare' };
  if (map[e.key]) setScreen(map[e.key]);
});

if (state.screen === 'splash') {
  render();
} else {
  render();
}
