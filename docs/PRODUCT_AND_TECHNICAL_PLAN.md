# FinTrackApp - Plano de Produto e Arquitetura

Data: 2026-06-08

## 1. Visao

Construir uma app pessoal para consultar e gerir compras, com foco principal em transacoes feitas com Apple Pay, mas com suporte para adicionar transacoes manualmente dentro da app. A app deve receber eventos vindos do Apple Shortcuts, guardar pagamentos, categorizar automaticamente desde a primeira versao, permitir correcao manual de qualquer classificacao, aceitar faturas avulsas e associar cada fatura a transacao correta.

O objetivo principal e reduzir a acao manual para praticamente zero no momento do pagamento. A app nao deve tentar substituir o Shortcuts como mecanismo de captacao. O papel da app e receber o evento, persistir, enriquecer, reconciliar, consultar e corrigir.

## 2. Principio central

O sistema deve ser local-first e orientado por eventos.

Quando ocorre uma transacao Apple Pay, o iPhone dispara uma automacao via Apple Shortcuts. Essa automacao envia para a app um evento de pagamento. A app guarda o evento imediatamente como um draft, mesmo que venha incompleto, e abre uma janela de revisao onde o pagamento pode ser confirmado, descartado ou enriquecido com fatura. Depois, por regras, OCR, analise de fatura, inteligencia artificial e reconciliacao, o draft confirmado e transformado num pagamento completo.

Isto evita depender de uma unica fonte perfeita. Apple Pay, Wallet, bancos e faturas podem ter dados incompletos ou chegar em momentos diferentes.

## 3. Validação do Shortcuts concluída

A Apple disponibiliza um trigger de Shortcuts chamado Transaction para automacoes baseadas em transacoes da Wallet/Apple Pay. A documentacao publica da Apple indica que o trigger pode ser configurado para uma carta atraves da opcao "When I tap" e que automacoes pessoais podem ser ativadas/desativadas e, quando suportado, correr imediatamente.

Validação prática concluída em 2026-06-17: a automação `Transaction` foi configurada para executar imediatamente, sem notificação, ao tocar com qualquer um de 5 cartões da Carteira. O Shortcuts conseguiu receber a transação como entrada e usar os campos da transação numa notificação e numa nota.

Campos confirmados na UI do Shortcuts:

- `Transacao`: objeto completo da transacao.
- `Cartao ou passe`: cartao, passe ou metodo usado.
- `Comerciante`: nome do comerciante.
- `Quantia`: valor da transacao.
- `Nome`: nome/display name da transacao.

Exemplo real observado:

- `Quantia`: `8,70 €`
- `Comerciante`: `Ji YuanJi Yuan`
- Automação: `Executar imediatamente`
- Notificação da automação: desativada

O spike de discovery deixa de ser necessario. As duvidas restantes passam a ser tratadas como robustez de parsing e edge cases:

- Se `Quantia` chega como numero decimal, texto formatado ou objeto monetario.
- Se a moeda vem embebida em `Quantia` ou precisa de ser inferida.
- Se `Comerciante` vem sempre preenchido.
- Se `Nome` e diferente de `Comerciante` e em que casos.
- Se `Cartao ou passe` e suficiente para inferir banco.
- Se ha timestamp real dentro do objeto `Transacao` ou se temos de usar o timestamp criado pelo Shortcut.
- Se existe algum identificador unico ou se a app tem de deduplicar por heuristicas.

Decisao: a app deve assumir estes campos como payload base, mas guardar sempre o `raw_payload` completo para diagnostico e compatibilidade futura, porque a Apple pode alterar detalhes de Shortcuts entre versoes de iOS.

## 4. Experiencia alvo

### 4.1 Pagamento

1. Utilizador paga com Apple Pay.
2. Apple Shortcuts dispara uma automacao "Transaction".
3. A automacao chama uma acao da FinTrackApp ou envia uma request para um endpoint local/cloud.
4. A app recebe o evento, sem tentar capturar diretamente o pagamento por fora do Shortcuts.
5. A app cria um draft com estado `draft`.
6. A app abre uma janela/sheet de draft com os dados preenchidos pelo Shortcuts.
7. A app categoriza automaticamente de raiz, ainda no draft.
8. O utilizador pode confirmar, descartar ou editar o draft.
9. O utilizador pode anexar foto/PDF da fatura logo no draft, se a tiver.
10. Ao confirmar, o draft passa a pagamento com estado `pending_enrichment`, `complete` ou `needs_reconciliation`, conforme a qualidade dos dados.
11. Ao descartar, o draft fica marcado como `discarded` e nao entra nas consultas financeiras normais.
12. Se faltarem dados, a app mantem timestamp, cartao, banco se inferivel e origem `apple_pay_shortcut`.

