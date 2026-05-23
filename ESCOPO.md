# ESCOPO.md - PulseMac

## Visão

PulseMac é um app macOS nativo, offline, para monitoramento local de sistema. O app usa menu bar, SwiftUI para configuração e painéis, WidgetKit com App Group, notificações locais e persistência local.

## Stack real

- Linguagem: Swift.
- Plataforma: macOS.
- UI: AppKit para status item/janelas e SwiftUI para telas.
- Widgets: WidgetKit com App Group.
- Persistência: SQLite/local stores.
- Notificações: UserNotifications.
- Testes: XCTest.
- Qualidade: SwiftFormat, SwiftLint, xcodebuild build/test.

## Módulos

- `Sources/App`: composição, AppDelegate, menu bar, janelas e entrada do app.
- `Sources/Domain`: entidades, regras, protocolos e contratos puros.
- `Sources/Data`: implementações de stores, sampler, notificações e diagnósticos.
- `Sources/SystemMetrics`: coletores de métricas do sistema.
- `Sources/Storage`: persistência SQLite/local.
- `Sources/Presentation`: ViewModels e Views SwiftUI.
- `Sources/Widgets`: WidgetKit.
- `Tests`: testes unitários.

## Nomenclatura oficial do projeto

- `View`: tela ou componente SwiftUI.
- `ViewModel`: estado e ações da tela.
- `Model`: snapshot/entidade simples.
- `Store`: persistência local.
- `Collector`: coleta de métrica do sistema.
- `Provider`: fonte externa/local abstrata.
- `Client`: integração com API do sistema, notificação ou serviço local.
- `Engine`/`Evaluator`: regra de domínio.
- `Protocol`: contrato de domínio ou boundary.

## Regras de arquitetura

- SOLID é obrigatório.
- Domain não depende de SwiftUI, AppKit, SQLite, WidgetKit ou APIs concretas do sistema.
- Presentation não acessa SQLite/coleta diretamente; usa ViewModels e contratos.
- App faz composição e DI, não regra de negócio.
- Nenhuma chamada de rede em runtime.
- Persistência local deve ter política de retenção e limpeza quando armazenar histórico.
