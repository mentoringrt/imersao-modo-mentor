# Modo Mentor · Deck de Produção

Bundle pronto pra rodar do **deck oficial da Imersão Modo Mentor** —
Rodrigo Thomaz · RT Mentoring. **42 slides** em 1920×1080, canvas preto + gold.

> Implementado a partir do handoff oficial em `claude.ai/design` (Canva).
> Estrutura idêntica ao protótipo, com bugs corrigidos automaticamente
> a cada sync (ver `scripts/sync-from-handoff.ps1`).

---

## Live

- **Apresentação:** https://mentoringrt.github.io/imersao-modo-mentor/
- **Repo:** https://github.com/mentoringrt/imersao-modo-mentor

---

## Como usar

### Modo apresentação (palco / Zoom / Meet)

1. Abra `index.html` no Chrome (Edge / Firefox também rodam).
2. Clique em **Abrir deck completo**.
3. Use as setas `←` `→` (ou `PgUp` `PgDn`, `Space`) pra navegar.
4. `R` reseta pro slide 1. `Home` / `End` vão pro início / fim.
5. Em fullscreen (`F11`), o stage escala automático sem letterbox preto.

### Bloco isolado Mente + Coragem

Útil pra workshops curtos ou apresentações focadas em mentalidade
sem o método completo de venda. Abra `Modo Mentor - Bloco Mente e Coragem.html`.

### Modo print / PDF

`Ctrl+P` direto no `Modo Mentor - Deck Completo.html` → destino "Salvar como PDF"
→ margens "Nenhuma" → cores "Sim". Saída: PDF de 42 páginas, 1 slide por página.

---

## Estrutura

```
deck/
├── index.html                                Launcher (3 cards: completo, bloco isolado, repo)
├── Modo Mentor - Deck Completo.html          Deck principal — 42 slides
├── Modo Mentor - Bloco Mente e Coragem.html  Bloco isolado (8 slides finais)
├── colors_and_type.css                       Design tokens oficiais
├── base-styles.css                           Estilos base do deck
├── extra-styles.css                          Estilos dos blocos novos (MENTE/CORAGEM)
├── deck-stage.js                             Web component <deck-stage>
├── image-slot.js                             Web component <image-slot>
├── assets/                                   Logos, fotos auditório, workbook (16 imgs)
├── fonts/                                    Montserrat 9 variantes
├── screens/                                  Screenshots de design (s1, s2-donut, s3-phd…)
├── uploads/                                  Fotos de referência (WhatsApp recentes)
└── scripts/
    └── sync-from-handoff.ps1                 Auto-sync com novo handoff do claude.ai/design
```

---

## Bugs corrigidos no handoff

1. **Slide 1 — eyebrow vazio.** Original tem placeholder não preenchido.
   Reaplicado como `IMERSÃO PREMIUM · RT MENTORING`.
2. **Slide nichos — typo "Finças".** Trocado por **"Finanças"**.

> Esses 2 fixes são **reaplicados automaticamente** pelo script `sync.cmd`
> a cada sync com o claude.ai/design. Não precisa lembrar.

---

## Sincronizando com novo handoff do claude.ai/design

Quando você adicionar/editar slides no claude.ai/design e exportar o ZIP:

1. **Baixe o ZIP** em `~/Downloads/` (qualquer nome — script auto-detecta).
2. **Duplo-clique em `sync.cmd`** (ou rode `.\scripts\sync-from-handoff.ps1`).
3. O script:
   - Acha o ZIP mais recente em Downloads
   - **Detecta automaticamente o formato** (raiz plana ou subpasta `project/`)
   - Mostra preview do diff (novos, modificados, removidos)
   - Pede confirmação
   - Substitui arquivos no repo (preservando launcher + README + scripts)
   - Reaplica os 2 bugs corrigidos
   - Commit + push automático
   - Abre a URL do Pages (rebuilda em ~30s)

Veja `scripts/README.md` pra opções avançadas (`-DryRun`, `-Force`, `-SkipPush`, etc).

---

## Brand reminder

- Canvas: **preto** (`#000`).
- Acento: **gold** (`#B8924F` família — gradiente até `#8F6F36`).
- Tipo: **Montserrat** 800/900 em UPPERCASE pra display, 400/500 pro body.
- Forest green (`#0C1F17`) e Cormorant Garamond ficam **reservados para o
  workbook impresso**, não pro deck digital.
- Sem emoji. Sem motivação vazia. Promessa sempre com número ou prazo.
- O middle-dot `·` é o separador oficial em metadata strips.

> *Mais do que informar, a marca conduz.*
> *Mais do que motivar, a marca estrutura.*
> *Mais do que inspirar, a marca gera resultado.*

---

## Histórico de blocos (42 slides organizados)

| # | Bloco | Slides |
|---|-------|--------|
| - | **Abertura** | Cover photo + cover logo + cover type + Manifesto + Bio Rodrigo + Statement + Ambiência |
| 01 | **Avatar** | Section divider + O que é avatar + Diálogos internos + Nichos (Finanças/Emagrecimento) + ICP Matrix + Quote Schwartz |
| 02 | **Promessa** | Section divider + Tipos de promessa (entrada/principal/premium) + Quote mente preparada |
| 03 | **Esteira** | Section divider + 5 produtos (ladder) + Ponte diagram + Ponte v2 photo + Quote rastros |
| 04 | **Autoridade** | Section divider + 3Ps Instagram + Pitch elevador + Quote perguntas |
| 05 | **Ação** | Section divider + Funil AIDA + Quote "se você fizer" |
| 06 | **Mente** *(novo)* | Section divider + New Mind + Foco 80/20 + Fórmula PHD + Comunicação 80/20 |
| 07 | **Coragem** *(novo)* | Section divider + Pergunta que dói + Caderno + Lei imutável + Frase pra gravar |
| - | **Fechamento** | Closing statement + CTA Aplicar + CTA Próxima imersão + Obrigado |
