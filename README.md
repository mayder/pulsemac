# PulseMac

Monitor de sistema macOS nativo, leve e 100% offline. Inspirado em iStat Menus, com alertas locais, notificacoes e widgets.

## Objetivos
- 100% offline (sem rede, telemetria, analytics ou crash reporting)
- Menu bar com AppKit (NSStatusItem)
- UI de configuracao com SwiftUI
- WidgetKit com dados via App Group
- Alertas locais com UserNotifications
- Arquitetura limpa e testavel desde o dia 1

## Telas e recursos atuais
- Metricas (cards + sensores + rede)
- Processos (tabela com app/CPU/memoria/disco e detalhes)
- Alertas (CRUD, historico, filtros)
- Impacto (regras ativas + processos sugeridos)
- Ajustes e Sobre

## Navegacao
- Sidebar nativa do macOS
- Atalhos: Cmd+1..5 para trocar de abas
- Menu bar: Atualizar, Exportar diagnostico, Ajustes, Sobre

## Requisitos de desenvolvimento
- macOS + Xcode instalado
- `check.sh` executa formatacao, lint, build e testes

## Rodar checks
```
./check.sh
```

## Estrutura (alto nivel)
- `Sources/App`: entrada AppKit + status item
- `Sources/Presentation`: SwiftUI + ViewModels
- `Sources/Domain`: entidades, casos de uso, protocolos
- `Sources/Data`: implementacoes e infraestrutura
- `Sources/SystemMetrics`: coletores de metricas
- `Sources/Alerts`: motor de alertas
- `Sources/Storage`: persistencia local
- `Sources/Widgets`: widget extension
- `Tests`: testes unitarios

## Privacidade
Ver `PRIVACY.md`.
