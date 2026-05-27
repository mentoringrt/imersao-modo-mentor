# Scripts do Modo Mentor Deck

## `sync-from-handoff.ps1`

Sincroniza o repo com um novo handoff exportado do **claude.ai/design**.

### Uso comum (auto-detect do ZIP em Downloads)

```powershell
.\scripts\sync-from-handoff.ps1
```

Ou da raiz do repo, duplo-clique em `sync.cmd`.

### Opções

| Flag | O que faz |
|------|-----------|
| `-ZipPath "C:\..."` | Caminho explícito do ZIP (em vez de auto-detectar) |
| `-DryRun` | Só mostra o diff. Não toca em nada. |
| `-Force` | Pula confirmação interativa |
| `-CommitMessage "..."` | Mensagem customizada do commit |
| `-SkipPush` | Faz commit local mas não pusha |

### Exemplos

```powershell
# Ver o que mudaria sem aplicar
.\scripts\sync-from-handoff.ps1 -DryRun

# Sync automático sem perguntar (CI / automação)
.\scripts\sync-from-handoff.ps1 -Force

# ZIP específico, commit message custom
.\scripts\sync-from-handoff.ps1 `
    -ZipPath "C:\Users\DELL\Downloads\handoff-v3.zip" `
    -CommitMessage "feat: novos slides de objeções e prova social"

# Revisar antes de pushar
.\scripts\sync-from-handoff.ps1 -SkipPush
# ... revisa com `git diff HEAD~1`
# ... se ok: git push
```

### O que o script faz

1. **Localiza** o ZIP em `~/Downloads/` (mais recente que casa com padrões `*rt-mentoring*`, `*modo-mentor*`, `*design-system-handoff*`)
2. **Extrai** em `$env:TEMP/mm-handoff-sync-<timestamp>/`
3. **Diff** com o estado atual do repo (excluindo `preview/`, `ui_kits/`, `uploads/`, `export/`, `slides/references/`)
4. **Preview** dos novos/modificados/removidos
5. **Pede confirmação** (a menos que `-Force`)
6. **Sincroniza** os arquivos, preservando o que é **nosso** (não vem do handoff):
   - `index.html` (launcher)
   - `README.md`
   - `.gitignore`
   - `sync.cmd`
   - `scripts/`
   - `.git/`
7. **Reaplica bugs corrigidos**:
   - Slide 1: eyebrow vazio → `IMERSÃO PREMIUM · RT MENTORING`
   - Slide 11: typo `Finças` → `Finanças`
8. **Git** add + commit (msg auto) + push
9. **Abre** a URL do Pages no Chrome (rebuilda em ~30s)

### Pré-requisitos

- PowerShell 5.1+ (já vem no Windows)
- `git` no PATH
- Estar dentro de `MODO MENTOR/deck/` (ou rodar via `sync.cmd`)
- Autenticação git já feita (HTTPS via gh CLI ou SSH)

### Troubleshooting

**"Nenhum ZIP candidato encontrado"**
Renomeie o ZIP pra incluir "rt-mentoring" ou "modo-mentor" no nome, OU passe `-ZipPath` explicitamente.

**"Estrutura inesperada"**
O ZIP do claude.ai/design deve ter uma pasta `project/` dentro. Se mudaram o formato, ajuste a função `Get-ChildItem ... Where-Object { $_.Name -eq 'project' }` no script.

**"ha mudancas nao commitadas"**
Há diffs locais não salvos. Ou commite antes (`git stash` / `git commit`), ou aceite seguir com `-Force` (sua mudança vai pro stage junto com o sync).

**Pages não atualizou**
Veja o status do build em `https://github.com/mentoringrt/imersao-modo-mentor/actions`. Build leva 30-90s. Se falhou, abre o log do action.
