# FinTrackApp - Diagramas Mermaid

Data: 2026-06-08

Este documento descreve as principais iteracoes e fluxos da app em Mermaid. O objetivo e transformar o plano de produto num mapa visual para orientar implementacao, testes e decisoes de UX.

## 1. Ciclo de vida geral

```mermaid
flowchart TD
    Start([Inicio]) --> Source{Origem da transacao}

    Source -->|Apple Pay via Shortcuts| ShortcutEvent[Evento recebido do Shortcuts]
    Source -->|Manual| ManualCreate[Criar transacao manual]
    Source -->|Importacao futura| BankImport[Importar extrato bancario]
    Source -->|Fatura avulsa| ReceiptInbox[Submeter fatura para inbox]

    ShortcutEvent --> Draft[Criar draft]
    Draft --> DraftReview[Abrir janela de draft]
    DraftReview --> DraftDecision{Decisao do utilizador}

    DraftDecision -->|Confirmar| Confirmed[Transacao confirmada]
    DraftDecision -->|Descartar| Discarded[Draft descartado]
    DraftDecision -->|Fechar sem decidir| PendingDraft[Draft pendente]
    DraftDecision -->|Adicionar fatura| ReceiptAttached[Anexar fatura ao draft]

    ReceiptAttached --> Confirmed
    PendingDraft --> DraftReview

    ManualCreate --> AutoCategorize[Categorizacao automatica]
    BankImport --> Reconcile[Reconciliacao]
    ReceiptInbox --> ReceiptPipeline[OCR e analise]

    Confirmed --> AutoCategorize
    AutoCategorize --> Enrichment{Dados completos?}

    Enrichment -->|Sim| Complete[Pagamento completo]
    Enrichment -->|Nao| NeedsReview[Precisa de revisao]
    Enrichment -->|Falta fatura| MissingReceipt[Sem fatura]

    ReceiptPipeline --> MatchReceipt[Matching fatura-transacao]
    MatchReceipt --> Complete
    Reconcile --> Complete
    Reconcile --> NeedsReview

    Complete --> Consult[Consulta, pesquisa, calendario, insights]
    NeedsReview --> Consult
    MissingReceipt --> Consult
    Discarded --> DraftHistory[Historico tecnico de drafts]
```

## 2. Evento Apple Pay via Shortcuts

```mermaid
sequenceDiagram
    participant User as Utilizador
    participant Wallet as Apple Pay / Wallet
    participant Shortcuts as Apple Shortcuts
    participant AppIntent as App Intent
    participant App as FinTrackApp
    participant DB as Base local

    User->>Wallet: Faz pagamento com Apple Pay
    Wallet-->>Shortcuts: Dispara automacao Transaction
    Shortcuts->>Shortcuts: Le Shortcut Input
    Note over Shortcuts: Transaction, Card or Pass,<br/>Merchant, Amount, Name
    Shortcuts->>AppIntent: Executa LogApplePayPaymentIntent
    AppIntent->>App: Envia payload normalizado + raw_payload
    App->>DB: Guarda draft imediatamente
    App->>App: Infere banco, categoria e estado inicial
    App-->>User: Abre janela de draft
```

## 3. Janela de draft

```mermaid
flowchart TD
    DraftOpened[Janela de draft aberta] --> ShowFields[Mostrar dados recebidos]

    ShowFields --> Validate{Dados parecem validos?}
    Validate -->|Sim| SuggestedReady[Mostrar categoria sugerida]
    Validate -->|Nao| HighlightMissing[Destacar campos em falta]

    SuggestedReady --> UserAction{Acao do utilizador}
    HighlightMissing --> UserAction

    UserAction -->|Confirmar| Confirm[Confirmar transacao]
    UserAction -->|Editar| Edit[Editar campos]
    UserAction -->|Adicionar fatura| AddReceipt[Foto/PDF da fatura]
    UserAction -->|Descartar| Discard[Descartar draft]
    UserAction -->|Fechar| KeepDraft[Manter em drafts pendentes]

    Edit --> ReCategorize[Recalcular categoria]
    ReCategorize --> UserAction

    AddReceipt --> OCR[OCR local]
    OCR --> AIReceipt[Analise opcional com Gemini]
    AIReceipt --> AttachToDraft[Associar fatura ao draft]
    AttachToDraft --> UserAction

    Confirm --> DecideStatus{Qualidade dos dados}
    DecideStatus -->|Completo| Complete[Status complete]
    DecideStatus -->|Sem fatura| PendingEnrichment[Status pending_enrichment]
    DecideStatus -->|Dados insuficientes| NeedsReconciliation[Status needs_reconciliation]

    Discard --> Discarded[Status discarded]
    KeepDraft --> PendingDraft[Status draft]
```

## 4. Transacao manual

