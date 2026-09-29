/**
 * ROTA PRIME — política de aparelhos no GitHub (trial + revogação + PRO mensal).
 *
 * Propriedades do script (Configurações do projeto → Propriedades do script):
 *   GITHUB_TOKEN      — token GitHub (repo ALN2025/rotaprime)
 *   REGISTER_SECRET   — mesma senha do app Flutter (trial POST + painel ?key=)
 *   MP_WEBHOOK_SECRET — senha só para Mercado Pago / POST extend_pro (NÃO é REGISTER_SECRET)
 *
 * Implantar → App da Web → Qualquer pessoa → Nova versão após cada alteração.
 *
 * POST /exec (JSON):
 *   Trial app: { "register_secret": "...", "device_id": "..." }
 *   MP / cron: { "action": "extend_pro", "webhook_secret": "...", "device_id": "...", "days": 31 }
 *
 * Webhook Mercado Pago (URL com mp_key = MP_WEBHOOK_SECRET):
 *   .../exec?mp_key=SUA_MP_WEBHOOK_SECRET
 *   Requer MP_ACCESS_TOKEN no script. Notificações: pagamento aprovado / assinatura authorized.
 *
 * Painel admin:
 *   https://script.google.com/macros/s/SEU_ID/exec?key=SUA_REGISTER_SECRET
 */

var REPO_OWNER = 'ALN2025';
var REPO_NAME = 'rotaprime';
var FILE_PATH = 'license/revoked_devices.json';

/** App Flutter — registrar trial usado */
function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
    var action = String(body.action || 'register_trial');

    var mpHandled = tryHandleMercadoPagoWebhook_(e, body);
    if (mpHandled !== null) {
      return jsonOut(mpHandled);
    }

    if (action === 'register_licensed_pro') {
      if (!checkAdminKey_(body.register_secret)) {
        return jsonOut({ ok: false, error: 'unauthorized' });
      }
      var deviceIdLic = normalizeId_(body.device_id);
      if (!deviceIdLic) {
        return jsonOut({ ok: false, error: 'missing device_id' });
      }
      var buyer = String(body.buyer || body.buyer_name || '').trim();
      registerLicensedPro_(deviceIdLic, buyer, 'app');
      return jsonOut({ ok: true, device_id: deviceIdLic });
    }

    if (action === 'extend_pro') {
      if (!checkMpWebhookSecret_(body.webhook_secret)) {
        return jsonOut({ ok: false, error: 'unauthorized' });
      }
      var deviceIdPay = normalizeId_(body.device_id);
      if (!deviceIdPay) {
        return jsonOut({ ok: false, error: 'missing device_id' });
      }
      var days = parseInt(body.days, 10);
      if (!days || days < 1) days = 31;
      var untilIso = extendProUntil_(deviceIdPay, days);
      return jsonOut({ ok: true, device_id: deviceIdPay, pro_until: untilIso });
    }

    if (!checkAdminKey_(body.register_secret)) {
      return jsonOut({ ok: false, error: 'unauthorized' });
    }
    var deviceId = normalizeId_(body.device_id);
    if (!deviceId) {
      return jsonOut({ ok: false, error: 'missing device_id' });
    }
    withPolicyDoc_(function (doc) {
      ensureArrays_(doc);
      if (doc.trial_used_device_ids.indexOf(deviceId) < 0) {
        doc.trial_used_device_ids.push(deviceId);
        doc.trial_used_device_ids.sort();
      }
    }, 'trial: register device ' + deviceId);
    return jsonOut({ ok: true, device_id: deviceId });
  } catch (err) {
    return jsonOut({ ok: false, error: String(err) });
  }
}

