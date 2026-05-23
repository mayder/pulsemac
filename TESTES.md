# TESTES.md - PulseMac

## Política mínima de testes

- Unitário: validar regra de domínio, avaliadores, stores e view models sem depender de UI real.
- Integração local: validar SQLite/store, App Group, notificações fake e diagnósticos quando aplicável.
- UI/manual macOS: validar menu bar, janelas, widgets e atalhos em macOS com Xcode.
- Cobertura mínima por criticidade: alertas, histórico, notificações e coleta devem ter testes direcionados antes de fechar pacote.
- Dados de teste e fixtures: usar dados pequenos, determinísticos, sem dump real de produção e com IDs previsíveis.

## Pacote/lote

- Lotes usam testes rasos e direcionados.
- Fechamento do pacote exige `./check.sh` completo.
- Bug simples ou melhoria sem impacto de código pode usar teste local/direcionado.
- Bug complexo ou mudança ampla exige check completo.

## Check principal

```bash
./check.sh
```

O check roda SwiftFormat, SwiftLint, build e testes Xcode, além das validações do modelo.