```mermaid
flowchart TD
    ManualStart[Adicionar transacao manual] --> FillFields[Preencher data, montante, comerciante, banco]
    FillFields --> OptionalFields[Adicionar cartao, notas, localizacao opcional]
    OptionalFields --> SuggestCategory[Sugerir categoria automaticamente]
    SuggestCategory --> CategoryDecision{Categoria correta?}

    CategoryDecision -->|Sim| SaveManual[Guardar transacao]
    CategoryDecision -->|Nao| UserCategory[Utilizador altera categoria]
    UserCategory --> RuleDecision{Aplicar como regra futura?}

    RuleDecision -->|Sim| SaveMerchantRule[Guardar regra comerciante-categoria]
    RuleDecision -->|Nao| SaveManual
    SaveMerchantRule --> SaveManual

    SaveManual --> ManualStatus{Tem dados suficientes?}
    ManualStatus -->|Sim| Complete[Status complete]
    ManualStatus -->|Nao| NeedsReview[Status needs_reconciliation]
```

## 5. Inbox de faturas avulsas

```mermaid
flowchart TD
    SubmitReceipt[Submeter fatura avulsa] --> ReceiptInbox[Guardar em inbox]
    ReceiptInbox --> Preprocess[Pre-processar imagem/PDF]
    Preprocess --> OCR[OCR local com Vision]
    OCR --> Extract[Extrair campos estruturados]

    Extract --> CandidateSearch[Encontrar transacoes candidatas]
    CandidateSearch --> DeterministicScore[Score deterministico]
    DeterministicScore --> EnoughCandidates{Ha candidatos plausiveis?}

    EnoughCandidates -->|Nao| NeedsManual[Precisa de associacao manual]
    EnoughCandidates -->|Sim| GeminiMatch[Matching assistido por Gemini]

    GeminiMatch --> Confidence{Confianca}
    Confidence -->|Alta| AutoAttach[Associar automaticamente]
    Confidence -->|Media| SuggestAttach[Mostrar sugestao ao utilizador]
    Confidence -->|Baixa| NeedsManual

    SuggestAttach --> UserDecision{Utilizador confirma?}
    UserDecision -->|Sim| AutoAttach
    UserDecision -->|Nao| NeedsManual

    AutoAttach --> EnrichPayment[Enriquecer pagamento]
    EnrichPayment --> SaveNotes[Guardar notas estruturadas]
    SaveNotes --> CompleteOrReview{Tudo consistente?}
    CompleteOrReview -->|Sim| Complete[Pagamento completo]
    CompleteOrReview -->|Nao| Review[Precisa de revisao]
```

## 6. Matching fatura-transacao

```mermaid
flowchart LR
    Receipt[Fatura analisada] --> Features[Features da fatura]
    Payment[Transacoes candidatas] --> PaymentFeatures[Features das transacoes]

    Features --> Score[Score deterministico]
    PaymentFeatures --> Score

    Score --> ScoreParts[Montante + Data + Comerciante + Banco + Cartao + Localizacao]
    ScoreParts --> CandidateList[Top candidatos]

    CandidateList --> Gemini{Gemini ativo?}
    Gemini -->|Nao| RuleOnly[Usar score deterministico]
    Gemini -->|Sim| AICompare[Comparar OCR, comerciante, linhas e contexto]

    AICompare --> FinalScore[Score final + explicacao]
    RuleOnly --> FinalScore

    FinalScore --> Decision{Resultado}
    Decision -->|>= 80| AutoMatch[Auto-match]
    Decision -->|50-79| SuggestedMatch[Match sugerido]
    Decision -->|< 50| ManualMatch[Manual]
```

## 7. Categorizacao automatica

```mermaid
flowchart TD
    Tx[Transacao ou draft] --> KnownMerchant{Comerciante conhecido?}

    KnownMerchant -->|Sim| MerchantRule[Aplicar regra do comerciante]
    KnownMerchant -->|Nao| AliasMatch{Alias conhecido?}

    AliasMatch -->|Sim| AliasRule[Normalizar comerciante e aplicar regra]
    AliasMatch -->|Nao| KeywordMatch{Keyword conhecida?}

    KeywordMatch -->|Sim| KeywordCategory[Aplicar categoria por keyword]
    KeywordMatch -->|Nao| ReceiptAvailable{Ha fatura analisada?}

    ReceiptAvailable -->|Sim| ReceiptCategory[Categoria por NIF/linhas da fatura]
    ReceiptAvailable -->|Nao| GeminiAvailable{Gemini ativo?}

    GeminiAvailable -->|Sim| GeminiCategory[Sugerir categoria com IA]
    GeminiAvailable -->|Nao| Uncategorized[Categoria Outro / precisa de revisao]

    MerchantRule --> Confidence[Guardar categoria + confianca]
    AliasRule --> Confidence
    KeywordCategory --> Confidence
    ReceiptCategory --> Confidence
    GeminiCategory --> Confidence
    Uncategorized --> Confidence

    Confidence --> UserCanEdit[Utilizador pode sempre alterar]
    UserCanEdit --> Changed{Categoria alterada?}
    Changed -->|Sim| LearnRule[Guardar aprendizagem opcional]
    Changed -->|Nao| Done[Manter categoria]
```

## 8. Estados da transacao

