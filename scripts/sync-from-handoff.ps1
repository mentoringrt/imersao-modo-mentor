<#
.SYNOPSIS
  Sincroniza o repo local com um novo handoff exportado do claude.ai/design.

.DESCRIPTION
  1. Localiza o ZIP do handoff (parametro -ZipPath ou auto-detecta o mais recente
     em ~/Downloads/ com padrao "*RT Mentoring*Design System*handoff*.zip" ou
     "*rt-mentoring-design-system*.zip").
  2. Extrai em diretorio temporario.
  3. Compara conteudo com deck/ atual (excluindo pastas nao usadas em deploy).
  4. Sincroniza: copia arquivos novos/modificados, remove os que sumiram.
  5. Preserva arquivos NOSSOS (index.html launcher, README.md, scripts/, .git/).
  6. Reaplica bugs corrigidos (eyebrow slide 1, typo "Fincas").
  7. Faz git add + commit + push, com mensagem descritiva automatica.
  8. Pages rebuilda em ~30s, abro a URL final no Chrome.

.PARAMETER ZipPath
  Caminho explicito pro ZIP. Se omitido, busca o mais recente em ~/Downloads/.

.PARAMETER DryRun
  So mostra o que mudaria, nao aplica nada.

.PARAMETER Force
  Pula confirmacao interativa.

.PARAMETER CommitMessage
  Mensagem do commit. Se omitida, gera automatica baseada no diff.

.PARAMETER SkipPush
  Faz commit local mas nao push (util pra revisar antes).

.EXAMPLE
  .\sync-from-handoff.ps1
  Pega o ZIP mais recente do Downloads, mostra preview, pede confirmacao, sync + push.

.EXAMPLE
  .\sync-from-handoff.ps1 -DryRun
  So mostra o que mudaria. Nao toca em nada.

.EXAMPLE
  .\sync-from-handoff.ps1 -ZipPath "C:\Users\DELL\Downloads\handoff-v2.zip" -Force
  Usa um ZIP especifico, sem perguntar nada.
#>

[CmdletBinding()]
param(
    [string]$ZipPath,
    [switch]$DryRun,
    [switch]$Force,
    [string]$CommitMessage,
    [switch]$SkipPush
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

# -------- Constants --------
$RepoRoot     = Split-Path -Parent $PSScriptRoot
$PagesUrl     = "https://mentoringrt.github.io/imersao-modo-mentor/"
$GitHubUrl    = "https://github.com/mentoringrt/imersao-modo-mentor"

# Pastas/arquivos do handoff que NAO entram no deploy
$ExcludePathsFromHandoff = @(
    'preview',
    'ui_kits',
    'uploads',
    'export',
    'slides/references'
)

# Arquivos NOSSOS que NUNCA devem ser sobrescritos pelo handoff
$PreservedFiles = @(
    'index.html',         # nosso launcher (handoff nao tem)
    'README.md',          # nosso (handoff tem README diferente)
    '.gitignore',
    'sync.cmd'
)
$PreservedDirs = @(
    '.git',
    'scripts'
)

# -------- Helpers --------
function Write-Section($title) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  $title" -ForegroundColor Cyan
    Write-Host ("=" * 70) -ForegroundColor DarkGray
}

function Write-Step($msg) {
    Write-Host "  -> " -NoNewline -ForegroundColor DarkGray
    Write-Host $msg
}

function Get-FileHashFast($path) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { return $null }
    (Get-FileHash -LiteralPath $path -Algorithm MD5).Hash
}

function Should-ExcludeFromHandoff($relPath) {
    foreach ($excl in $ExcludePathsFromHandoff) {
        if ($relPath -like "$excl*" -or $relPath -like "$excl/*" -or $relPath -like "$excl\*") {
            return $true
        }
    }
    return $false
}

function Should-PreserveInRepo($relPath) {
    # Top-level files preservados
    $topName = ($relPath -split '[\\/]')[0]
    if ($relPath -notmatch '[\\/]' -and $PreservedFiles -contains $topName) { return $true }
    # Diretorios preservados (qualquer arquivo dentro)
    foreach ($d in $PreservedDirs) {
        if ($topName -eq $d) { return $true }
    }
    return $false
}

# -------- 1. Localizar o ZIP --------
Write-Section "1. Localizando o ZIP do handoff"

