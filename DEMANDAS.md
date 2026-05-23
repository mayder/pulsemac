# DEMANDAS.md - PulseMac

Backlog executável do PulseMac. O histórico inicial permanece em `CHECKLIST.md` e `ROADMAP.md`.

## Quando criar pacote

Criar pacote quando houver várias demandas relacionadas, risco transversal, mudança em mais de um módulo ou necessidade de dividir entrega em lotes. Um lote pode resolver uma ou mais demandas, mas o pacote só fecha após check completo e review de fechamento.

## Estado atual

O app já possui base funcional, menu bar, métricas, alertas, histórico local, widgets e diagnóstico. Próximas demandas devem ser abertas como pacotes aqui antes de implementação.

## Pacotes sugeridos

| Pacote | Nome | Status |
|---|---|---|
| PMAC-01 | Revisão de sensores e explicações de indisponibilidade | não iniciado |
| PMAC-02 | Detalhamento de processos agrupados | não iniciado |
| PMAC-03 | Detalhamento de regras/eventos de alertas | não iniciado |
| PMAC-04 | Melhorias de impacto e causas prováveis | não iniciado |
| PMAC-05 | Ajustes por categoria e documentação operacional | não iniciado |

## PMAC-01 - Revisão de sensores

Lotes:

- [ ] Mapear sensores disponíveis/indisponíveis por hardware.
- [ ] Melhorar explicações na aba Sensores.
- [ ] Garantir fallback visual sem travar UI.
- [ ] Testar view model e formatação.

## Regras

- Lotes podem usar testes direcionados.
- Fechamento de pacote exige `./check.sh` completo.
- Bugs corrigidos devem atualizar `BUGS.md` e retestar conforme `TESTES.md`.
- Pacote fechado deve ter commit local, sem push automático.
