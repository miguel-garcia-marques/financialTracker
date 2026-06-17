# FinTrackApp - Configuracao Apple Shortcuts

Data: 2026-06-17

Este documento regista a configuracao confirmada para receber transacoes Apple Pay via Apple Shortcuts.

## 1. Estado da validacao

Validacao pratica concluida.

Confirmado:

- A automacao pode usar o trigger `Transaction`.
- A automacao pode correr com `Executar imediatamente`.
- `Notificar quando executado` pode ficar desligado.
- O trigger pode ser configurado para `Ao tocar com qualquer um de 5 cartoes da Carteira`.
- O Shortcuts consegue receber a transacao como entrada.
- O Shortcuts consegue usar campos da transacao em acoes seguintes.

Exemplo observado:

- `Quantia`: `8,70 €`
- `Comerciante`: `Ji YuanJi Yuan`
- Data/hora do teste: 17 de junho de 2026

## 2. Campos confirmados

Campos disponiveis na entrada `Transacao`:

- `Transacao`
- `Cartao ou passe`
- `Comerciante`
- `Quantia`
- `Nome`

Mapeamento recomendado para a app:

| Shortcuts | Campo normalizado |
| --- | --- |
| `Transacao` | `transaction` / `raw_payload.transaction` |
| `Cartao ou passe` | `card_or_pass` / `card_label` |
| `Comerciante` | `merchant` / `merchant_name` |
| `Quantia` | `amount` + `currency` |
| `Nome` | `name` / `transaction_name` |

## 3. Configuracao atual de automacao

Trigger:

- App: Shortcuts
- Automacao pessoal: `Transaction`
- Quando: `Ao tocar com qualquer um de 5 cartoes da Carteira`
- Execucao: `Executar imediatamente`
- Notificacoes: `Notificar quando executado` desligado

Acao temporaria validada:

- Receber transacao como entrada.
- Mostrar notificacao com `Quantia`.
- Criar nota com `Quantia`, `Comerciante` e `Nome`.

Acao final esperada:

- Executar App Intent da FinTrackApp.
- Passar `Transacao`, `Cartao ou passe`, `Comerciante`, `Quantia` e `Nome`.
- A app cria um `draft` local.
- A app abre a janela de draft para confirmar, descartar, editar ou anexar fatura.

## 4. Regras de parsing

`Quantia` deve ser tratada como input formatado e nao como decimal garantido.

Regras:

- Aceitar virgula decimal, exemplo `8,70 €`.
- Extrair moeda quando vier embebida no texto.
- Assumir `EUR` como default quando a moeda nao vier explicita.
- Guardar sempre o valor original no `raw_payload`.
- Se o parsing falhar, criar draft sem `amount` normalizado e marcar para revisao.

`Comerciante` e `Nome` devem ser guardados separadamente.

Regras:

- `Comerciante` alimenta `merchant_name`.
- `Nome` alimenta `transaction_name`.
- Se forem iguais ou quase iguais, manter ambos no raw payload e escolher `merchant_name` como display principal.
- Se `Comerciante` vier vazio, usar `Nome` como fallback visual.

`Cartao ou passe` deve alimentar inferencia de banco.

Regras:

- Tentar match com `PaymentMethod.shortcut_card_label`.
- Se houver match, preencher `payment_method_id` e `bank_id`.
- Se nao houver match, guardar `card_label` e marcar banco como desconhecido/editavel.

## 5. Implicacao para roadmap

O spike de discovery ja nao e necessario.

A primeira tarefa tecnica passa a ser implementar:

- App Intent da FinTrackApp.
- Parsing robusto dos cinco campos confirmados.
- Persistencia do `raw_payload`.
- Criacao de `Payment` com `status = draft`.
- Abertura da janela de draft.