### 4.1.1 Janela de draft

A janela de draft deve ser otimizada para decisao rapida, nao para contabilidade pesada.

Campos visiveis:

- Quantia
- Comerciante
- Nome da transacao
- Cartao ou passe
- Banco inferido/editavel
- Categoria sugerida
- Data/hora
- Estado da fatura

Acoes principais:

- Confirmar
- Descartar
- Editar campos
- Adicionar fatura
- Guardar como pendente, se o utilizador nao quiser decidir no momento

Comportamento:

- Se o utilizador confirmar sem fatura, a transacao fica guardada normalmente e marcada como sem fatura.
- Se adicionar fatura no draft, a fatura e associada diretamente ao pagamento quando este for confirmado.
- Se o utilizador fechar a janela sem escolher, o draft deve ficar numa inbox de drafts pendentes para nao perder o evento.
- A app deve evitar notificacoes ou bloqueios excessivos; o draft deve ser rapido de fechar/confirmar.

### 4.2 Transacao manual

1. Utilizador cria transacao manualmente.
2. Preenche montante, data, comerciante, banco, metodo de pagamento e notas.
3. A app sugere categoria automaticamente.
4. O utilizador pode alterar a categoria.
5. A transacao fica marcada com origem `manual`.

### 4.3 Consulta

O utilizador abre a app e ve:

- Lista cronologica de compras.
- Vista de calendario.
- Total diario, semanal e mensal.
- Filtros por categoria, comerciante, cartao e estado.
- Filtros por banco.
- Drafts pendentes.
- Pagamentos sem fatura.
- Pagamentos que precisam de revisao.
- Pesquisa global sobre todos os campos pesquisaveis: comerciante, montante, data, banco, cartao, categoria, notas, NIF, numero de fatura, IVA, texto OCR, linhas da fatura e payload bruto tecnico quando em modo debug.

### 4.4 Fatura depois da compra

1. Utilizador submete uma fatura sem ter de escolher previamente um pagamento.
2. A fatura entra numa inbox de faturas.
3. A app executa OCR e extrai campos.
4. A app usa regras e IA para encontrar a transacao correta.
5. A app adiciona detalhes a notas estruturadas.
6. Se a confianca for alta, associa automaticamente.
7. Se a confianca for baixa, mostra sugestoes e pede confirmacao.
8. O utilizador tambem pode anexar uma fatura diretamente a um pagamento especifico quando quiser.

## 5. Arquitetura recomendada

### 5.1 MVP recomendado: iOS local-first

Para uma app pessoal, a abordagem mais solida e com menos friccao e comecar por uma app nativa iOS:

- SwiftUI para interface.
- SwiftData ou SQLite para persistencia local.
- App Intents para expor uma acao chamavel por Apple Shortcuts.
- Document picker, camera e share extension para anexar faturas.
- VisionKit/Vision para OCR on-device.
- Gemini API, com API key configurada localmente, para analise opcional de faturas, categorizacao assistida e matching fatura-transacao.
- Opcionalmente CloudKit para sync privado entre dispositivos Apple.

Esta abordagem reduz dependencia de backend, melhora privacidade e encaixa naturalmente com Apple Pay, Wallet e Shortcuts.

### 5.2 Evolucao com backend

Adicionar backend apenas quando houver necessidade clara de:

- Sync multi-plataforma fora do ecossistema Apple.
- Processamento de faturas mais pesado.
- Dashboard web.
- Backup/exportacoes recorrentes.
- Modelos de categorizacao treinados com historico.

Opcoes praticas:

- Supabase: Postgres, Storage, Auth, Edge Functions.
- Cloudflare Workers + D1/R2: leve, barato, bom para APIs.
- Firebase: rapido para mobile, mas menos ideal para queries financeiras relacionais.

