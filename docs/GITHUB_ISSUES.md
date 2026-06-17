# GitHub Issues propostas

Baseado em:

- `docs/PRODUCT_AND_TECHNICAL_PLAN.md`
- `docs/DATA_MODEL.md`
- `docs/APP_FLOWS_MERMAID.md`
- `docs/SHORTCUT_SETUP.md`

Repositorio alvo: `miguel-garcia-marques/financialTracker`

---

## 1. Configurar Shortcut final para chamar a FinTrackApp

Labels: `shortcuts`, `integration`, `fase-1`

### Contexto

A validação prática do Shortcuts foi concluída em 2026-06-17. A automação `Transaction` consegue correr com `Executar imediatamente`, receber a transação como entrada e usar campos como `Quantia`, `Comerciante` e `Nome`. Quando o App Intent existir, a automação temporária que cria nota deve ser substituída pela chamada real à FinTrackApp.

### Tarefas

- Criar/configurar automação `Transaction` final.
- Manter `Executar imediatamente`.
- Manter `Notificar quando executado` desligado.
- Usar `Ao tocar com qualquer um de 5 cartões da Carteira`.
- Passar `Transacao`, `Cartao ou passe`, `Comerciante`, `Quantia` e `Nome` para o App Intent da FinTrackApp.
- Remover a ação temporária de criar nota quando o fluxo real estiver funcional.
- Fazer teste real de baixo valor e confirmar que a app cria draft.

### Criterios de aceitacao

- O Shortcut final chama a FinTrackApp.
- Um pagamento real cria um draft na app.
- A automação continua sem notificação.
- O setup final fica alinhado com `docs/SHORTCUT_SETUP.md`.

---

## 2. Criar base SwiftUI local-first da app

Labels: `ios`, `swiftui`, `fase-1`

### Contexto

O MVP deve ser uma app iOS nativa, local-first, com SwiftUI e persistencia local.

### Tarefas

- Criar projeto SwiftUI inicial.
- Definir estrutura de navegação principal.
- Criar ecrãs base: Hoje, Historico, Calendario, Faturas, Drafts, Insights e Definicoes.
- Adicionar shell visual simples para estados vazios.
- Garantir que a app corre em simulador iOS.

### Criterios de aceitacao

- A app compila e abre no simulador.
- A navegação principal permite aceder aos ecrãs base do MVP.
- Não há dependência de backend para abrir ou usar a app.

---

## 3. Implementar persistencia local e modelo Payment

Labels: `data-model`, `persistence`, `fase-1`

### Contexto

`Payment` é a entidade central da app e deve suportar drafts incompletos, transações manuais e dados brutos vindos do Shortcuts.

### Tarefas

- Escolher SwiftData ou SQLite para a persistencia inicial.
- Implementar `Payment` com os campos definidos em `docs/DATA_MODEL.md`.
- Usar decimal para `amount`, nunca float.
- Guardar `raw_payload` e `structured_notes` como JSON.
- Implementar enums `PaymentSource` e `PaymentStatus`.
- Adicionar timestamps `created_at`, `updated_at`, `transaction_at`, `confirmed_at` e `discarded_at`.

### Criterios de aceitacao

- É possivel criar, listar, atualizar e apagar pagamentos localmente.
- Drafts podem existir com campos incompletos.
- Pagamentos `discarded` não entram nos totais financeiros normais.

---

## 4. Implementar modelos Bank e PaymentMethod

Labels: `data-model`, `fase-1`

### Contexto

Banco e método de pagamento são dados de primeira classe para filtrar, inferir origem e mapear `Card or Pass` do Shortcuts.

### Tarefas

- Implementar modelo `Bank`.
- Implementar modelo `PaymentMethod`.
- Suportar aliases de banco.
- Guardar `shortcut_card_label` no método de pagamento.
- Permitir ativar/desativar bancos e métodos sem apagar histórico.

### Criterios de aceitacao

- Um pagamento pode estar associado a banco e método de pagamento.
- A app consegue inferir banco a partir de `shortcut_card_label` quando houver configuração.
- Métodos desativados continuam disponíveis no histórico.

