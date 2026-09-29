# ROTA PRIME — continuar daqui

**Última atualização:** 2026-03-26  
**Versão do app:** `1.2.7+38` (`pubspec.yaml` + `lib/app/app_info.dart`)

Use este arquivo se o projeto quebrar, o chat sumir ou você voltar depois de meses.  
Objetivo do produto: app **nacional (Brasil)**, mapa **regional por entregador** (ex.: Caxias → RS, RJ → RJ), **sem servidor Node** no fluxo atual, **ultra rápido** no celular fraco.

---

## O que já está feito (não refazer do zero)

### Mapa e performance (~70% melhoria reportada pelo usuário)
- Enquadramento **cidade/UF**, nunca “Brasil inteiro” por geocode errado.
- `lib/utils/brazil_map_region.dart` — detecta UF (27 estados) e filtra paradas fora da região.
- `lib/utils/map_route_fit.dart` + `lib/utils/map_geo.dart` — fit da câmera, zoom mínimo regional.
- `lib/app/map_performance.dart` — limites ultra rápido:
  - **40+ paradas:** abre **lista** primeiro; mapa atrás.
  - **25+:** pins leves, tiles só rede, basemap simples.
  - **60+:** sem pin do motorista no planejamento.
  - **40+:** sem linha laranja completa no mapa.
- `lib/widgets/planning_route_map_layer.dart` — mapa isolado, rebuild só quando paradas mudam de verdade.
- `lib/widgets/route_map.dart` — cache de markers, animação GPS só na entrega ativa, tiles com buffer 1 em rotas pesadas.
- `lib/screens/rota_mapa_screen.dart` — bootstrap com GPS, fit regional, otimização sem bloquear UI.

### Servidor local / VPS — **removido do app**
- Apagados: `rota_server_screen`, `rota_backend_client`, `rota_server_settings`, `rota_api_config`.
- **Otimização:** OSRM público no aparelho (`lib/services/osrm_service.dart`).
- **Geocode:** Photon/direto no aparelho (`lib/services/geocode_service.dart`).
- Pasta `servidor/` no PC fica **ignorada pelo git** (`.gitignore`). Pode apagar manualmente.
- **Licença PRO** (`reloadPlanFromServer` em `subscription_provider`) **permanece** — não é o servidor Node.

### Build e scripts
- `COMPILAR.APK.bat` — APK celular + emulador em `release/`.
- `PARAR-TUDO.bat` / `PARAR-GRADLE.bat` — para Gradle após compilar.

### UI recente
- Rodapé mapa/lista: **setas + ícone de mapa** (`route_map_mode_toggle.dart`).
- Dialog otimizar: setas girando + mapa (sem triângulo Penrose).
- GPS no mapa: círculo laranja + seta (`rota_driver_map_marker.dart`).

---

## Como testar (fluxo oficial hoje)

1. **Servidor:** não usar — URL vazia, sem painel Node.
2. `COMPILAR.APK.bat` → instalar `release/ROTA_PRIME.apk` no Motorola.
3. Importar romaneio (~115 paradas se possível).
4. Conferir:
   - Mapa na **região certa** (RS se você está em Caxias).
   - **Lista** abre primeiro se 40+ paradas.
   - Otimizar (PRO) sem travar o dialog.
   - Zoom/girar mapa com delay aceitável.

---

## Arquivos-chave (onde mexer se der bug)

| Área | Caminho |
|------|---------|
| Tela mapa + lista | `lib/screens/rota_mapa_screen.dart` |
| Camada mapa planejamento | `lib/widgets/planning_route_map_layer.dart` |
| Mapa (tiles, pins, polylines) | `lib/widgets/route_map.dart` |
| UF / região Brasil | `lib/utils/brazil_map_region.dart` |
| Fit câmera | `lib/utils/map_route_fit.dart` |
| Limites performance | `lib/app/map_performance.dart` |
| Otimização rota | `lib/services/osrm_service.dart` + `lib/providers/rota_provider.dart` |
| Import / registry romaneio | `lib/utils/romaneio_import_registry.dart` |
| Versão visível | `lib/app/app_info.dart`, `pubspec.yaml` |

---

## Próximos passos (se quiser “ultra rápido++”)

- [ ] Modo “só lista” opcional até o usuário tocar no mapa (rotas 80+).
- [ ] Clustering de pins no zoom baixo (muitos markers).
- [ ] Adiar geocode em lote com progress na lista (import).
- [ ] Publicar build 38 no GitHub Releases (`ROTA_PRIME.apk`).

---

## Git (salvar no repositório)

Se o commit falhar por “Author identity unknown”, configure uma vez no PC:

```powershell
git config user.email "seu@email.com"
git config user.name "Seu Nome"
```

Depois, na pasta do projeto:

```powershell
cd "c:\Users\User\Desktop\ROTA PRIME"
git add lib/ pubspec.yaml android/ .gitignore COMPILAR.APK.bat PARAR-*.bat CONTINUAR-AQUI.md
git status
git commit -m "v1.2.7: mapa regional por UF, ultra rapido, sem servidor Node"
```

**Não** adicionar `servidor/`, `build/`, `.dart_tool/`, `release/*.apk` (já no .gitignore).

---

## Se der erro ao compilar

1. `PARAR-TUDO.bat`
2. `flutter clean` (opcional, demora)
3. `COMPILAR.APK.bat` de novo
4. Erro de análise: `dart analyze lib`

---

## Contato com contexto antigo

Conversas longas podem estar resumidas; este arquivo é a **fonte de verdade local**.  
Ao abrir novo chat no Cursor, diga: *“Leia CONTINUAR-AQUI.md e continue o ROTA PRIME.”*
