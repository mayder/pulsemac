# GOVERNANCA.md - PulseMac

## Precedência

1. `PATHS.toml`: caminhos e checks oficiais.
2. `QUALITY_ROADMAP.md`: workflow, arquitetura, SOLID e Definition of Done.
3. `GOVERNANCA.md`: gates, riscos, prioridade e rollback.
4. `ESCOPO.md`: escopo funcional.
5. `DEMANDAS.md`: backlog executável.
6. `TELAS.md`, `TESTES.md`, `BUGS.md`, `DECISOES.md` e `RUNBOOK.md`: validação e operação.

## Gates

- `./check.sh` verde antes de fechar pacote.
- Build e testes com Xcode quando houver mudança de código.
- Mudanças em coleta, alertas, persistência ou notificações exigem teste direcionado.
- UI precisa respeitar macOS HIG e não gerar loops de atualização.
- Sem telemetria, analytics, crash reporting remoto ou chamada de rede.

## Banco e governança técnica

- Migrations são proibidas. Alterações persistentes devem ser scripts/rotinas idempotentes documentadas quando aplicável.
- Preferir stores locais existentes; evitar criar novas tabelas/arquivos sem justificativa.
- Histórico local precisa de retenção e limpeza.
- Mudanças com risco transversal exigem rollback e decisão em `DECISOES.md` quando criarem padrão duradouro.

## Observabilidade mínima da aplicação

- Logs locais/diagnóstico sem dados sensíveis.
- Export de diagnóstico local, sem envio externo.
- Retenção e limpeza para histórico local.
- Nenhum dado sai do dispositivo.