```mermaid
stateDiagram-v2
    [*] --> draft: Evento Shortcuts recebido
    [*] --> complete: Transacao manual completa
    [*] --> needs_reconciliation: Transacao manual incompleta

    draft --> complete: Confirmar com dados completos
    draft --> pending_enrichment: Confirmar sem fatura/detalhes
    draft --> needs_reconciliation: Confirmar com dados insuficientes
    draft --> discarded: Descartar
    draft --> draft: Fechar sem decidir

    pending_enrichment --> complete: Fatura associada / dados enriquecidos
    pending_enrichment --> needs_reconciliation: Conflito detectado

    needs_reconciliation --> complete: Utilizador corrige / extrato reconciliado / IA valida
    needs_reconciliation --> ignored: Utilizador ignora

    complete --> duplicate: Duplicado detectado
    duplicate --> complete: Duplicado resolvido

    discarded --> [*]
    ignored --> [*]
    complete --> [*]
```

## 9. Pesquisa global

```mermaid
flowchart TD
    Query[Pesquisa do utilizador] --> Normalize[Normalizar query]
    Normalize --> SearchIndex[Pesquisar indice local]

    SearchIndex --> PaymentFields[Campos da transacao]
    SearchIndex --> ReceiptFields[Campos da fatura]
    SearchIndex --> OCRFields[Texto OCR]
    SearchIndex --> NotesFields[Notas]
    SearchIndex --> MerchantFields[Comerciante e aliases]
    SearchIndex --> BankFields[Banco e cartao]

    PaymentFields --> Rank[Ranking de resultados]
    ReceiptFields --> Rank
    OCRFields --> Rank
    NotesFields --> Rank
    MerchantFields --> Rank
    BankFields --> Rank

    Rank --> Filters[Filtros: data, categoria, banco, estado, fatura]
    Filters --> Results[Lista de resultados]
    Results --> Detail[Abrir detalhe]
```

## 10. Vista de calendario

```mermaid
flowchart TD
    Calendar[Vista calendario] --> Month[Mes]
    Calendar --> Week[Semana futura/opcional]

    Month --> DayCells[Dias com totais]
    DayCells --> Indicators[Indicadores por estado]

    Indicators --> HasDrafts[Drafts pendentes]
    Indicators --> MissingReceipts[Sem fatura]
    Indicators --> NeedsReview[Precisa de revisao]
    Indicators --> Complete[Completo]

    DayCells --> SelectDay{Selecionar dia}
    SelectDay --> DaySummary[Resumo do dia]
    DaySummary --> DayTxs[Transacoes do dia]
    DayTxs --> PaymentDetail[Detalhe da transacao]
```

## 11. Gemini API opcional

```mermaid
flowchart TD
    NeedAI{Tarefa precisa de IA?} -->|Nao| LocalOnly[Usar regras locais]
    NeedAI -->|Sim| HasKey{API key configurada?}

    HasKey -->|Nao| Fallback[Fallback local + pedir revisao]
    HasKey -->|Sim| Consent{IA cloud ativa nas definicoes?}

    Consent -->|Nao| Fallback
    Consent -->|Sim| Minimize[Enviar apenas dados necessarios]

    Minimize --> Gemini[Chamada Gemini API]
    Gemini --> Validate[Validar resposta contra regras]
    Validate --> Confidence{Confianca suficiente?}

    Confidence -->|Sim| Apply[Aplicar sugestao]
    Confidence -->|Nao| Suggest[Mostrar como sugestao]

    Apply --> Audit[Guardar fonte, confianca e timestamp]
    Suggest --> Audit
    Fallback --> Audit
    LocalOnly --> Audit
```

## 12. Modelo de dados

O modelo de dados detalhado, incluindo o diagrama ER Mermaid, vive em `docs/DATA_MODEL.md`.

## 13. Roadmap visual

```mermaid
gantt
    title Roadmap FinTrackApp
    dateFormat  YYYY-MM-DD
    axisFormat  %d/%m

    section Fase 1
    App SwiftUI base                     :b1, 2026-06-17, 4d
    Persistencia local                   :b2, after b1, 3d
    App Intent Shortcuts                 :b3, after b2, 3d
    Drafts Apple Pay                     :b4, after b3, 4d
    Transacoes manuais                   :b5, after b4, 3d
    Calendario simples                   :b6, after b5, 3d

    section Fase 2
    Categorias e regras                  :c1, after b6, 4d
    Pesquisa global                      :c2, after c1, 3d
    Aprendizagem por correcao            :c3, after c2, 3d

    section Fase 3
    Inbox de faturas                     :d1, after c3, 3d
    OCR local                            :d2, after d1, 4d
    Matching deterministico              :d3, after d2, 4d

    section Fase 4
    Gemini API opcional                  :e1, after d3, 4d
    Matching assistido por IA            :e2, after e1, 4d
    Importacao de extratos               :e3, after e2, 4d

    section Fase 5
    CloudKit e backup                    :f1, after e3, 5d
    Insights avancados                   :f2, after f1, 5d
```