Para ja, CloudKit ou local SQLite e melhor que introduzir backend cedo demais.

## 6. Fluxo Apple Shortcuts

### 6.1 Shortcut ideal

Trigger:

- Automation: Transaction
- Card: selecionar cartao Apple Pay relevante
- Run Immediately: ligado, se permitido

Action:

- Executar acao App Intent da FinTrackApp: `Registar Pagamento Apple Pay`

Campos vindos do Shortcuts:

- `transaction`: valor completo de `Transacao`, preservado para debug.
- `card_or_pass`: valor de `Cartao ou passe`.
- `merchant`: valor de `Comerciante`.
- `amount`: valor de `Quantia`.
- `name`: valor de `Nome`.

Campos normalizados pela app:

- `source`: `apple_pay_shortcut`
- `triggered_at`: timestamp ISO 8601 criado pelo Shortcut
- `card_label`: normalizado a partir de `Cartao ou passe`
- `bank_name`: banco emissor inferido pela carta configurada, quando possivel
- `amount`: normalizado a partir de `Quantia`
- `currency`: extraido de `Quantia` ou default `EUR`
- `merchant_name`: normalizado a partir de `Comerciante`
- `transaction_name`: normalizado a partir de `Nome`
- `raw_payload`: JSON com tudo o que o Shortcut conseguir fornecer

### 6.2 Fallback se Shortcuts nao fornecer dados ricos

Se o trigger apenas indicar que houve um tap/pagamento:

1. Criar registo pendente com timestamp e cartao.
2. Usar heuristicas:
   - Localizacao aproximada no momento da compra, se o Shortcut permitir e o utilizador aceitar.
   - Comerciante frequente perto da localizacao.
   - Fatura anexada posteriormente.
   - Banco inferido pela carta configurada no Shortcuts.
   - Importacao posterior de extrato bancario CSV/OFX.
   - Email/recibo do comerciante, se o utilizador partilhar para a app.
3. Marcar pagamento como `needs_reconciliation` ate haver montante/comerciante.

Este fallback e essencial porque a Apple nao oferece uma API publica geral para ler todas as transacoes Apple Pay/Wallet como fonte de dados financeira completa.

## 7. Modelo de dados

O modelo de dados detalhado vive em `docs/DATA_MODEL.md`.

Entidades principais:

- `Payment`
- `Bank`
- `PaymentMethod`
- `Merchant`
- `Category`
- `Receipt`
- `ReceiptLineItem`
- `MerchantRule`
- `ReceiptPaymentMatch`

Decisoes centrais:

- Eventos Apple Pay recebidos pelo Shortcuts entram como `draft`.
- Drafts podem ser confirmados, descartados ou ficar pendentes.
- Faturas podem existir sem `payment_id` ate serem associadas.
- Banco e uma entidade propria e tambem pode existir como texto temporario em transacoes ainda nao normalizadas.
- Alteracoes manuais do utilizador prevalecem sobre regras e sugestoes de IA.

## 8. Categorizacao

### 8.1 Regras deterministicas primeiro

A primeira versao deve categorizar automaticamente todos os pagamentos que conseguir. A base deve ser regras simples e auditaveis:

- Comerciante conhecido -> categoria.
- Alias de comerciante -> comerciante canonical -> categoria.
- Palavras-chave no nome do comerciante.
- NIF do emissor da fatura.
- MCC/codigo de categoria, se alguma fonte futura fornecer.

Exemplos:

- `Continente`, `Pingo Doce`, `Lidl`, `Auchan` -> Supermercado
- `Uber`, `Bolt`, `CP`, `Carris`, `Metro` -> Transporte
- `Galp`, `Repsol`, `BP` -> Combustivel
- `Farmacia`, `Well's` -> Farmacia

### 8.2 Aprendizagem com feedback

Quando o utilizador muda a categoria de um comerciante, a app deve perguntar implicitamente pelo comportamento:

- Aplicar so a este pagamento.
- Aplicar a pagamentos futuros deste comerciante.
- Aplicar tambem a pagamentos antigos semelhantes.

### 8.3 IA apenas como camada auxiliar

Modelos de linguagem devem ser usados para:

- Normalizar comerciante.
- Interpretar faturas.
- Sugerir categoria quando regras falham.
- Gerar notas estruturadas.
- Ajudar no matching entre fatura avulsa e transacao.

