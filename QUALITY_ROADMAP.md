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
