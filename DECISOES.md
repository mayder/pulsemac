# DECISOES.md - PulseMac

## Modelo de decisão

### DEC-YYYYMMDD-01 - Título da decisão

- Contexto:
- Decisão:
- Alternativas consideradas:
- Impacto:
- Rollback:

## Decisões existentes consolidadas

### DEC-20260207-01 - App offline e sem rede

- Contexto: PulseMac monitora o sistema local.
- Decisão: não usar rede, telemetria, analytics, crash reporting remoto ou remote config.
- Impacto: diagnóstico e logs devem ser locais.
- Rollback: qualquer integração externa exige nova decisão e revisão de privacidade.

### DEC-20260207-02 - App Sandbox OFF e App Group ON

- Contexto: leitura de processos/caminhos locais e widgets exigem capacidades específicas.
- Decisão: App Sandbox OFF para leitura local e App Group ON para Widgets.
- Impacto: manter privacidade local e documentar no `PRIVACY.md`.
- Rollback: reavaliar permissões e capacidades se a distribuição exigir sandbox.