Mas a app deve guardar sempre:

- Valor sugerido.
- Confianca.
- Razao/fonte.
- Se foi confirmado pelo utilizador.

### 8.4 Gemini API

A app pode usar Gemini via API key para tarefas onde modelos de linguagem trazem valor real:

- Extrair campos estruturados de OCR ruidoso.
- Classificar linhas de fatura.
- Sugerir categoria e subcategoria.
- Comparar fatura com transacoes candidatas.
- Explicar, em modo tecnico, porque uma associacao foi sugerida.

Como a app e para uso pessoal, a API key pode comecar por ficar configurada localmente nas definicoes da app ou num ficheiro de configuracao de desenvolvimento. Mesmo assim, a app deve tratar chamadas externas como opcionais: sem API key, o fluxo base deve continuar a funcionar com regras locais e OCR.

## 9. Analise de faturas

### 9.1 Pipeline

1. Ingestao: imagem/PDF.
2. Pre-processamento:
   - Corrigir orientacao.
   - Melhorar contraste.
   - Detetar bordas.
3. OCR:
   - Vision framework on-device para MVP.
   - Fallback futuro com servico cloud se OCR local falhar.
4. Extracao estruturada:
   - Total.
   - Data.
   - Comerciante.
   - NIF.
   - Numero de fatura.
   - IVA.
   - Linhas principais.
5. Matching com transacoes candidatas:
   - Filtrar por janela temporal.
   - Filtrar por montante, se extraido.
   - Filtrar por banco/metodo quando houver pistas.
   - Usar IA para comparar comerciante, linhas da fatura, localizacao e notas.
6. Validacao:
   - Total da fatura bate com pagamento?
   - Data proxima da compra?
   - Comerciante semelhante?
7. Enriquecimento:
   - Atualizar pagamento.
   - Adicionar notas.
   - Anexar fatura.
   - Marcar como completo ou precisa de revisao.

### 9.2 Matching fatura-pagamento

Score de match:

- Montante igual: +50
- Data no mesmo dia: +20
- Data em janela de 3 dias: +10
- Comerciante semelhante: +20
- Localizacao compativel: +10
- Banco/metodo de pagamento compativel: +10
- IA considera match provavel: +20
- Ja selecionado manualmente pelo utilizador: +100

Estados:

- `auto_matched`: score >= 80
- `suggested_match`: score 50-79
- `needs_manual_match`: score < 50

Para o MVP, o score deterministico deve gerar a lista de candidatos. A IA deve receber apenas candidatos plausiveis, nao a base inteira, para reduzir custo, latencia e risco de matches errados.

## 10. UX da app

### 10.1 Ecras principais

1. Hoje
   - Compras de hoje
   - Total do dia
   - Drafts pendentes
   - Pendentes de fatura
   - Pendentes de reconciliacao

2. Historico
   - Lista filtravel
   - Pesquisa
   - Filtros por categoria, estado, cartao, comerciante
   - Filtros por banco

3. Calendario
   - Vista mensal
   - Indicadores de total por dia
   - Marcadores de dias com faturas pendentes
   - Tap num dia abre lista das transacoes desse dia
   - Alternancia mes/semana, se for util depois do MVP

4. Pagamento
   - Montante, comerciante, data, categoria
   - Banco
   - Estado
   - Indicador se veio de draft confirmado
   - Fatura anexada
   - Notas extraidas
   - Acoes: adicionar fatura, editar categoria, marcar como ignorado, combinar duplicados

5. Faturas
   - Inbox de faturas sem pagamento associado
   - Faturas processadas
   - Faturas com match sugerido
   - Faturas que precisam de revisao

6. Drafts
   - Eventos Apple Pay recebidos e ainda nao confirmados
   - Acoes rapidas para confirmar, descartar, editar e anexar fatura
   - Separacao clara entre drafts recentes e drafts antigos

7. Insights
   - Gastos por mes
   - Gastos por categoria
   - Comerciantes principais
   - Evolucao semanal/mensal

8. Definicoes
   - Cartoes monitorizados
   - Bancos
   - Categorias
   - Regras de comerciantes
   - API key Gemini
   - Exportacao CSV/JSON
   - Privacidade e sync

### 10.2 Estados visuais importantes

