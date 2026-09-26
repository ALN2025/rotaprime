# ROTA PRIME

Aplicativo Android para **planejamento e execução de rotas de entrega**, pensado para entregadores que trabalham com romaneios (planilhas XLSX), paradas manuais e navegação assistida no mapa.

**Versão atual:** `1.0.1+17` (ver `pubspec.yaml`)

> **Download oficial (clientes):** [github.com/ALN2025/rotaprime](https://github.com/ALN2025/rotaprime) · **[Baixar APK (Release)](https://github.com/ALN2025/rotaprime/releases/latest)**  
> README para entregadores no repositório: compara **Grátis** vs **PRO** com ícones. Guia detalhado: **[GUIA-USUARIO.md](GUIA-USUARIO.md)**.

---

## Visão geral

O ROTA PRIME reúne em um único fluxo:

- importação de pacotes a partir de **planilha XLSX** (formato compatível com romaneios Shopee);
- **mapa interativo** com pins por endereço, progresso de entregas e GPS;
- **modo entrega ativa** (entregue / não entregue, múltiplos pacotes no mesmo endereço);
- planos **Grátis** e **PRO**, com otimização de rota e traçado pelas ruas apenas no PRO.

Os dados ficam **no aparelho** (banco local Isar), com suporte a retomar rota ativa após fechar o app.

---

## Planos Grátis e PRO

| Recurso | Grátis | PRO |
|--------|:------:|:---:|
| Importar planilha XLSX | ✓ | ✓ |
| Mapa, paradas e status de entrega | ✓ | ✓ |
| Ordem igual à planilha / manual | ✓ | ✓ |
| Parada manual (rua, nº, bairro, cidade) | ✓ | ✓ |
| Editar endereço do pin (menu ⋮) | ✓ | ✓ |
| CEP + número (ViaCEP) | — | ✓ |
| Otimização OSRM + linha laranja no mapa | — | ✓ |
| Tempo / distância estimados | — | ✓ |
| Controle de gastos e lucro da rota | — | ✓ |

Detalhes completos: tela **Comparar planos** dentro do app.

A licença PRO é vinculada ao **ID do aparelho** (Configurações → ID do aparelho). Geração de chaves: script `GERAR-LICENCA.bat` (uso interno / suporte).

---

## Requisitos

### Para usar o APK (entregador)

- Android com permissões de **localização** e **internet** (mapa, geocodificação e, no PRO, OSRM).
- Opcional: microfone (entrada por voz), câmera (QR de pacote).

### Para compilar (desenvolvimento)

- [Flutter SDK](https://docs.flutter.dev/get-started/install) compatível com `sdk: ^3.12.2`
- Android SDK / Android Studio (JDK embarcado)
- `flutter` e `dart` no `PATH`

---

## Build do APK oficial

Na raiz do projeto:

```bat
COMPILAR.APK.bat
```

O script executa, em sequência:

1. `flutter pub get`
2. `dart run build_runner build` (Isar)
3. `flutter build apk --release` — **celular** (ARM) e **emulador** (x64)
4. Cópia dos artefatos para:
   - `release\ROTA_PRIME.apk` ← **celulares / distribuição / GitHub**
   - `release\ROTA_PRIME_EMULADOR.apk` ← **emulador Android no PC** (demo-pc)
   - Área de trabalho: `ROTA_PRIME.apk` e `ROTA_PRIME_EMULADOR.apk`

Use **somente** `release\ROTA_PRIME.apk` para Telegram, USB e entregadores. Não envie o APK do emulador para celulares reais.

Se o build falhar ou o APK ficar anormalmente pequeno, execute `REPARAR-GRADLE.bat` e compile novamente.

---

## Instalação no celular

1. Instale `release\ROTA_PRIME.apk` (permitir “fontes desconhecidas” se necessário).
2. Ou, com USB debugging e `adb` no PATH:

   ```bat
   INSTALAR-USB.bat
   ```

---

## Desenvolvimento local

```bat
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

Análise estática:

```bat
dart analyze
flutter test
```

Após alterar modelos Isar (`lib/models/*.dart` com anotações `@collection`), regenere sempre com `build_runner`.

---

## Estrutura do projeto (resumo)

| Caminho | Descrição |
|---------|-----------|
| `lib/` | Código Flutter (telas, providers, serviços, widgets) |
| `lib/providers/rota_provider.dart` | Estado da rota, otimização, navegação ativa |
| `lib/services/` | Importação XLSX, geocodificação, OSRM, localização |
| `lib/widgets/` | Mapa, folhas de parada, diálogos manual/editar |
| `android/` | Projeto Android nativo |
| `release/` | APK oficial gerado pelo script |
| `demo-pc/` | Materiais auxiliares de demo (emulador / mock); não substituem o APK |
| `tools/` | Scripts de verificação do APK |

---

## Stack técnica

- **Flutter** + **Riverpod** (estado)
- **Isar** (persistência local)
- **flutter_map** + **latlong2** (mapa)
- **OSRM** (otimização e trechos PRO)
- **Nominatim / Photon** (geocodificação de endereços manuais)
- **ViaCEP** (entrada por CEP no PRO)
- **geolocator**, **mobile_scanner**, **speech_to_text**, entre outros (ver `pubspec.yaml`)

---

## Fluxo típico do entregador

1. **Importar** romaneio XLSX ou **criar rota manual** (Grátis: rua, número, bairro e cidade).
2. Revisar paradas no **mapa**; corrigir endereço pelo menu **⋮ → Editar endereço** se necessário.
3. **PRO:** otimizar rota → traçado laranja e ordem sugerida pelo menor caminho.
4. **Iniciar rota** → modo entrega ativa (Grátis: ordem da planilha; PRO otimizado: pin mais próximo + recálculo ao desviar).
5. Marcar **Entregue** / **Não entregue**; app prioriza outros pacotes no **mesmo endereço** quando aplicável.
6. **Finalizar** rota e consultar histórico / gastos (PRO).

---

## Scripts úteis (Windows)

| Script | Função |
|--------|--------|
| `COMPILAR.APK.bat` | Gera o APK release oficial |
| `INSTALAR-USB.bat` | Instala o APK via ADB |
| `GERAR-LICENCA.bat` | Gera licença PRO (suporte) |
| `REPARAR-GRADLE.bat` | Repara cache Gradle em falhas de build |

---

## Privacidade e rede

- Endereços digitados ou importados são usados para exibição no mapa e, quando online, enviados a serviços de **geocodificação** e **roteamento** (OpenStreetMap / OSRM / APIs públicas configuradas no app).
- Não commitar credenciais, `.env` ou chaves de licença no repositório.

Documentos legais: telas **Termos** / **Privacidade** no aplicativo.

---

## Suporte

Canal de suporte conforme a distribuição do APK (DEV ALN). Para PRO, informe o **ID do aparelho** copiado nas configurações do app.

---

## Licença do projeto

Software proprietário. Uso, distribuição e modificação conforme contrato ou autorização do titular (DEV ALN / ROTA PRIME).
