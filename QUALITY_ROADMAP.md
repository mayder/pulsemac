# Quality Roadmap

## Gates obrigatorios
- SwiftFormat (lint)
- SwiftLint (strict)
- Build com Xcode
- Testes unitarios

## check.sh
`check.sh` executa, nesta ordem:
1. swiftformat --lint
2. swiftlint --strict
3. xcodebuild build
4. xcodebuild test

## Convencoes
- Arquitetura limpa e protocolos no dominio
- Sem chamadas de rede
- Codigo e docs em PT-BR (ASCII quando possivel)
- Preferir structs para snapshots e modelos simples

## Tests obrigatorios
- Avaliacao de regra com duracao sustentada + cooldown
- Logica de notificacao com fake
- Persistencia com store em memoria/fake

## Performance baseline
- Intervalo padrao: 2s
- Timer com throttling
- Sem busy-loop


## Modelo IA e workflow

- Ler `PATHS.toml` antes de planejar ou implementar.
- Seguir SOLID e separação de responsabilidades.
- Leitura mínima por tipo de tarefa: pacote usa `PATHS.toml`, `QUALITY_ROADMAP.md`, `GOVERNANCA.md` e `DEMANDAS.md`; bug usa `BUGS.md` e `TESTES.md`; UI usa `TELAS.md` e `TESTES.md`.
- Resposta final curta: informar o que foi feito, bloqueios e como validar.
- Se a branch atual for `main` ou `hml`, confirmar com o usuário antes de alterar, exceto quando houver autorização explícita para o lote.
- Nunca usar migrations. Mudanças persistentes devem ser scripts/rotinas idempotentes documentadas quando aplicável.
- Observabilidade mínima da aplicação deve ser local/offline, com retenção e limpeza para histórico/diagnósticos.
- Review de fechamento de pacote: revisar bugs, regressão, arquitetura, testes, docs, riscos e rollback.
- Contrato de módulo: responsabilidade, entradas, saídas, erros, dependências e limites de camada.
- Nomenclatura oficial do projeto fica em `ESCOPO.md`.
- Adaptação à arquitetura real: preservar AppKit/SwiftUI/WidgetKit e boundaries já existentes.
- Decisões arquiteturais ficam em `DECISOES.md` no formato `DEC-YYYYMMDD-01`.
- Check adaptável por stack: `check.sh` roda validações do modelo e checks Swift/Xcode reais.