if (-not $ZipPath) {
    $downloads = Join-Path $env:USERPROFILE "Downloads"
    $candidates = Get-ChildItem -Path $downloads -Filter "*.zip" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "rt.?mentoring.?(design.?system|handoff)" -or
            $_.Name -match "modo.?mentor" -or
            $_.Name -match "design.?system.?handoff"
        } |
        Sort-Object LastWriteTime -Descending

    if ($candidates.Count -eq 0) {
        Write-Host ""
        Write-Host "  Nenhum ZIP candidato encontrado em $downloads" -ForegroundColor Yellow
        Write-Host "  Padroes procurados: '*rt-mentoring*', '*modo-mentor*', '*design-system-handoff*'" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "  Passe o caminho explicito:" -ForegroundColor White
        Write-Host '    .\sync-from-handoff.ps1 -ZipPath "C:\caminho\completo.zip"' -ForegroundColor DarkGray
        exit 1
    }

    $ZipPath = $candidates[0].FullName
    Write-Step "Auto-detectado: $($candidates[0].Name)"
    Write-Step "Tamanho: $([math]::Round($candidates[0].Length/1MB, 1)) MB"
    Write-Step "Modificado: $($candidates[0].LastWriteTime)"
    if ($candidates.Count -gt 1) {
        Write-Step "($($candidates.Count - 1) outros candidatos mais antigos foram ignorados)"
    }
}

if (-not (Test-Path -LiteralPath $ZipPath)) {
    throw "ZIP nao encontrado: $ZipPath"
}

# -------- 2. Extrair em temp --------
Write-Section "2. Extraindo handoff em temp"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$tempRoot  = Join-Path $env:TEMP "mm-handoff-sync-$timestamp"
New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

Expand-Archive -Path $ZipPath -DestinationPath $tempRoot -Force

# Suportamos DOIS formatos de export do claude.ai/design:
#
#  Formato A (handoff antigo): zip contem `<algum-nome>/project/...`
#    O deck principal vive em `slides/modo-mentor/index.html`.
#
#  Formato B (Canva atual):   zip contem arquivos na raiz, sem subpasta `project/`.
#    O deck principal vive em `Modo Mentor - Deck Completo.html` na raiz.
#
# Em ambos os casos, o "source dir" e' o diretorio que contem `colors_and_type.css`.

# 1) Procura subpasta project/ (formato A)
$sourceDir = Get-ChildItem -Path $tempRoot -Directory -Recurse -Depth 3 |
    Where-Object { $_.Name -eq 'project' -and (Test-Path (Join-Path $_.FullName 'colors_and_type.css')) } |
    Select-Object -First 1

# 2) Se nao achou, ve se a raiz do zip ja tem os arquivos (formato B)
if (-not $sourceDir) {
    if (Test-Path (Join-Path $tempRoot 'colors_and_type.css')) {
        $sourceDir = Get-Item $tempRoot
    }
}

# 3) Senao, qualquer subpasta de primeiro nivel que tenha o CSS
if (-not $sourceDir) {
    $sourceDir = Get-ChildItem -Path $tempRoot -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName 'colors_and_type.css') } |
        Select-Object -First 1
}

if (-not $sourceDir) {
    throw "Arquivos do design system nao encontrados no ZIP (esperado colors_and_type.css em algum nivel)."
}

# Detecta formato pelo nome do diretorio fonte
$isLegacyFormat = ($sourceDir.Name -eq 'project')

Write-Step "Extraido em: $tempRoot"
Write-Step ("Formato detectado: " + $(if ($isLegacyFormat) { "LEGACY (project/ subpasta)" } else { "CANVA (raiz plana)" }))
Write-Step "Source: $($sourceDir.FullName)"

# -------- 3. Diff --------
Write-Section "3. Calculando diff com o repo atual"

$handoffFiles = Get-ChildItem -Path $sourceDir.FullName -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($sourceDir.FullName.Length + 1).Replace('\', '/')
    if (Should-ExcludeFromHandoff $rel) { return }
    [pscustomobject]@{
        Rel       = $rel
        FullPath  = $_.FullName
        Hash      = Get-FileHashFast $_.FullName
        Size      = $_.Length
    }
}