/** Painel admin no navegador */
function doGet(e) {
  var mpKey = (e && e.parameter && e.parameter.mp_key) || '';
  if (mpKey) {
    if (checkMpWebhookSecret_(mpKey)) {
      return ContentService.createTextOutput(
        'ROTA PRIME webhook OK. Mercado Pago deve enviar POST nesta URL (mp_key correto). ' +
          'Painel admin: use ?key=REGISTER_SECRET (nao mp_key).'
      ).setMimeType(ContentService.MimeType.TEXT);
    }
    return ContentService.createTextOutput(
      'mp_key incorreto. Use o mesmo valor de MP_WEBHOOK_SECRET no Apps Script.'
    ).setMimeType(ContentService.MimeType.TEXT);
  }
  var key = (e && e.parameter && e.parameter.key) || '';
  if (!checkAdminKey_(key)) {
    return HtmlService.createHtmlOutput(
      '<body style="font-family:sans-serif;background:#111;color:#eee;padding:24px">' +
        '<h2>ROTA PRIME — acesso negado</h2>' +
        '<p>Painel: <code>?key=</code> + <b>REGISTER_SECRET</b>.</p>' +
        '<p>Webhook Mercado Pago: mesma URL com <code>?mp_key=</code> + <b>MP_WEBHOOK_SECRET</b> (POST).</p>' +
        '</body>'
    );
  }
  return HtmlService.createHtmlOutput(buildAdminHtml_(key))
    .setTitle('ROTA PRIME — Aparelhos')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

/** Exibição pt-BR (horário de Brasília). */
function formatProUntilBr_(iso) {
  if (!iso) return '-';
  var d = new Date(iso);
  if (isNaN(d.getTime())) return String(iso);
  return Utilities.formatDate(d, 'America/Sao_Paulo', 'dd/MM/yyyy HH:mm');
}

function buildProUntilBrMap_(proUntil) {
  var out = {};
  var pu = proUntil || {};
  for (var id in pu) {
    if (Object.prototype.hasOwnProperty.call(pu, id)) {
      out[id] = formatProUntilBr_(pu[id]);
    }
  }
  return out;
}

// --- API chamada pelo painel (google.script.run) ---

function apiLoadPolicy(adminKey) {
  assertAdmin_(adminKey);
  var doc = readPolicyDoc_();
  ensureArrays_(doc);
  var proUntil = doc.pro_until || {};
  var licensed = doc.licensed_pro_devices || {};
  return {
    trial_used_device_ids: doc.trial_used_device_ids,
    revoked_device_ids: doc.revoked_device_ids,
    licensed_pro_devices: licensed,
    pro_until: proUntil,
    pro_until_br: buildProUntilBrMap_(proUntil),
    github_file: REPO_OWNER + '/' + REPO_NAME + '/' + FILE_PATH,
  };
}

/** Registra aparelho com PRO por chave (painel / app após ativar). */
function registerLicensedPro_(deviceId, buyer, source) {
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    if (!doc.licensed_pro_devices[deviceId]) {
      doc.licensed_pro_devices[deviceId] = {};
    }
    var entry = doc.licensed_pro_devices[deviceId];
    if (buyer) entry.buyer = buyer;
    if (source) entry.source = source;
    entry.registered_at = new Date().toISOString();
    var revoked = doc.revoked_device_ids.indexOf(deviceId) >= 0;
    if (revoked) entry.revoked = true;
    else delete entry.revoked;
  }, 'licensed PRO register ' + deviceId);
}

function apiRegisterLicensedPro(adminKey, deviceIdRaw, buyerRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  var buyer = String(buyerRaw || '').trim();
  registerLicensedPro_(deviceId, buyer, 'admin');
  return { ok: true, device_id: deviceId };
}

function apiRemoveLicensedProFromList(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    if (doc.licensed_pro_devices[deviceId]) {
      delete doc.licensed_pro_devices[deviceId];
    }
  }, 'admin: remove licensed PRO from list ' + deviceId);
  return { ok: true, device_id: deviceId };
}

