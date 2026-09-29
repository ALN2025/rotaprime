# Mapa escuro com nomes de ruas — ROTA PRIME

## O que o app usa hoje (sem chave Google)

O mapa principal é **Flutter Map + tiles Esri** (grátis, sem API key):

| Modo no app | Base | Nomes de rua |
|-------------|------|----------------|
| **Ruas** | Esri World Street Map | Sim |
| **Escuro** | **Carto Dark** (fundo escuro + ruas no tile) | Sim — nomes no zoom (Carto CDN) |

**Não precisa de chave Google** no modo Escuro. Usa **Carto `dark_all`** (mapa escuro de verdade, diferente do Ruas claro).

Se ainda faltar algum nome, é lacuna do OpenStreetMap na região (qualquer mapa OSM), não falta de API Google.

Isso já aparece em **Tipo de mapa** com apenas **Ruas** e **Escuro**.

---

## Se quiser Google Maps (nomes no modo escuro)

Aí sim precisa de **Google Cloud** e billing (há cota grátis mensal).

### 1. Criar projeto

1. [Google Cloud Console](https://console.cloud.google.com/)
2. Novo projeto, ex.: `ROTA PRIME`

### 2. Ativar APIs

- **Maps SDK for Android** (mapa no app)
- **Maps SDK for iOS** (se publicar na App Store)
- Opcional: **Directions API** / **Routes API** (rotas no Google; hoje o app usa OSRM)

### 3. Criar chave de API

1. **APIs e serviços → Credenciais → Criar credenciais → Chave de API**
2. Restrinja a chave:
   - **Android:** nome do pacote `com.example.rota_prime` (confira em `android/app/build.gradle.kts`) + SHA-1 do keystore de release/debug
   - **APIs:** só Maps SDK for Android (e iOS se usar)

### 4. Colocar no Android (ROTA PRIME)

1. Copie `android/maps-key.properties.example` → `android/maps-key.properties`
2. Cole a chave em `GOOGLE_MAPS_API_KEY=...` (este arquivo **não vai pro Git**)
3. Recompile o APK — o Gradle injeta no `AndroidManifest`

**Restrinja a chave** no Google Cloud: pacote `com.rotaprime.rota_prime` + SHA-1 do keystore.

### 5. Estilo escuro com ruas legíveis

No Google Maps, use **Map Style** (JSON) no console ou `GoogleMap(mapStyle: ...)`.

- Estilo **dark** oficial: [Map Style Reference](https://developers.google.com/maps/documentation/javascript/style-reference)
- Para **rótulos de ruas** visíveis: não oculte features `road` / `road.local` no JSON; ajuste `visibility` e `color` dos labels.

Migrar o app de Esri para `google_maps_flutter` é uma mudança grande; para entregas no Brasil, **Escuro (Esri Reference)** costuma ser suficiente sem Google.

### Suporte

WhatsApp: **+55 54 99137-6738** (54991376738)
