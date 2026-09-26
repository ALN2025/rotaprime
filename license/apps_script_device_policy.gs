/**
 * ROTA PRIME — política de aparelhos no GitHub (trial + revogação PRO).
 *
 * Propriedades do script: GITHUB_TOKEN, REGISTER_SECRET (mesma senha do app Flutter).
 * Implantar → App da Web → Qualquer pessoa.
 *
 * App Android: POST doPost (registra trial) — mesma URL /exec.
 * Você (admin): abra no navegador:
 *   https://script.google.com/macros/s/SEU_ID/exec?key=SUA_REGISTER_SECRET
 */

var REPO_OWNER = 'ALN2025';
var REPO_NAME = 'rotaprime';
var FILE_PATH = 'license/revoked_devices.json';

/** App Flutter — registrar trial usado */
function doPost(e) {
  try {
    var body = JSON.parse(e.postData.contents);
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
  var key = (e && e.parameter && e.parameter.key) || '';
  if (!checkAdminKey_(key)) {
    return HtmlService.createHtmlOutput(
      '<body style="font-family:sans-serif;background:#111;color:#eee;padding:24px">' +
        '<h2>ROTA PRIME — acesso negado</h2>' +
        '<p>Abra esta URL com <code>?key=</code> + a mesma senha de <b>REGISTER_SECRET</b> (Apps Script).</p>' +
        '<p>Ex.: <code>.../exec?key=SUA_SENHA</code></p>' +
        '</body>'
    );
  }
  return HtmlService.createHtmlOutput(buildAdminHtml_(key))
    .setTitle('ROTA PRIME — Aparelhos')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

// --- API chamada pelo painel (google.script.run) ---

function apiLoadPolicy(adminKey) {
  assertAdmin_(adminKey);
  var doc = readPolicyDoc_();
  ensureArrays_(doc);
  return {
    trial_used_device_ids: doc.trial_used_device_ids,
    revoked_device_ids: doc.revoked_device_ids,
    github_file: REPO_OWNER + '/' + REPO_NAME + '/' + FILE_PATH,
  };
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
  }, 'admin: unrevoke PRO ' + deviceId);
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
    '<p class="hint">Lista vem do GitHub <code>license/revoked_devices.json</code>. ' +
    'O app atualiza em alguns minutos (cache). Trial = sem novo trial ao reinstalar. Revogado = perde PRO licenciado.</p>' +
    '<div id="msg"></div>' +
    '<h2>Adicionar ID manualmente</h2>' +
    '<input id="deviceId" placeholder="Cole o ID do aparelho (Configurações no app)" />' +
    '<button onclick="actRevoke()">Revogar PRO</button>' +
    '<button onclick="actTrial()">Marcar trial já usado</button>' +
    '<button class="secondary" onclick="load()">Atualizar listas</button>' +
    '<h2>Trial já usados (<span id="nTrial">0</span>)</h2>' +
    '<ul id="listTrial"></ul>' +
    '<h2>PRO revogados (<span id="nRevoked">0</span>)</h2>' +
    '<ul id="listRevoked"></ul>' +
    '<script>var ADMIN_KEY=' +
    keyJson +
    ';' +
    'function show(t,err){var el=document.getElementById("msg");el.className=err?"err":"msg";el.textContent=t;}' +
    'function load(){show("Carregando…");google.script.run.withSuccessHandler(function(d){' +
    'document.getElementById("nTrial").textContent=d.trial_used_device_ids.length;' +
    'document.getElementById("nRevoked").textContent=d.revoked_device_ids.length;' +
    'renderList("listTrial",d.trial_used_device_ids,"trial");' +
    'renderList("listRevoked",d.revoked_device_ids,"revoke");' +
    'show("Atualizado · "+d.github_file);}).withFailureHandler(function(e){show(e.message,true);}).apiLoadPolicy(ADMIN_KEY);}' +
    'function renderList(ulId,ids,kind){var ul=document.getElementById(ulId);ul.innerHTML="";' +
    'if(!ids.length){ul.innerHTML="<li class=hint>Nenhum</li>";return;}' +
    'ids.forEach(function(id){var li=document.createElement("li");var span=document.createElement("span");span.textContent=id;' +
    'var b=document.createElement("button");b.className="secondary";b.textContent=kind==="trial"?"Liberar trial":"Restaurar PRO";' +
    'b.onclick=function(){if(kind==="trial")actClearTrial(id);else actUnrevoke(id);};' +
    'li.appendChild(span);li.appendChild(b);ul.appendChild(li);});}' +
    'function idVal(){return document.getElementById("deviceId").value;}' +
    'function actRevoke(){var id=idVal();google.script.run.withSuccessHandler(function(){show("PRO revogado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiRevokePro(ADMIN_KEY,id);}' +
    'function actTrial(){var id=idVal();google.script.run.withSuccessHandler(function(){show("Trial marcado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiMarkTrialUsed(ADMIN_KEY,id);}' +
    'function actUnrevoke(id){google.script.run.withSuccessHandler(function(){show("PRO restaurado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiUnrevokePro(ADMIN_KEY,id);}' +
    'function actClearTrial(id){google.script.run.withSuccessHandler(function(){show("Trial liberado: "+id);load();})' +
    '.withFailureHandler(function(e){show(e.message,true);}).apiClearTrialUsed(ADMIN_KEY,id);}' +
    'load();</script></body></html>'
  );
}
