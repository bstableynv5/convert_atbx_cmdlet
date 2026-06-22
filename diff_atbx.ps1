function Diff-Atbx {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][Alias("A")][string]$Old,
        [Parameter(Mandatory = $true)][Alias("B")][string]$New,
        [string]$TempDir = ".diffatbx_temp",
        [string]$Output
    )
        
    begin {
    }
    
    process {

        try {
            # unpack-atbx creates non-existent dirs
            
            $OldDir = (Join-Path $TempDir "OLD")
            Unpack-Atbx -Name $Old -Master $OldDir

            $NewDir = (Join-Path $TempDir "NEW")
            Unpack-Atbx -Name $New -Master $NewDir

            # i don't like the -Output param (perfer > redirection) but neither of
            # $Host.UI.RawUI.IsStdOutRedirected
            # [System.Console]::IsOutputRedirected
            # were able to detect when redirection was happening.

            # no-pager dumps entire diff to screen non-interactively
            if ($Output) {
                (git --no-pager diff --no-index $OldDir $NewDir) -replace "diff --git", "`n`ndiff --git" > $Output
            }
            else {
                (git --no-pager diff --color=always --no-index $OldDir $NewDir) -replace "diff --git", "`n`ndiff --git" | Write-Output
            }
        }
        finally {
            # ctrl-c while in git diff pager kills script.
            # this ensures temp dir is always removed.
            Remove-Item -Path $TempDir -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    
    end {
        
    }
}