Cada pagamento deve comunicar rapidamente:

- Draft pendente
- Completo
- Sem fatura
- Precisa de reconciliacao
- Categoria sugerida
- Possivel duplicado
- Descartado, apenas em vista tecnica/historico de drafts
- Erro na analise da fatura
- Banco desconhecido

## 11. Privacidade e seguranca

Dados financeiros e faturas sao sensiveis. Decisoes recomendadas:

- Guardar dados localmente por defeito.
- Encriptar ficheiros de faturas em repouso, se possivel.
- Usar Face ID/Touch ID para abrir a app.
- Nao enviar faturas para servicos externos sem opcao explicita.
- Deixar claro quando Gemini/API externa esta ativa.
- Permitir desativar IA cloud e manter apenas processamento local.
- Separar texto OCR de ficheiro original.
- Permitir apagar todos os dados.
- Exportar dados em formato aberto.
- Se houver cloud, preferir CloudKit privado ou backend com encriptacao e politicas claras.

## 12. Observabilidade e qualidade de dados

O produto depende da qualidade do pipeline. Desde o MVP, guardar:

- Quantos eventos foram recebidos automaticamente via Shortcuts.
- Quantos viraram drafts.
- Quantos drafts foram confirmados.
- Quantos drafts foram descartados.
- Quantos ficaram incompletos.
- Quantos foram enriquecidos por fatura.
- Quantos foram categorizados automaticamente.
- Quantas sugestoes foram corrigidas.
- Quantas associacoes fatura-transacao foram feitas automaticamente.
- Quantas associacoes por IA foram corrigidas.
- Erros de OCR.
- Duplicados detetados.

Estes dados podem ficar locais, sem analytics externo.

## 13. Roadmap recomendado

### Validação ja concluída

- A automação Shortcuts `Transaction` corre com `Executar imediatamente`.
- A automação pode ser configurada para qualquer um de 5 cartões da Carteira.
- O Shortcuts recebe a transação como entrada.
- Os campos `Quantia`, `Comerciante` e `Nome` foram usados com sucesso em ações do Shortcuts.
- A app deve agora implementar a receção real desses campos, sem precisar de spike de discovery.

### Fase 1 - MVP de rececao, consulta e transacoes manuais

Objetivo: receber eventos do Shortcuts de forma robusta, nunca perder um evento de pagamento e permitir adicao manual.

Tarefas:

- App SwiftUI.
- Persistencia local.
- Modelo `Payment`.
- Modelo `Bank`.
- App Intent chamavel pelo Shortcut.
- Fluxo de draft apos evento recebido.
- Janela/sheet de confirmacao, descarte, edicao e fatura.
- Inbox de drafts pendentes.
- Lista de pagamentos.
- Vista de calendario simples.
- Detalhe de pagamento.
- Estados `pending_enrichment`, `complete`, `needs_reconciliation`.
- Edicao manual de montante, comerciante e categoria.
- Criacao manual de transacoes.
- Categorizacao automatica basica desde o inicio.
- Exportacao CSV.

### Fase 2 - Categorias e regras

Objetivo: reduzir edicao manual.

Tarefas:

- Modelo de categorias.
- Regras por comerciante.
- Normalizacao de nomes.
- Aplicar categoria automaticamente.
- UI para corrigir categoria.
- Aprendizagem simples a partir das correcoes.
- Pesquisa global sobre campos pesquisaveis.

### Fase 3 - Faturas

Objetivo: submeter faturas avulsas, extrair detalhes e associar a transacao correta.

Tarefas:

- Inbox de faturas sem pagamento associado.
- Submeter imagem/PDF sem escolher pagamento.
- Anexar imagem/PDF diretamente a pagamento, como fluxo alternativo.
- Capturar foto da fatura.
- OCR local com Vision.
- Guardar texto OCR.
- Extrair total, data e comerciante.
- Matching basico com pagamento.
- Notas estruturadas.

### Fase 4 - Reconciliacao

Objetivo: lidar com dados Apple Pay incompletos e melhorar matching com IA.

Tarefas:

- Integracao opcional com Gemini API.
- Matching assistido por IA entre faturas e transacoes candidatas.
- Importar extrato CSV/OFX manualmente.
- Matching entre extrato e pagamentos pendentes.
- Deteccao de duplicados.
- Regras para resolver conflitos.