function apiRevokePro(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    if (doc.revoked_device_ids.indexOf(deviceId) < 0) {
      doc.revoked_device_ids.push(deviceId);
      doc.revoked_device_ids.sort();
    }
    if (!doc.licensed_pro_devices[deviceId]) {
      doc.licensed_pro_devices[deviceId] = {};
    }
    doc.licensed_pro_devices[deviceId].revoked = true;
    doc.licensed_pro_devices[deviceId].revoked_at = new Date().toISOString();
  }, 'admin: revoke PRO ' + deviceId);
  return { ok: true, device_id: deviceId };
}

function apiUnrevokePro(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    doc.revoked_device_ids = doc.revoked_device_ids.filter(function (id) {
      return id !== deviceId;
    });
    if (doc.licensed_pro_devices[deviceId]) {
      delete doc.licensed_pro_devices[deviceId].revoked;
      delete doc.licensed_pro_devices[deviceId].revoked_at;
    }
  }, 'admin: unrevoke PRO ' + deviceId);
  return { ok: true, device_id: deviceId };
}

/** Remove PRO mensal (Mercado Pago / +31 dias) — apaga entrada em pro_until. */
function apiClearProMonthly(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    if (doc.pro_until[deviceId]) {
      delete doc.pro_until[deviceId];
    }
  }, 'admin: clear PRO mensal ' + deviceId);
  return { ok: true, device_id: deviceId };
}

function apiMarkTrialUsed(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    if (doc.trial_used_device_ids.indexOf(deviceId) < 0) {
      doc.trial_used_device_ids.push(deviceId);
      doc.trial_used_device_ids.sort();
    }
  }, 'admin: mark trial used ' + deviceId);
  return { ok: true, device_id: deviceId };
}

function apiClearTrialUsed(adminKey, deviceIdRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    doc.trial_used_device_ids = doc.trial_used_device_ids.filter(function (id) {
      return id !== deviceId;
    });
  }, 'admin: clear trial used ' + deviceId);
  return { ok: true, device_id: deviceId };
}

// --- GitHub ---

function withPolicyDoc_(mutator, commitMessage) {
  var token = getGithubToken_();
  var meta = githubGetFileMeta_(token);
  var doc = JSON.parse(meta.content);
  ensureArrays_(doc);
  mutator(doc);
  delete doc._comment;
  var newContent = JSON.stringify(doc, null, 2) + '\n';
  githubPutFile_(token, meta.sha, newContent, commitMessage);
}

function readPolicyDoc_() {
  var token = getGithubToken_();
  var meta = githubGetFileMeta_(token);
  return JSON.parse(meta.content);
}

function ensureArrays_(doc) {
  if (!doc.revoked_device_ids) doc.revoked_device_ids = [];
  if (!doc.trial_used_device_ids) doc.trial_used_device_ids = [];
  if (!doc.pro_until) doc.pro_until = {};
  if (!doc.licensed_pro_devices) doc.licensed_pro_devices = {};
}

function checkMpWebhookSecret_(key) {
  var secret = PropertiesService.getScriptProperties().getProperty('MP_WEBHOOK_SECRET');
  return secret && String(key) === String(secret);
}

function checkMpUrlKey_(e) {
  var key = (e && e.parameter && e.parameter.mp_key) || '';
  return checkMpWebhookSecret_(key);
}

