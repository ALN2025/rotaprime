# Painel ROTA PRIME (Google Apps Script)

Um script só: **registro automático de trial** (app) + **painel para você** (revogar PRO, ver IDs).

## 1. Atualizar o código no Google

1. Abra [script.google.com](https://script.google.com) → projeto **rota prime trial**.
2. Apague todo o `Código.gs`.
3. Copie **tudo** de `license/apps_script_device_policy.gs` (pasta do projeto no PC).
4. Salve (Ctrl+S).

Propriedades do script (já configuradas):

| Propriedade       | Uso                          |
|-------------------|------------------------------|
| `GITHUB_TOKEN`    | Token GitHub (Contents R/W)  |
| `REGISTER_SECRET` | Senha (igual ao app Flutter) |

## 2. Nova implantação (importante)

**Implantar** → **Gerenciar implantações** → lápis na Web App → **Nova versão** → **Implantar**.

(A URL `/exec` pode continuar a mesma.)

## 3. Abrir o painel no celular ou PC

No navegador (Chrome):

```
https://script.google.com/macros/s/SEU_ID/exec?key=SUA_REGISTER_SECRET
```

Use a **mesma senha** do `REGISTER_SECRET` (ex.: a que está no Flutter em `kTrialRegisterSecret`).

**Salve nos favoritos** — só você deve ter esse link.

### No painel você pode

- Ver **trial já usados** (IDs que não ganham trial de novo).
- Ver **PRO revogados** (reembolso / mau uso).
- Colar um ID e clicar **Revogar PRO** ou **Marcar trial já usado**.
- **Restaurar PRO** / **Liberar trial** em cada linha da lista.

O app lê:  
https://github.com/ALN2025/rotaprime/blob/main/license/revoked_devices.json

## 4. App Flutter

Nada muda: `kTrialRegisterUrl` continua a URL `/exec` (POST do trial).

## Segurança

- Quem não souber `?key=...` não entra no painel.
- Mesmo assim, não compartilhe o link completo publicamente.
