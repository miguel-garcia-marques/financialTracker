# Workflow dos Agentes

Este repositório usa desenvolvimento orientado por issues. Os agentes devem
manter GitHub Issues, branches e Pull Requests alinhados para que o trabalho
possa ser revisto e merged sem surpresas.

## Fonte De Verdade

- GitHub Issues são a fonte de verdade para trabalho de implementação.
- Usar `docs/` como contexto de produto e técnico quando existir, mas não usar
  docs como substituto de ligar PRs a issues.
- Antes de começar código, verificar o issue relevante e os PRs abertos.

## Branches

- Usar sempre o prefixo `codex/` para branches criados por agentes.
- Preferir nomes neste formato:
  - `codex/issue-N-descricao-curta`
  - `codex/docs-descricao-curta`
  - `codex/chore-descricao-curta`
- Manter um issue lógico por branch sempre que possível.
- Não reutilizar branches para issues não relacionados.
- Se um branch depende de outro branch ainda não merged, explicitar essa
  dependência no body do PR.

## Pull Requests

- Abrir um PR por issue.
- O título do PR deve começar pelo issue ou pelo tópico do issue, por exemplo:
  - `Issue 5: Criar App Intent para registar pagamento Apple Pay`
- Todo PR de issue deve incluir uma secção `Issue` com closing keyword:
  - `Closes #N`
- Depois de editar o PR, confirmar que o GitHub reconheceu a associação:
  - `gh pr view <PR> --json closingIssuesReferences`
- Se `closingIssuesReferences` estiver vazio num PR de issue, o PR não está
  corretamente ligado. Corrigir a base ou o body antes de considerar o PR ready.

## PRs Empilhados E Dependências

- Se o PR B depende do PR A, tornar a dependência explícita:
  - Adicionar uma secção `Dependencias`.
  - Incluir `Depends on #A`.
  - Incluir `Nao fazer merge antes de #A`.
- Manter PRs dependentes em draft até a dependência estar merged.
- Fluxo recomendado para stacks:
  1. Abrir o primeiro PR independente como ready.
  2. Abrir os PRs dependentes como draft.
  3. Depois de o PR A fazer merge, marcar o PR B como ready.
  4. Repetir até a stack estar merged.
- Se o GitHub não mostrar closing references para PRs empilhados, mudar a base
  do PR para `main` e usar a secção `Dependencias` mais estado draft para evitar
  merges fora de ordem.

## PRs De Documentação

- PRs só de documentação podem ser independentes e não precisam fechar issues de
  produto, exceto quando foram criados especificamente para um issue de docs.
- Não misturar planeamento/documentação com PRs de implementação, a menos que o
  issue peça explicitamente ambos.

## Validação

- Cada PR de implementação deve listar os comandos de validação usados.
- Para trabalho iOS, preferir:
  - `xcodebuild -project FinTrackApp.xcodeproj -scheme FinTrackApp -configuration Debug -destination generic/platform=iOS Simulator -derivedDataPath .build/DerivedData-<nome> CODE_SIGNING_ALLOWED=NO build`
- Se um comando não puder correr por limitações do ambiente local, indicar isso
  claramente no body do PR e na resposta final.

## Ordem De Merge

- Nunca fazer merge de um PR em draft.
- Nunca fazer merge de um PR que diz depender de outro PR ainda não merged.
- Fazer merge das stacks de baixo para cima:
  - Primeiro o PR sem dependências.
  - Depois o PR que depende dele.
  - Continuar por ordem.
- Depois de uma dependência fazer merge, atualizar o PR seguinte se a diff ou a
  base precisarem de limpeza, e só depois marcar como ready.

## Redução De Tokens E Créditos

- Ler primeiro os ficheiros estritamente necessários. Evitar abrir documentos
  longos completos quando `rg`, `git diff --stat`, `sed -n` ou `gh ... --json`
  dão contexto suficiente.
- Preferir comandos focados:
  - `rg "termo" caminho/`
  - `git diff -- nome-do-ficheiro`
  - `gh pr view <PR> --json number,title,body,baseRefName,headRefName`
- Usar `rg --files` para descobrir ficheiros antes de ler conteúdo.
- Evitar repetir leituras de ficheiros que acabaram de ser mostrados, salvo se
  houve alterações.
- Para PRs e issues, pedir apenas os campos JSON necessários em vez de texto
  completo de CLI.
- Antes de editar, resumir mentalmente o alvo e aplicar patches pequenos e
  localizados. Evitar refactors amplos sem necessidade do issue.
- Quando houver vários comandos independentes de leitura, executá-los em
  paralelo para reduzir tempo de interação.
- Não correr builds/testes repetidamente sem mudança relevante. Validar depois
  de um conjunto coerente de alterações.
- Se um build completo for caro e a alteração for textual/docs-only, não correr
  build; indicar no PR que a validação foi revisão textual.
- Evitar gerar artefactos grandes ou screenshots salvo quando forem necessários
  para validar UI, layout ou execução.
- Nas respostas finais, reportar só o essencial: PRs, issues, comandos de
  validação e bloqueios. Não colar logs longos.

## Higiene Local

- Manter outputs gerados fora dos commits.
- Não commitar `.DS_Store`, `.build/`, DerivedData ou estado de utilizador do
  Xcode.
- Antes de commitar, verificar:
  - `git status --short --branch`
  - `git diff --cached --stat`
- Não reverter alterações do utilizador a menos que isso seja pedido
  explicitamente.