---

## 5. Criar App Intent para registar pagamento Apple Pay

Labels: `ios`, `shortcuts`, `fase-1`

### Contexto

A app deve receber eventos do Apple Shortcuts e guardar imediatamente um draft para nunca perder uma transação.

### Tarefas

- Criar App Intent `Registar Pagamento Apple Pay`.
- Aceitar campos `transaction`, `card_or_pass`, `merchant`, `amount` e `name`.
- Normalizar `amount`, `currency`, `merchant_name`, `transaction_name`, `card_label` e `triggered_at`.
- Guardar sempre o `raw_payload` completo.
- Criar `Payment` com `source = apple_pay_shortcut` e `status = draft`.

### Criterios de aceitacao

- O Intent aparece como acao no Shortcuts.
- Ao executar o Intent, é criado um draft local.
- Mesmo com campos em falta, o evento fica persistido com `raw_payload`.

---

## 6. Criar janela de revisão de draft

Labels: `ux`, `drafts`, `fase-1`

### Contexto

Após receber um evento Apple Pay, a app deve abrir uma janela/sheet rápida para confirmar, descartar, editar ou anexar fatura.

### Tarefas

- Mostrar quantia, comerciante, nome da transação, cartão/passe, banco, categoria sugerida, data/hora e estado da fatura.
- Adicionar ações: confirmar, descartar, editar campos, adicionar fatura e guardar como pendente.
- Se fechar sem decisão, manter `status = draft`.
- Ao confirmar, escolher entre `complete`, `pending_enrichment` e `needs_reconciliation`.
- Ao descartar, marcar `status = discarded`.

### Criterios de aceitacao

- Um draft pode ser confirmado, descartado ou deixado pendente.
- Campos incompletos são visíveis ao utilizador.
- Confirmar sem fatura marca corretamente o estado de enriquecimento.

---

## 7. Criar inbox de drafts pendentes

Labels: `ux`, `drafts`, `fase-1`

### Contexto

Eventos recebidos sem decisão imediata devem ficar numa inbox para revisão posterior.

### Tarefas

- Criar ecrã de drafts pendentes.
- Separar drafts recentes e antigos.
- Permitir confirmar, descartar, editar e anexar fatura a partir da lista.
- Excluir drafts descartados das consultas financeiras normais.

### Criterios de aceitacao

- Drafts pendentes são recuperáveis depois de fechar a janela inicial.
- Ações rápidas atualizam o estado do draft.
- Drafts descartados só aparecem em vista técnica/histórico de drafts.

---

## 8. Implementar criação manual de transações

Labels: `payments`, `ux`, `fase-1`

### Contexto

Além de Apple Pay, a app deve permitir adicionar transações manualmente.

### Tarefas

- Criar formulário de nova transação manual.
- Campos: montante, data, comerciante, banco, método de pagamento e notas.
- Definir `source = manual`.
- Sugerir categoria automaticamente.
- Permitir alterar categoria antes de guardar.

### Criterios de aceitacao

- O utilizador consegue criar uma transação manual completa.
- Transações incompletas são guardadas como `needs_reconciliation`.
- A categoria sugerida é editável.

---

## 9. Implementar lista, detalhe e filtros de pagamentos

Labels: `payments`, `ux`, `fase-1`

### Contexto

O utilizador deve conseguir consultar compras de forma cronológica e abrir o detalhe de cada pagamento.

### Tarefas

- Criar lista cronológica de pagamentos.
- Criar detalhe de pagamento.
- Mostrar montante, comerciante, data, categoria, banco, estado, origem, fatura e notas.
- Adicionar filtros por categoria, estado, cartão, comerciante e banco.
- Excluir `discarded` por defeito.

### Criterios de aceitacao

- Pagamentos aparecem por ordem cronológica.
- O detalhe mostra os campos essenciais e estados visuais.
- Filtros podem ser combinados.

---

## 10. Criar calendário simples de compras

