# Mercado Pago — PRO mensal R$ 30 (cartão + Pix)

O **APK não guarda Access Token** do Mercado Pago. O app só abre o **link de assinatura** com o **ID do aparelho**. Quem estende o PRO é o **webhook → Apps Script → GitHub** (`pro_until`).

## Se o cliente não pagar

- Mercado Pago **não renova** → webhook de aprovação **não** chega → `pro_until` **não** aumenta.
- Quando a data passa, o app volta ao **Grátis** sozinho (sync a cada ~90 s / ao abrir o app).
- Você **não** precisa revogar aparelho por aparelho.

---

## O que você precisa fazer (Mercado Pago)

1. Entrar em [Mercado Pago Developers](https://www.mercadopago.com.br/developers).
2. Criar **duas assinaturas** (ou um plano com cartão + Pix, conforme o painel MP):
   - **Cartão** — recorrente ~R$ 30/mês.
   - **Pix** — assinatura/recorrência Pix (quando disponível na sua conta).
3. Anotar o **`preapproval_plan_id`** (ou URL de checkout) de **cada** plano.
4. Configurar **referência externa** = ID do aparelho (24 caracteres do app).  
   No checkout, o app já envia `external_reference={device_id}` na URL.
5. **Webhook automático** — [Suas integrações → Webhooks](https://www.mercadopago.com.br/developers/panel/app) → URL de produção:

```
https://script.google.com/macros/s/AKfycbzCK6U29h7OoE3eUjE7_tW8P-vaJHyuEmu7wrFPCcDxz8dzB2XfWgCrgwRx2MgJYCBv/exec?mp_key=SUA_MP_WEBHOOK_SECRET
```

   - Eventos: **Pagamentos** (`payment`) e **Assinaturas** (`subscription_preapproval` / preapproval).
   - O script usa `MP_ACCESS_TOKEN` para buscar o pagamento/assinatura na API MP e lê **`external_reference`** (= ID do aparelho que o app já manda na URL de checkout).
   - Cada aprovação / renovação **authorized** soma **+31 dias** em `pro_until` no GitHub.

6. **Access Token de produção** — propriedade `MP_ACCESS_TOKEN` no Apps Script, **nunca** no APK.

7. **Teste manual** (sem MP), POST JSON:

```json
{
  "action": "extend_pro",
  "webhook_secret": "SUA_MP_WEBHOOK_SECRET",
  "device_id": "ID_DO_APARELHO",
  "days": 31
}
```

---

## O que você precisa colocar no projeto (sem mandar segredo no chat)

| Item | Onde |
|------|------|
| URL checkout **cartão** com `{device_id}` | `lib/config/mercadopago_checkout_config.dart` ou `--dart-define=MP_CARD_URL=...` |
| URL checkout **Pix** com `{device_id}` | `lib/config/mercadopago_checkout_config.dart` ou `--dart-define=MP_PIX_URL=...` |
| `MP_WEBHOOK_SECRET` | Apps Script → Propriedades do script |
| `GITHUB_TOKEN`, `REGISTER_SECRET` | Já existem |
| Publicar nova versão do Web App | Implantar → Nova versão |

### Exemplo de URL no app (substitua o ID do plano)

```
https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=SEU_PLANO_CARTAO&external_reference={device_id}
```

---

## O que NÃO enviar pelo WhatsApp/chat

- Access Token Mercado Pago  
- `MP_WEBHOOK_SECRET` / `REGISTER_SECRET`  
- Token GitHub  

Envie só: **IDs dos planos** ou **URLs de checkout** (podem ser públicas) e confirme que o webhook está apontando para o script.

---

## Painel admin (manual)

No painel `.../exec?key=REGISTER_SECRET`, use **apiExtendProDays** (via script) ou POST `extend_pro` após Pix avulso — estende +31 dias no `pro_until`.

---

## Teste

1. Copiar ID do aparelho no app.  
2. Pagar teste (sandbox MP) ou POST manual `extend_pro` com seu `device_id`.  
3. Configurações → **Sincronizar plano** → deve aparecer **PRO mensal** com data.  
4. Remover data no JSON ou esperar expirar → **Grátis**.
