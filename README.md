# Modo Mentor · Deck de Produção

Bundle pronto pra rodar do **deck oficial da Imersão Modo Mentor** —
Rodrigo Thomaz · RT Mentoring. 31 slides em 1920×1080, canvas preto + gold.

> Implementado a partir do handoff oficial em `claude.ai/design`
> (`rt-mentoring-design-system`). Estrutura idêntica ao protótipo, com bugs
> corrigidos e entry point limpo.

---

## Como usar

### Modo apresentação (palco / Zoom / Meet)

1. Abra `index.html` no Chrome (Edge / Firefox também rodam).
2. Clique em **Abrir deck interativo**.
3. Use as setas `←` `→` (ou `PgUp` `PgDn`, `Space`) pra navegar.
4. `R` reseta pro slide 1. `Home` / `End` vão pro início / fim.
5. Em fullscreen (`F11`), o stage escala automático sem letterbox preto.

### Modo print / PDF

1. No `index.html` da raiz, clique em **Modo print**.
2. `Ctrl+P` → destino "Salvar como PDF" → margens "Nenhuma" → cores "Sim".
3. Saída: PDF de 31 páginas, 1 slide por página, em 1920×1080.

### Onde estão os speaker notes

Cada slide tem uma fala correspondente em
`slides/modo-mentor/index.html` dentro de
`<script type="application/json" id="speaker-notes">`. O componente
`<deck-stage>` lê esse JSON e dispara `slideIndexChanged` pra qualquer
host externo que esteja escutando — útil pra integração com TelePrompter,
OBS, Zoom Annotations etc.

---

## Estrutura

```
deck/
├── index.html              Entry point (launcher com 2 botões)
├── README.md               Este arquivo
├── colors_and_type.css     Design tokens oficiais (RT Mentoring + Modo Mentor)
├── fonts/                  Montserrat — todas as variantes
├── assets/                 Logos, fotografia do evento, workbook
└── slides/
    ├── modo-mentor/
    │   ├── index.html          Deck principal (31 slides interativos)
    │   ├── index-print.html    Versão print
    │   ├── styles.css          Estilos locais do deck
    │   ├── deck-stage.js       Web component <deck-stage>
    │   └── image-slot.js       Web component <image-slot> (drag-and-drop)
    └── references/             Referências visuais do design
```

---

## O que o deck cobre

31 slides organizados em 5 blocos + abertura + fechamento:

| # | Slide | Bloco |
|---|-------|-------|
| 01–03 | Covers (photo · logo · type) | Abertura |
| 04 | Manifesto | Abertura |
| 05 | Bio Rodrigo Thomaz | Abertura |
| 06 | Statement "Clareza constrói direção" | Abertura |
| 07 | Ambiência muda o jogo | Abertura |
| 08–13 | Avatar · diálogos · nichos · ICP · quote Schwartz | **Bloco 01 — Avatar** |
| 14–15 | Promessa central + 3 produtos · quote Rodrigo | **Bloco 02 — Promessa** |
| 16–20 | Esteira de 5 produtos · ponte · quote rastros | **Bloco 03 — Esteira** |
| 21–24 | Autoridade · 3Ps Instagram · pitch elevador · quote perguntas | **Bloco 04 — Autoridade** |
| 25–27 | Funil AIDA · quote "se você fizer" | **Bloco 05 — Ação** |
| 28 | Closing statement "Sua mentoria merece vender" | Fechamento |
| 29–30 | CTA Aplicar mentoria · CTA próxima imersão | Fechamento |
| 31 | Obrigado | Fechamento |

---

## Bugs corrigidos no handoff

Durante o port pra produção, dois bugs foram resolvidos:

1. **Slide 1 — eyebrow vazio.** O original tinha
   `<span class="dot"></span><span></span>` (placeholder não preenchido).
   Implementado como `IMERSÃO PREMIUM · RT MENTORING` (padrão usado
   no resto do deck).
2. **Slide 11 — typo "Finças".** Trocado por **"Finanças"** no
   placeholder do `image-slot`.

Nenhum outro conteúdo foi alterado — copy, tipografia, paleta, ordem
dos slides e speaker notes mantidos exatamente como no handoff.

---

## Servindo o deck (opcional)

Pra abrir em outros dispositivos (tablet do operador, segunda tela), suba
um servidor local:

```bash
# Python 3
python -m http.server 8000

# Node (npx serve)
npx serve .
```

Depois acesse `http://<seu-ip>:8000/` na máquina cliente.

Hospedagem produção: qualquer servidor estático (Vercel, Netlify, S3,
GitHub Pages, Cloudflare Pages). Não há build step.

---

## Atualizando copy de slides

Para editar uma frase específica:

1. Abra `slides/modo-mentor/index.html` num editor.
2. Cada slide é uma `<section>` com comentário `<!-- NN · NOME -->`.
3. Edite o texto direto. Mantenha:
   - **UPPERCASE** em eyebrows, badges e section labels
   - **Sentence case** em headlines de hero/quote
   - Palavra de promessa envolvida em `<span class="gold">…</span>`
4. Atualize o speaker note correspondente no JSON do `<head>`.

Para mudar a paleta ou tipografia (não recomendado — fere o brand),
edite `colors_and_type.css` no nível dos tokens, nunca inline nos slides.

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