Labels: `calendar`, `ux`, `fase-1`

### Contexto

O MVP deve incluir vista mensal com totais por dia e indicadores de pendências.

### Tarefas

- Criar vista mensal.
- Mostrar total por dia.
- Indicar dias com drafts, faturas pendentes e pagamentos que precisam de revisão.
- Ao tocar num dia, abrir resumo e lista de transações desse dia.

### Criterios de aceitacao

- O calendário mostra totais corretos por dia.
- Estados pendentes ficam visíveis no dia correspondente.
- Selecionar um dia navega para as transações desse dia.

---

## 11. Implementar categorias iniciais e regras determinísticas

Labels: `categorization`, `fase-2`

### Contexto

A primeira versão deve categorizar automaticamente todos os pagamentos que conseguir usando regras simples e auditáveis.

### Tarefas

- Criar modelo `Category` com categorias iniciais.
- Criar modelo `MerchantRule`.
- Implementar normalização simples de comerciante.
- Aplicar regras por comerciante, alias e keyword.
- Guardar confiança e origem da sugestão.

### Criterios de aceitacao

- Comerciantes conhecidos como Continente, Pingo Doce, Lidl, Uber, Bolt, Galp e Farmacia recebem categoria automaticamente.
- O utilizador pode alterar qualquer categoria sugerida.
- A sugestão guarda fonte e confiança.

---

## 12. Implementar aprendizagem por correção de categoria

Labels: `categorization`, `ux`, `fase-2`

### Contexto

Quando o utilizador corrige uma categoria, a app deve conseguir aprender para reduzir edição manual futura.

### Tarefas

- Ao alterar categoria, permitir aplicar só ao pagamento atual.
- Permitir aplicar a pagamentos futuros do mesmo comerciante.
- Permitir aplicar também a pagamentos antigos semelhantes.
- Criar ou atualizar `MerchantRule` quando aplicável.

### Criterios de aceitacao

- Correções manuais prevalecem sobre sugestões automáticas.
- Regras criadas pelo utilizador são aplicadas em novos pagamentos.
- A aplicação retroativa é opcional.

---

## 13. Implementar pesquisa global local

Labels: `search`, `fase-2`

### Contexto

A app deve permitir pesquisa global sobre pagamentos, bancos, cartões, categorias, notas, faturas e OCR.

### Tarefas

- Definir índice ou query local para os campos pesquisáveis.
- Pesquisar comerciante, montante, data, banco, cartão, categoria e notas.
- Incluir dados de faturas e OCR quando existirem.
- Incluir `raw_payload` apenas em modo debug.
- Adicionar filtros sobre resultados.

### Criterios de aceitacao

- Uma pesquisa encontra pagamentos por comerciante, banco, categoria e texto de notas.
- Texto OCR fica pesquisável após processamento de fatura.
- `raw_payload` não aparece em pesquisa normal.

---

## 14. Criar modelo Receipt e inbox de faturas

Labels: `receipts`, `data-model`, `fase-3`

### Contexto

Faturas podem ser submetidas sem pagamento associado e reconciliadas posteriormente.

### Tarefas

- Implementar modelo `Receipt`.
- Guardar ficheiro original localmente.
- Permitir imagem e PDF.
- Criar inbox de faturas sem pagamento associado.
- Permitir anexar fatura diretamente a um pagamento.
- Implementar estados `analysis_status` e `match_status`.

### Criterios de aceitacao

- Uma fatura pode existir sem `payment_id`.
- Uma fatura pode ser anexada diretamente a um pagamento.
- Ficheiro original e metadados ficam persistidos.

---

## 15. Implementar OCR local para faturas

Labels: `receipts`, `ocr`, `fase-3`

### Contexto

O MVP deve usar Vision/VisionKit on-device para extrair texto de imagens/PDF de faturas.

### Tarefas

- Adicionar ingestão de foto/PDF.
- Pré-processar imagem quando aplicável: orientação, contraste e bordas.
- Executar OCR local.
- Guardar `ocr_text` e `ocr_confidence`.
- Marcar análise como `processed`, `failed` ou `needs_review`.