$repoFiles = Get-ChildItem -Path $RepoRoot -Recurse -File | ForEach-Object {
    $rel = $_.FullName.Substring($RepoRoot.Length + 1).Replace('\', '/')
    if (Should-PreserveInRepo $rel) { return }
    [pscustomobject]@{
        Rel       = $rel
        FullPath  = $_.FullName
        Hash      = Get-FileHashFast $_.FullName
        Size      = $_.Length
    }
}

$handoffByRel = @{}; $handoffFiles | ForEach-Object { $handoffByRel[$_.Rel] = $_ }
$repoByRel    = @{}; $repoFiles    | ForEach-Object { $repoByRel[$_.Rel]    = $_ }

# Remove do handoff os arquivos preservados (nao queremos que o handoff
# sobrescreva nosso launcher index.html, nosso README, etc).
foreach ($preservedName in $PreservedFiles) {
    if ($handoffByRel.ContainsKey($preservedName)) {
        $handoffByRel.Remove($preservedName)
    }
}
foreach ($preservedDir in $PreservedDirs) {
    @($handoffByRel.Keys) | Where-Object { $_ -like "$preservedDir/*" -or $_ -like "$preservedDir\*" } |
        ForEach-Object { $handoffByRel.Remove($_) }
}

$added    = @()
$modified = @()
$removed  = @()
$same     = 0

foreach ($rel in $handoffByRel.Keys) {
    if (-not $repoByRel.ContainsKey($rel)) {
        $added += $rel
    } elseif ($handoffByRel[$rel].Hash -ne $repoByRel[$rel].Hash) {
        $modified += $rel
    } else {
        $same++
    }
}
foreach ($rel in $repoByRel.Keys) {
    if (-not $handoffByRel.ContainsKey($rel)) {
        $removed += $rel
    }
}

Write-Host ""
Write-Host "  Novos     : " -NoNewline; Write-Host $added.Count -ForegroundColor Green
Write-Host "  Modificados: " -NoNewline; Write-Host $modified.Count -ForegroundColor Yellow
Write-Host "  Removidos : " -NoNewline; Write-Host $removed.Count -ForegroundColor Red
Write-Host "  Iguais    : " -NoNewline; Write-Host $same -ForegroundColor DarkGray

if (($added.Count + $modified.Count + $removed.Count) -eq 0) {
    Write-Host ""
    Write-Host "  >> Nada mudou. Repo ja esta sincronizado com este handoff." -ForegroundColor Green
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
    exit 0
}

# Detalhes
function Show-FileList($title, $list, $color) {
    if ($list.Count -eq 0) { return }
    Write-Host ""
    Write-Host "  $title" -ForegroundColor $color
    $list | Select-Object -First 30 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
    if ($list.Count -gt 30) {
        Write-Host "    ... (mais $($list.Count - 30) arquivos)" -ForegroundColor DarkGray
    }
}

Show-FileList "Novos arquivos:" $added Green
Show-FileList "Modificados:" $modified Yellow
Show-FileList "Removidos (serao deletados do repo):" $removed Red

if ($DryRun) {
    Write-Host ""
    Write-Host "  >> DRY-RUN. Nada foi alterado." -ForegroundColor Cyan
    Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
    exit 0
}

# -------- 4. Confirmacao --------
if (-not $Force) {
    Write-Host ""
    $answer = Read-Host "  Aplicar essas mudancas? [s/N]"
    if ($answer -notmatch '^[sSyY]') {
        Write-Host "  Cancelado pelo usuario." -ForegroundColor Yellow
        Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
        exit 0
    }
}

# -------- 5. Verificar estado do git --------
Write-Section "4. Verificando estado do git"

Push-Location $RepoRoot
try {
    $branch = (& git rev-parse --abbrev-ref HEAD).Trim()
    $dirty  = (& git status --porcelain).Trim()
    Write-Step "Branch: $branch"
    if ($dirty) {
        Write-Host ""
        Write-Host "  AVISO: ha mudancas nao commitadas:" -ForegroundColor Yellow
        $dirty -split "`n" | Select-Object -First 10 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }
        if (-not $Force) {
            $answer = Read-Host "  Continuar mesmo assim? [s/N]"
            if ($answer -notmatch '^[sSyY]') {
                Write-Host "  Cancelado." -ForegroundColor Yellow
                Pop-Location
                Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
                exit 0
            }
        }
    } else {
        Write-Step "Working tree limpo. OK."
    }
} finally {
    Pop-Location
}

# -------- 6. Sync de arquivos --------
Write-Section "5. Sincronizando arquivos"

# Copia novos + modificados
foreach ($rel in @($added) + @($modified)) {
    $srcPath = $handoffByRel[$rel].FullPath
    $dstPath = Join-Path $RepoRoot $rel.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    $dstDir  = Split-Path -Parent $dstPath
    if (-not (Test-Path $dstDir)) { New-Item -ItemType Directory -Force -Path $dstDir | Out-Null }
    Copy-Item -LiteralPath $srcPath -Destination $dstPath -Force
}
Write-Step "Copiados: $($added.Count + $modified.Count) arquivos"

# Remove os que sumiram
foreach ($rel in $removed) {
    $dstPath = Join-Path $RepoRoot $rel.Replace('/', [System.IO.Path]::DirectorySeparatorChar)
    if (Test-Path $dstPath) {
        Remove-Item -LiteralPath $dstPath -Force
    }
}
if ($removed.Count -gt 0) {
    Write-Step "Removidos: $($removed.Count) arquivos"
}

# Limpa diretorios vazios criados pela remocao
Get-ChildItem -Path $RepoRoot -Recurse -Directory |
    Where-Object {
        $_.FullName -notmatch '\\\.git(\\|$)' -and
        $_.FullName -notmatch '\\scripts(\\|$)' -and
        (Get-ChildItem $_.FullName -Force).Count -eq 0
    } |
    ForEach-Object { Remove-Item -LiteralPath $_.FullName -Force -ErrorAction SilentlyContinue }

