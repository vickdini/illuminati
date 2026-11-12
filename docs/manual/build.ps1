# Builds the Illuminati manual in every language with XeLaTeX.
# Usage: ./build.ps1            (all languages)
#        ./build.ps1 es fr      (only these)
param([string[]]$Languages = @('en', 'es', 'fr', 'de', 'it', 'pt'))

$ErrorActionPreference = 'Stop'
Push-Location $PSScriptRoot
try {
    foreach ($lang in $Languages) {
        # Two passes so the table of contents and references are filled in.
        foreach ($pass in 1, 2) {
            xelatex -interaction=nonstopmode -halt-on-error "manual-$lang.tex" | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "manual-$lang.tex failed; see manual-$lang.log" }
        }
        Write-Host "manual-$lang.pdf"
    }
    Remove-Item *.aux, *.out, *.toc -ErrorAction SilentlyContinue
} finally {
    Pop-Location
}
