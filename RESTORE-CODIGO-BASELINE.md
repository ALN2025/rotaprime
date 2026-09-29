# Restaurar código — baseline APK da raiz

Use este ponto quando novas implementações quebrarem o app. O **APK de referência** funcional fica na raiz do projeto:

- `ROTA_PRIME.apk` ou `BASE APK ROTA PRIME.apk`

## Commit baseline (código estável antes das mudanças desta sessão)

```
fad3ea8e1b687ed4c3a4c0b50b0fe52a86bca4da
```

## Restaurar só o código (git)

1. Salve o que estiver fazendo: `git stash push -m "backup antes restore"`
2. Volte ao baseline: `git checkout fad3ea8e1b687ed4c3a4c0b50b0fe52a86bca4da -- .`
3. Ou execute na raiz: **`RESTAURAR-CODIGO-BASELINE.bat`**

Depois de testar, para voltar ao trabalho recente: `git stash pop`.

## Reinstalar o APK baseline no celular

1. Copie `ROTA_PRIME.apk` para o telefone.
2. Desinstale a versão atual (se pedir assinatura diferente).
3. Instale o APK da raiz.

## Marcar um novo baseline (quando estiver satisfeito de novo)

```bat
git add -A
git commit -m "Baseline funcional ROTA PRIME v1.2.7"
git tag baseline-funcional-v1.2.7
```

Atualize o hash deste arquivo com `git rev-parse HEAD`.