function mpGetJson_(url, token) {
  var res = UrlFetchApp.fetch(url, {
    method: 'get',
    headers: { Authorization: 'Bearer ' + token },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) {
    throw new Error('MP API ' + res.getResponseCode() + ' ' + res.getContentText());
  }
  return JSON.parse(res.getContentText());
}

/** ID do aparelho a partir de pagamento ou assinatura MP. */
function mpResolveDeviceId_(payOrPre, token, isPreapproval) {
  if (!payOrPre) return null;
  var deviceId = payOrPre.external_reference;
  if (deviceId) return deviceId;
  var meta = payOrPre.metadata;
  if (meta && meta.device_id) return meta.device_id;
  if (!isPreapproval && payOrPre.preapproval_id) {
    var pre = mpGetJson_(
      'https://api.mercadopago.com/preapproval/' + payOrPre.preapproval_id,
      token
    );
    return mpResolveDeviceId_(pre, token, true);
  }
  return null;
}

function mpPreapprovalIsPaid_(status) {
  var s = String(status || '').toLowerCase();
  return s === 'authorized' || s === 'active';
}

/**
 * Notificação Mercado Pago → consulta API → external_reference = device_id → +31 dias.
 * Retorna null se o POST não for webhook MP.
 */
function tryHandleMercadoPagoWebhook_(e, body) {
  var type = String(body.type || body.topic || body.action || '').toLowerCase();
  var hasMpShape = type.length > 0 || body.resource || (body.data && body.data.id);
  if (!hasMpShape) return null;
  if (!checkMpUrlKey_(e)) {
    return { ok: false, error: 'unauthorized' };
  }
  var token = PropertiesService.getScriptProperties().getProperty('MP_ACCESS_TOKEN');
  if (!token) {
    return { ok: false, error: 'Configure MP_ACCESS_TOKEN nas propriedades do script' };
  }
  var id = body.data && body.data.id;
  if (!id && body.resource) {
    var resStr = String(body.resource);
    var mPre = resStr.match(/\/preapproval\/([^/?]+)/i);
    var mPay = resStr.match(/\/payments\/([^/?]+)/i);
    if (mPre) id = mPre[1];
    else if (mPay) id = mPay[1];
  }
  if (!id) return { ok: false, error: 'missing mp resource id' };

  var deviceId = null;
  var extend = false;
  var mpStatus = '';

  if (type.indexOf('preapproval') >= 0 || type.indexOf('subscription') >= 0) {
    var pre = mpGetJson_('https://api.mercadopago.com/preapproval/' + id, token);
    deviceId = mpResolveDeviceId_(pre, token, true);
    mpStatus = pre.status;
    extend = mpPreapprovalIsPaid_(pre.status);
  } else if (type.indexOf('payment') >= 0 || type.indexOf('authorized_payment') >= 0) {
    var pay = mpGetJson_('https://api.mercadopago.com/v1/payments/' + id, token);
    deviceId = mpResolveDeviceId_(pay, token, false);
    mpStatus = pay.status;
    extend = pay.status === 'approved';
  } else {
    return { ok: true, ignored: true, type: type };
  }

  deviceId = normalizeId_(deviceId);
  if (!deviceId) {
    return { ok: false, error: 'missing external_reference no Mercado Pago (use link do app com ID)' };
  }
  if (!extend) {
    return { ok: true, skipped: true, device_id: deviceId, mp_status: mpStatus || 'not_paid_yet' };
  }
  var untilIso = extendProUntil_(deviceId, 31);
  return {
    ok: true,
    source: 'mercadopago',
    device_id: deviceId,
    pro_until: untilIso,
    pro_until_br: formatProUntilBr_(untilIso),
  };
}

/** Soma [days] a partir de max(hoje, pro_until atual). Retorna ISO UTC. */
function extendProUntil_(deviceId, days) {
  var untilIso = '';
  withPolicyDoc_(function (doc) {
    ensureArrays_(doc);
    var now = new Date();
    var base = now;
    var prev = doc.pro_until[deviceId];
    if (prev) {
      var prevDate = new Date(prev);
      if (!isNaN(prevDate.getTime()) && prevDate > base) {
        base = prevDate;
      }
    }
    var until = new Date(base.getTime());
    until.setUTCDate(until.getUTCDate() + days);
    untilIso = until.toISOString();
    doc.pro_until[deviceId] = untilIso;
  }, 'mp: extend PRO ' + deviceId + ' +' + days + 'd');
  return untilIso;
}

function apiExtendProDays(adminKey, deviceIdRaw, daysRaw) {
  assertAdmin_(adminKey);
  var deviceId = normalizeId_(deviceIdRaw);
  if (!deviceId) throw new Error('ID inválido');
  var days = parseInt(daysRaw, 10);
  if (!days || days < 1) days = 31;
  var untilIso = extendProUntil_(deviceId, days);
  return {
    ok: true,
    device_id: deviceId,
    pro_until: untilIso,
    pro_until_br: formatProUntilBr_(untilIso),
  };
}

function getGithubToken_() {
  var token = PropertiesService.getScriptProperties().getProperty('GITHUB_TOKEN');
  if (!token) throw new Error('Configure GITHUB_TOKEN nas propriedades do script');
  return token;
}

function checkAdminKey_(key) {
  var secret = PropertiesService.getScriptProperties().getProperty('REGISTER_SECRET');
  return secret && String(key) === String(secret);
}

function assertAdmin_(adminKey) {
  if (!checkAdminKey_(adminKey)) throw new Error('Não autorizado');
}

function normalizeId_(raw) {
  return String(raw || '')
    .trim()
    .toLowerCase();
}

function githubGetFileMeta_(token) {
  var url =
    'https://api.github.com/repos/' + REPO_OWNER + '/' + REPO_NAME + '/contents/' + FILE_PATH;
  var res = UrlFetchApp.fetch(url, {
    method: 'get',
    headers: {
      Authorization: 'Bearer ' + token,
      Accept: 'application/vnd.github+json',
    },
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) {
    throw new Error('GitHub GET failed: ' + res.getResponseCode() + ' ' + res.getContentText());
  }
  var json = JSON.parse(res.getContentText());
  var decoded = Utilities.newBlob(Utilities.base64Decode(json.content)).getDataAsString();
  return { sha: json.sha, content: decoded };
}

function githubPutFile_(token, sha, content, message) {
  var url =
    'https://api.github.com/repos/' + REPO_OWNER + '/' + REPO_NAME + '/contents/' + FILE_PATH;
  var payload = {
    message: message,
    content: Utilities.base64Encode(content),
    sha: sha,
  };
  var res = UrlFetchApp.fetch(url, {
    method: 'put',
    headers: {
      Authorization: 'Bearer ' + token,
      Accept: 'application/vnd.github+json',
    },
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });
  if (res.getResponseCode() !== 200) {
    throw new Error('GitHub PUT failed: ' + res.getResponseCode() + ' ' + res.getContentText());
  }
}

function jsonOut(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON
  );
}

function buildAdminHtml_(adminKey) {
  var keyJson = JSON.stringify(String(adminKey));
  return (
    '<!DOCTYPE html><html><head><meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1">' +
    '<title>ROTA PRIME Admin</title>' +
    '<style>' +
    'body{font-family:system-ui,sans-serif;background:#0f1115;color:#e8eaed;margin:0;padding:16px;max-width:720px}' +
    'h1{font-size:1.25rem;color:#ff6b00}h2{font-size:1rem;margin-top:24px;color:#aaa}' +
    'input,button,select{font-size:14px;padding:10px;border-radius:8px;border:1px solid #333}' +
    'input{width:100%;box-sizing:border-box;background:#1a1d24;color:#fff;margin:8px 0}' +
    'button{background:#ff6b00;color:#111;border:none;font-weight:700;cursor:pointer;margin:4px 4px 4px 0}' +
    'button.secondary{background:#333;color:#eee}button.danger{background:#b91c1c;color:#fff}' +
    'ul{list-style:none;padding:0}li{background:#1a1d24;margin:6px 0;padding:10px 12px;border-radius:8px;' +
    'font-family:monospace;font-size:12px;word-break:break-all;display:flex;justify-content:space-between;align-items:center;gap:8px}' +
    '.msg{padding:10px;border-radius:8px;margin:12px 0;background:#1e3a2f;color:#6ee7b7}' +
    '.err{background:#3f1d1d;color:#fca5a5}.hint{color:#888;font-size:12px;line-height:1.4}' +
    '</style></head><body>' +
    '<h1>ROTA PRIME — Aparelhos</h1>' +
    '<p class="hint">GitHub <code>license/revoked_devices.json</code>. App sincroniza em ~90 s. ' +
    '<b>pro_until</b> = PRO mensal. <b>licensed_pro_devices</b> = PRO vitalício (chave). ' +
    'O app registra ao ativar o código; ou use <b>Registrar PRO vitalício</b>. ' +
    '<b>Revogar PRO vitalício</b> = revoked_device_ids (app perde PRO em ~90 s).</p>' +
    '<div id="msg"></div>' +
    '<h2>Adicionar ID manualmente</h2>' +
    '<input id="deviceId" placeholder="Cole o ID do aparelho (Configurações no app)" />' +
    '<button onclick="actExtendPro()">+31 dias PRO mensal</button>' +
    '<button onclick="actRegisterLicensed()">Registrar PRO vitalício (lista)</button>' +
    '<button onclick="actRevoke()">Revogar PRO vitalício (chave)</button>' +
    '<button class="danger" onclick="actClearProMonthly()">Remover PRO mensal</button>' +
    '<button onclick="actTrial()">Marcar trial já usado</button>' +
    '<button class="secondary" onclick="load()">Atualizar listas</button>' +
    '<h2>PRO mensal — pro_until (<span id="nProUntil">0</span>)</h2>' +
    '<ul id="listProUntil"></ul>' +
    '<h2>PRO vitalício — chave (<span id="nLicensed">0</span>)</h2>' +
    '<ul id="listLicensed"></ul>' +
    '<h2>Trial já usados (<span id="nTrial">0</span>)</h2>' +
    '<ul id="listTrial"></ul>' +
    '<h2>PRO revogados (<span id="nRevoked">0</span>)</h2>' +
    '<ul id="listRevoked"></ul>' +
    '<script>var ADMIN_KEY=' +
    keyJson +
    ';' +
    'function show(t,err){var el=document.getElementById("msg");el.className=err?"err":"msg";el.textContent=t;}' +
    'function load(){show("Carregando...");google.script.run.withSuccessHandler(function(d){try{' +
    'document.getElementById("nTrial").textContent=d.trial_used_device_ids.length;' +
    'document.getElementById("nRevoked").textContent=d.revoked_device_ids.length;' +
    'var revokedSet={};(d.revoked_device_ids||[]).forEach(function(x){revokedSet[x]=true;});' +
    'var lic=d.licensed_pro_devices||{};var licIds=Object.keys(lic).sort();' +
    'var licActive=licIds.filter(function(id){return !revokedSet[id];});' +
    'document.getElementById("nLicensed").textContent=licActive.length;' +
    'renderLicensed(licIds,lic,revokedSet);' +
    'var puBr=d.pro_until_br||{};var pu=d.pro_until||{};' +
    'var ids=Object.keys(pu).length?Object.keys(pu).sort():Object.keys(puBr).sort();' +
    'document.getElementById("nProUntil").textContent=ids.length;' +
    'renderProUntil(ids,puBr,pu);' +
    'renderList("listTrial",d.trial_used_device_ids,"trial");' +
    'renderList("listRevoked",d.revoked_device_ids,"revoke");' +
    'show("Atualizado - "+d.github_file);}catch(err){show(String(err),true);}})' +
    '.withFailureHandler(function(e){show(e.message||String(e),true);}).apiLoadPolicy(ADMIN_KEY);}' +
    'function renderLicensed(ids,lic,revokedSet){var ul=document.getElementById("listLicensed");ul.innerHTML="";' +
    'if(!ids.length){ul.innerHTML="<li class=\\"hint\\">Nenhum — ative chave no app (7 toques em Versao) ou Registrar PRO vitalicio</li>";return;}' +
    'ids.forEach(function(id){var meta=lic[id]||{};var li=document.createElement("li");var span=document.createElement("span");' +
    'var who=meta.buyer?(" · "+meta.buyer):"";var st=revokedSet[id]?" [Revogado]":" [Ativo]";' +
    'span.textContent=id+who+st;' +
    'var b=document.createElement("button");b.className="secondary";b.textContent="Remover da lista";' +
    'b.onclick=function(){actRemoveLicensed(id);};li.appendChild(span);li.appendChild(b);ul.appendChild(li);});}' +
    'function renderProUntil(ids,puBr,pu){var ul=document.getElementById("listProUntil");ul.innerHTML="";' +
    'if(!ids.length){ul.innerHTML="<li class=\\"hint\\">Nenhum - use +31 dias ou webhook MP</li>";return;}' +
    'ids.forEach(function(id){var li=document.createElement("li");var span=document.createElement("span");' +
    'var dt=puBr[id]||pu[id]||"-";span.textContent=id+" ate "+dt;' +
    'var b=document.createElement("button");b.className="secondary";b.textContent="Remover mensal";' +
    'b.onclick=function(){actClearProMonthlyId(id);};li.appendChild(span);li.appendChild(b);ul.appendChild(li);});}' +
    'function renderList(ulId,ids,kind){var ul=document.getElementById(ulId);ul.innerHTML="";' +
    'if(!ids.length){ul.innerHTML="<li class=\\"hint\\">Nenhum</li>";return;}' +
    'ids.forEach(function(id){var li=document.createElement("li");var span=document.createElement("span");span.textContent=id;' +
    'var b=document.createElement("button");b.className="secondary";b.textContent=kind==="trial"?"Liberar trial":"Restaurar PRO";' +
    'b.onclick=function(){if(kind==="trial")actClearTrial(id);else actUnrevoke(id);};' +
    'li.appendChild(span);li.appendChild(b);ul.appendChild(li);});}' +
    'function idVal(){return document.getElementById("deviceId").value;}' +
    'function actRegisterLicensed(){var id=idVal();if(!id){show("Cole o ID do aparelho",true);return;}' +
    'google.script.run.withSuccessHandler(function(){show("PRO vitalicio registrado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiRegisterLicensedPro(ADMIN_KEY,id,"");}' +
    'function actRemoveLicensed(id){google.script.run.withSuccessHandler(function(){show("Removido da lista: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiRemoveLicensedProFromList(ADMIN_KEY,id);}' +
    'function actExtendPro(){var id=idVal();if(!id){show("Cole o ID do aparelho",true);return;}' +
    'google.script.run.withSuccessHandler(function(r){show("PRO até "+(r.pro_until_br||r.pro_until));load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiExtendProDays(ADMIN_KEY,id,31);}' +
    'function actRevoke(){var id=idVal();if(!id){show("Cole o ID do aparelho",true);return;}' +
    'google.script.run.withSuccessHandler(function(){show("PRO vitalicio revogado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiRevokePro(ADMIN_KEY,id);}' +
    'function actClearProMonthly(){var id=idVal();if(!id){show("Cole o ID do aparelho",true);return;}' +
    'actClearProMonthlyId(id);}' +
    'function actClearProMonthlyId(id){google.script.run.withSuccessHandler(function(){show("PRO mensal removido: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiClearProMonthly(ADMIN_KEY,id);}' +
    'function actTrial(){var id=idVal();google.script.run.withSuccessHandler(function(){show("Trial marcado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiMarkTrialUsed(ADMIN_KEY,id);}' +
    'function actUnrevoke(id){google.script.run.withSuccessHandler(function(){show("PRO restaurado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiUnrevokePro(ADMIN_KEY,id);}' +
    'function actClearTrial(id){google.script.run.withSuccessHandler(function(){show("Trial liberado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiClearTrialUsed(ADMIN_KEY,id);}' +
    'load();</script></body></html>'
  );
}