### Fase 5 - Sync, backup e inteligencia

Objetivo: robustez e conveniencia.

Tarefas:

- CloudKit privado.
- Backup/exportacao automatica.
- Analise avancada de faturas.
- Sugestao IA de categorias.
- Insights mensais.

## 14. Decisoes tecnicas iniciais

Recomendacao para primeira implementacao:

- Plataforma: iOS
- Linguagem: Swift
- UI: SwiftUI
- Persistencia: SwiftData se target moderno, SQLite se quisermos mais controlo
- Automacao: App Intents + Apple Shortcuts
- OCR: Vision/VisionKit on-device
- IA opcional: Gemini API
- Sync: nenhum no MVP; CloudKit depois
- Backend: nenhum no MVP
- Exportacao: CSV e JSON

## 15. Riscos

### Risco 1: Apple Shortcuts nao entrega detalhes da transacao

Impacto: baixo/medio.

Mitigacao:

- Criar sempre draft pendente.
- Reconciliar com fatura ou extrato.
- Permitir edicao rapida.
- Tratar campos vazios ou formatos inesperados como edge cases de parsing.

### Risco 2: Automacao nao corre de forma 100% silenciosa

Impacto: medio/alto.

Mitigacao:

- Confirmar definicoes de Run Immediately.
- Evitar acoes no Shortcut que exijam confirmacao.
- Preferir App Intent simples e rapida.

### Risco 3: OCR de faturas portuguesas pode variar muito

Impacto: medio.

Mitigacao:

- Extrair primeiro apenas campos essenciais.
- Guardar texto bruto.
- Pedir revisao quando confianca baixa.
- Evoluir extratores por padroes reais.

### Risco 4: Duplicados

Impacto: medio.

Mitigacao:

- Deduplicar por janela temporal, cartao, montante e comerciante.
- Permitir combinar pagamentos.
- Guardar `raw_payload` e origem.

## 16. Definition of Done do MVP

O MVP esta pronto quando:

- Um pagamento Apple Pay dispara a automacao.
- A app cria um registo automaticamente.
- O evento recebido abre uma janela de draft.
- O utilizador consegue confirmar ou descartar o draft.
- O utilizador consegue adicionar fatura no draft.
- Fechar a janela nao perde o evento; fica em drafts pendentes.
- A app permite criar transacao manual.
- O utilizador consegue ver o pagamento na lista.
- O utilizador consegue ver pagamentos numa vista de calendario.
- O utilizador consegue editar montante, comerciante e categoria.
- A app categoriza automaticamente com regras basicas.
- Cada transacao tem banco como campo editavel/associavel.
- A app guarda o estado do pagamento.
- A app exporta CSV.
- O comportamento real do trigger Shortcuts esta documentado.
- Nao ha dependencia obrigatoria de backend.

## 17. Primeira tarefa de implementacao

Criar uma app iOS minima chamada FinTrackApp com:

- SwiftUI `PaymentsListView`
- Modelo `Payment`
- Modelo `Bank`
- Persistencia local
- App Intent `LogApplePayPaymentIntent`
- Modelo/estado de draft
- Janela de draft apos evento Apple Pay
- Criacao manual de pagamento
- Categorizacao automatica basica
- Vista de calendario
- Ecra tecnico temporario `ShortcutDebugView` que mostra o ultimo payload recebido

O fluxo de rececao do evento ja pode ser implementado com base na validacao pratica concluida.

## 18. Referencias

- Diagramas de fluxos e iteracoes da app - `docs/APP_FLOWS_MERMAID.md`
- Configuracao validada do Apple Shortcuts - `docs/SHORTCUT_SETUP.md`
- Apple Support: Transaction triggers in Shortcuts on iPhone or iPad - https://support.apple.com/guide/shortcuts/transaction-trigger-apd65c67538a/ios
- Apple Support: Enable or disable a personal automation in Shortcuts on iPhone or iPad - https://support.apple.com/guide/shortcuts/enable-or-disable-a-personal-automation-apd602971e63/ios
- Apple Developer: App Intents - https://developer.apple.com/documentation/appintents/app-intents
- Exemplo pratico nao-oficial: 1M Finance Wallet Automation Setup - https://finance.one-m.app/wallet-automation
