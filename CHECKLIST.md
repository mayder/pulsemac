# Checklist

## Phase 0: Repo scaffolding + CI-like local check
- [x] Estrutura base de pastas
- [x] Docs: ARCHITECTURE, ROADMAP, QUALITY_ROADMAP, PRIVACY
- [x] check.sh com format/lint/build/test
- [x] SwiftFormat + SwiftLint config
- [x] Xcode project com targets

## Phase 1: Metrics core + menu bar
- [x] Coletores CPU e Memoria
- [x] Coletores Disco, Rede e Bateria
- [x] MetricsSampler com intervalo configuravel
- [x] Menu bar mostrando CPU/RAM
- [x] Tela dedicada de metricas
- [x] Monitor grafico (velocimetros + linha temporal)

## Phase 2: Alerts + notificacoes + historico
- [x] Rule engine com duracao sustentada + cooldown
- [x] CRUD basico de alertas
- [x] Editor completo de alertas
- [x] Notificacoes locais com acoes
- [x] Nao perturbe com horario local
- [x] Filtros e busca no historico de alertas
- [x] Historico local (SQLite)
- [x] Tela dedicada de alertas
- [x] Aba "Impacto" (thresholds ativos + possiveis processos causadores)
- [x] Impacto: carregar dados somente ao abrir a aba (sem amostragem continua)

## Phase 3: Widgets
- [x] Widget pequeno/medio/grande
- [x] App Group e compartilhamento de dados

## Phase 4: Temps/Fans + top processos
- [x] Coletores best-effort (temps/fans)
- [x] Top processos
- [x] Tela detalhada de processos (grafico CPU/Memoria)
- [x] Aba "Processos" (tabela por CPU/Memoria/Disco) com coleta sob demanda

## Phase 5: Polish
- [x] Performance tuning e notas
- [x] Export diagnostico local
- [x] Revisao final de docs

## Fase UX (HIG)
### Etapa 1: Estrutura e navegacao
- [x] Migrar abas para sidebar padrao do macOS
- [x] Janela redimensionavel + persistencia de tamanho/posicao
- [x] Toolbar unificada com acao global de atualizar (quando aplicavel)
- [x] Comandos basicos no menu bar (Atualizar, Exportar, Sobre)

### Etapa 2: Hierarquia e conteudo
- [x] Remover textos repetidos e padronizar unidades
- [x] Ajustar grid/alinhamento entre cards
- [x] Agrupar detalhes por categoria (CPU/Memoria/Disco/Rede/Bateria/Sensores) e reduzir duplicacao no resumo

### Etapa 3: Controles e acoes
- [x] Botoes com icone e menu de acoes secundarias
- [x] Search field nativo nas listas

### Etapa 4: Telas principais
- [x] Metricas com cards mais claros (usado/livre)
- [x] Processos com icone do app e painel lateral fixo
- [x] Impacto com foco em regras ativas e processos sugeridos
- [x] Alertas em layout mestre-detalhe mais compacto

### Etapa 5: Acessibilidade e teclado
- [x] Atalhos basicos via menu bar (Atualizar, Exportar, Ajustes)
- [x] Navegacao por teclado nas abas (Cmd+1..5)

## Pendencias (para amanha)
- [x] Decidir estrategia App Sandbox x App Group x Widgets (A/B/C) (decisao: App Sandbox OFF, App Group ON p/ Widgets, sem rede)
- [x] Revisar warnings "Publishing changes from within view updates" (refreshIfNeeded defasado no onAppear)
- [x] Ajustar CPU por processo com normalizacao por numero de nucleos
- [x] Melhorar leitura de disco por processo (manter ultimo valor por alguns segundos)
- [x] Adicionar menu Window padrao do macOS
- [x] Metricas: aba CPU com detalhes (carga, nucleos, uso por nucleo).
- [x] Metricas: aba Disco com detalhes (ocupacao e throughput por processo).
- [x] Metricas: aba Rede com detalhes (picos e medias).
- [x] Metricas: aba Bateria com detalhes (estado, ciclos, tempo e capacidade).
- [ ] Metricas: aba Sensores com detalhamento e explicacoes (quando indisponivel).
- [ ] Processos: detalhar processos agrupados e contexto extra.
- [ ] Alertas: detalhar regras e eventos com contexto.
- [ ] Impacto: detalhar causas provaveis e links rapidos.
- [ ] Ajustes: detalhar configuracoes por categoria.
- [ ] Sobre: detalhar versao, sistema e creditos.
- [x] Sobre: mostrar informacoes do app e do sistema (versao, modelo, CPU, memoria, locale)
- [x] Metricas: detalhar Memoria (usado/livre/total/%)
- [x] Alertas: ao clicar na notificacao, abrir a tela de Metricas na categoria correspondente (CPU/Memoria/Disco/Rede/Bateria/Sensores)
- [x] Alertas: evitar notificacoes duplicadas do mesmo alerta (remover anterior e enviar a nova)
- [x] Historico de metricas (linha temporal). Aceitacao: selecionar metrica e ver serie temporal com filtros de periodo (1h/24h/7d), sem travar a UI.
- [x] Logs do sistema (erros recentes). Aceitacao: lista paginada com filtro por severidade e busca; coleta sob demanda.
- [x] Consumo por app (agrupado por bundle). Aceitacao: tabela agrupada por app com CPU/Memoria/Disco somados; ordenar por consumo.
- [x] Relatorio rapido (exportar resumo). Aceitacao: gerar JSON local com snapshot atual + top processos + regras ativas.
- [x] Atalhos (acoes rapidas). Aceitacao: botao para pausar alertas, limpar historico local, abrir pastas de diagnostico.
- [x] Favoritos (processos monitorados). Aceitacao: usuario marca processos; lista dedicada com alertas opcionais por favorito.
- [x] Comparar periodos (hoje x ontem). Aceitacao: comparativo simples com variacao % para CPU/RAM/Disco/Rede.
- [x] Metricas: bloco Top processos com detalhe e sparklines na Visao geral.
- [x] Processos: resumo com contadores + acao de atualizar e limpar busca.
- [x] Alertas: resumo com contagem de regras e ultimo evento.
- [x] Widget preview. Aceitacao: tela com preview dos tamanhos (P/M/G) e ultima atualizacao.
- [x] Diagnostico avancado (health do app). Aceitacao: mostra versao, status de permissao, App Group, sandbox e ultimo erro.

## Criterios de aceitacao (MVP)
- [x] Menubar mostra CPU% e RAM usados atualizando no intervalo escolhido
- [x] Usuario cria alerta "CPU > 80% por 20s" e recebe notificacao local
- [x] ./check.sh passa em maquina limpa com Xcode
- [x] App offline, sem permissao de rede
