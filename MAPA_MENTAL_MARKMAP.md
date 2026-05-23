---
title: PulseMac - Mapa Mental
markmap:
  colorFreezeLevel: 2
---

# PulseMac

## Fontes
- PATHS.toml
- ESCOPO.md
- GOVERNANCA.md
- QUALITY_ROADMAP.md
- DEMANDAS.md
- ARCHITECTURE.md
- CHECKLIST.md
- PRIVACY.md

## Produto
- Monitor de sistema macOS
- 100% offline
- Menu bar
- Alertas locais
- Histórico local
- Widgets
- Diagnóstico local

## Arquitetura
- SOLID
- Clean/Hexagonal
- Domain
  - Models
  - Alerts
  - Protocols
- Data
  - Stores
  - Notifications
  - Sampler
- SystemMetrics
  - CPU
  - Memory
  - Disk
  - Network
  - Battery
  - Thermal
  - Processes
- Presentation
  - Views
  - ViewModels
- App
  - AppKit
  - DI
- Widgets

## Checks
- Validações do modelo
- SwiftFormat
- SwiftLint
- xcodebuild clean
- xcodebuild build
- xcodebuild test

## Pacote/lote
- Lote com teste direcionado
- Fechamento com check completo
- Review de pacote
- Commit local ao fechar pacote

## Privacidade
- Sem rede
- Sem analytics
- Sem crash remoto
- Dados locais
- Export local
