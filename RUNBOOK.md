# RUNBOOK.md - PulseMac

## Requisitos

- macOS.
- Xcode instalado.
- SwiftFormat e SwiftLint via binário local/fallback do projeto quando necessário.

## Validar

```bash
./check.sh
```

## Operação local

- O app é 100% offline.
- Dados ficam no dispositivo.
- Histórico local deve ter retenção e limpeza.
- Export de diagnóstico gera arquivo local.

## Persistência

- Migrations são proibidas como padrão do modelo.
- Alterações em SQLite/store devem ser rotinas idempotentes ou scripts documentados.
- Explicar ordem, impacto e rollback em mudanças de persistência.

## Rollback

- Para mudança de UI: reverter View/ViewModel afetados.
- Para mudança de coleta: voltar collector/provider anterior.
- Para mudança de store: preservar compatibilidade de leitura ou fornecer rotina de downgrade/limpeza.
