# Arquitetura

## Principios
- Separacao clara de responsabilidades (Clean Architecture / Hexagonal)
- Dependencias sempre apontam para o dominio
- Protocolos para todas as fontes de dados e integracoes
- Atualizacao por eventos (Combine) e amostragem eficiente

## Modulos
- **Domain** (`Sources/Domain`)
  - Entidades: MetricSnapshot, CPUMetrics, MemoryMetrics, AlertRule, AlertEvent
  - Regras e casos de uso: AlertRuleEvaluator, AlertEngine
  - Protocolos: coletores, repositorios, notificacoes, clock
- **Data** (`Sources/Data`, `Sources/SystemMetrics`, `Sources/Storage`, `Sources/Alerts`)
  - Implementacoes concretas de coletores
  - Persistencia local (SQLite)
  - Store de regras e preferencias
  - Cliente de notificacoes locais
- **Presentation** (`Sources/Presentation`)
  - SwiftUI Views + ViewModels (Metricas, Alertas, Ajustes, Sobre)
  - Abas adicionais: Processos (on-demand) e Impacto de Alertas (on-demand)
  - Navegacao via sidebar nativa e comandos no menu bar
- **App** (`Sources/App`)
  - AppKit (NSStatusItem) e composicao (DI)
- **Widgets** (`Sources/Widgets`)
  - WidgetKit, leitura via App Group

## Fluxo de dados
1. `MetricsSampler` coleta CPU/RAM em intervalo configuravel
2. Publica `MetricSnapshot` via Combine
3. `MenuBarViewModel` atualiza UI
4. `AlertEngine` avalia regras e dispara notificacoes
5. `AppGroupMetricsStore` grava snapshot para Widgets
6. Coleta on-demand para abas de Processos e Impacto (somente ao abrir)

## Padroes
- Strategy: coletores (CPU, memoria, etc.)
- Observer/Publisher: Combine
- Specification: regras de alerta
- DI manual: `AppContainer`

## Limites e falhas
- Se uma metrica nao estiver disponivel, mostrar "--"
- Nenhuma chamada de rede em runtime
- Uso de timers com throttling para evitar busy-loop
- App Sandbox desativado para permitir leitura de processos e caminhos locais

## Performance (notas base)
- Amostragem em fila `utility` com `DispatchSourceTimer` e leeway (evita wakeups excessivos)
- Coletores mais caros (processos e termico) sao amostrados a cada N ciclos e reutilizam o ultimo valor
- Intervalos configuraveis: 1s, 2s, 5s, 10s
- Abas de Processos/Impacto executam coleta sob demanda para evitar consumo continuo