# -------- 7. Reaplicar bugs corrigidos --------
Write-Section "6. Reaplicando correcoes manuais"

# Aplica em QUALQUER .html no repo (path do deck principal varia entre formatos:
#   legacy: slides/modo-mentor/index.html
#   canva:  Modo Mentor - Deck Completo.html (raiz)
# Aplicar em todos cobre os dois e tambem o bloco isolado "Mente e Coragem".

$htmlFiles = Get-ChildItem -Path $RepoRoot -Filter "*.html" -Recurse -File |
    Where-Object {
        $_.FullName -notmatch '\\\.git\\' -and
        $_.Name -ne 'index.html'  # nao mexe no nosso launcher
    }

$fixedAny = $false
foreach ($f in $htmlFiles) {
    $content  = Get-Content -Raw -LiteralPath $f.FullName -Encoding UTF8
    $original = $content
    $fixedHere = @()

    # Bug 1: eyebrow slide 1 vazio
    $badEyebrowStart = '<span class="eyebrow"><span>IMERS' + [char]0x00C3 + 'O</span><span class="dot"></span><span>'
    if ($content -match [regex]::Escape($badEyebrowStart)) {
        $goodEyebrow = '<span class="eyebrow"><span>IMERS' + [char]0x00C3 + 'O PREMIUM</span><span class="dot">' + [char]0x00B7 + '</span><span>RT MENTORING</span></span>'
        $content = $content -replace [regex]::Escape($badEyebrowStart + "`r`n</span></span>"), $goodEyebrow
        $content = $content -replace [regex]::Escape($badEyebrowStart + "`n</span></span>"),   $goodEyebrow
        $fixedHere += "eyebrow"
    }

    # Bug 2: typo "Fincas" -> "Financas"
    if ($content -match ("Fin" + [char]0x00E7 + "as ")) {
        $content = $content -replace ("Fin" + [char]0x00E7 + "as "), ("Finan" + [char]0x00E7 + "as ")
        $fixedHere += "typo-financas"
    }

    if ($content -ne $original) {
        # Escreve UTF-8 sem BOM
        [System.IO.File]::WriteAllText($f.FullName, $content, (New-Object System.Text.UTF8Encoding $false))
        Write-Step "Fixes aplicados em $($f.Name): $($fixedHere -join ', ')"
        $fixedAny = $true
    }
}

if (-not $fixedAny) {
    Write-Step "Bugs ja estavam corretos. Nada a reaplicar."
}

# -------- 8. Git commit + push --------
Write-Section "7. Commit + push"

Push-Location $RepoRoot
try {
    & git add . | Out-Null

    $staged = (& git diff --cached --name-status) -split "`n" | Where-Object { $_ }
    if ($staged.Count -eq 0) {
        Write-Host "  Nada para commitar." -ForegroundColor Yellow
        Pop-Location
        Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue
        exit 0
    }

    Write-Step "Staged: $($staged.Count) arquivos"

    if (-not $CommitMessage) {
        $parts = @()
        if ($added.Count    -gt 0) { $parts += "$($added.Count) novos" }
        if ($modified.Count -gt 0) { $parts += "$($modified.Count) modificados" }
        if ($removed.Count  -gt 0) { $parts += "$($removed.Count) removidos" }
        $summary = $parts -join ", "
        $zipName = Split-Path -Leaf $ZipPath
        $CommitMessage = "sync: handoff ($summary) [from $zipName]"
    }

    Write-Step "Commit: $CommitMessage"
    & git commit -m $CommitMessage | Out-Null

    if ($SkipPush) {
        Write-Host ""
        Write-Host "  >> Commit feito local. -SkipPush ativo, push nao executado." -ForegroundColor Cyan
        Write-Host "     Quando quiser publicar: git push" -ForegroundColor DarkGray
    } else {
        Write-Step "Push -> origin/$branch ..."
        & git push origin $branch | Out-Null
        Write-Step "Push OK."
    }
} finally {
    Pop-Location
}

# -------- 9. Cleanup + abrir URL --------
Remove-Item -Recurse -Force $tempRoot -ErrorAction SilentlyContinue

Write-Section "Pronto"
Write-Host ""
Write-Host "  Repo:  $GitHubUrl" -ForegroundColor White
Write-Host "  Pages: $PagesUrl" -ForegroundColor White
Write-Host ""
Write-Host "  GitHub Pages rebuilda em ~30 segundos." -ForegroundColor DarkGray
Write-Host "  Vou abrir a URL no Chrome agora." -ForegroundColor DarkGray

Start-Process "chrome.exe" -ArgumentList $PagesUrl -ErrorAction SilentlyContinue

Write-Host ""