### Criterios de aceitacao

- Texto OCR é persistido na fatura.
- Falhas de OCR ficam visíveis para revisão.
- Texto OCR entra na pesquisa global.

---

## 16. Implementar matching determinístico fatura-transação

Labels: `receipts`, `matching`, `fase-3`

### Contexto

Antes de usar IA, a app deve gerar candidatos por score determinístico baseado em montante, data, comerciante, banco, cartão e localização.

### Tarefas

- Implementar `ReceiptPaymentMatch`.
- Filtrar candidatos por janela temporal.
- Pontuar montante, data, comerciante, banco/método e localização.
- Definir estados `auto_matched`, `suggested_match` e `needs_manual_match`.
- Associar automaticamente apenas quando score for alto.
- Mostrar sugestões quando score for médio.

### Criterios de aceitacao

- Score >= 80 associa automaticamente.
- Score 50-79 cria sugestão para confirmação.
- Score < 50 exige associação manual.
- Uma decisão aceite atualiza `Receipt.payment_id`.

---

## 17. Adicionar integração Gemini opcional

Labels: `ai`, `gemini`, `privacy`, `fase-4`

### Contexto

Gemini deve ser uma camada auxiliar opcional para faturas, categorização e matching, sem bloquear o fluxo local.

### Tarefas

- Adicionar definição para API key Gemini.
- Adicionar toggle explícito para IA cloud.
- Não chamar Gemini sem consentimento/configuração.
- Enviar apenas dados mínimos necessários.
- Guardar sugestão, confiança, fonte e explicação.
- Implementar fallback local quando Gemini estiver desativado.

### Criterios de aceitacao

- A app funciona sem API key.
- Chamadas externas só acontecem quando IA cloud está ativa.
- Sugestões de IA nunca substituem correções manuais.

---

## 18. Implementar exportação CSV/JSON

Labels: `export`, `privacy`, `fase-1`

### Contexto

O utilizador deve conseguir exportar dados em formato aberto desde o MVP.

### Tarefas

- Exportar pagamentos para CSV.
- Exportar dados completos para JSON.
- Excluir ou incluir `raw_payload` conforme opção explícita.
- Garantir que drafts descartados não entram por defeito na exportação financeira.

### Criterios de aceitacao

- O utilizador consegue gerar CSV de pagamentos.
- JSON preserva campos estruturados.
- Dados técnicos sensíveis exigem opção explícita.

---

## 19. Implementar privacidade local e bloqueio biométrico

Labels: `privacy`, `security`, `fase-5`

### Contexto

Dados financeiros e faturas são sensíveis. A app deve ser local-first e protegida por defeito.

### Tarefas

- Adicionar opção de bloqueio com Face ID/Touch ID.
- Garantir que ficheiros de fatura são guardados localmente.
- Avaliar encriptação de faturas em repouso.
- Adicionar ação para apagar todos os dados.
- Explicar no ecrã de definições quando serviços externos estão ativos.

### Criterios de aceitacao

- A app pode exigir biometria ao abrir.
- Existe opção clara para apagar dados locais.
- IA/cloud é transparente e desativável.

---

## 20. Criar métricas locais de qualidade de dados

Labels: `observability`, `fase-5`

### Contexto

O produto depende da qualidade de receção, categorização, OCR e matching. Métricas locais ajudam a perceber falhas sem analytics externo.

### Tarefas

- Contar eventos recebidos via Shortcuts.
- Contar drafts confirmados, descartados e incompletos.
- Contar pagamentos categorizados automaticamente e corrigidos.
- Contar faturas OCR processadas, falhadas e revistas.
- Contar matches automáticos, sugeridos e corrigidos.
- Expor estes dados em vista técnica/local.

### Criterios de aceitacao

- Métricas são locais e não enviadas para analytics externo.
- A vista técnica ajuda a diagnosticar problemas de payload, OCR e matching.
- Correções do utilizador ficam refletidas nas contagens.
