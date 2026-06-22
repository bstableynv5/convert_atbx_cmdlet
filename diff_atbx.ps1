function Diff-Atbx {
    <#
    .SYNOPSIS
        Uses git diff to show changes between two ArcGIS Pro Toolboxes (ATBX files).
    .DESCRIPTION
        Relies on Unpack-Atbx which is also provided by this module. Also relies
        on git diff. Presents diff in non-interactive (no-pager) mode.
    .PARAMETER Old
        The "A" or "Changed From" toolbox.
        .PARAMETER New
        The "B" or "Changed To" toolbox.
    .PARAMETER Output
        A file to write the diff into.
    .PARAMETER TempDir
        Temporary directory where Old and New atbxs will be unzipped for diffing.
    .EXAMPLE
        Diffs v1 and v1.2 versions of a toolbox.

            Diff-Atbx Toolbox_v1.0.atbx Toolbox_v1.2.atbx
        
        Same but uses parameter names.

            Diff-Atbx -Old Toolbox_v1.0.atbx -New Toolbox_v1.2.atbx

        Save diff to a file.

            Diff-Atbx -Old Toolbox_v1.0.atbx -New Toolbox_v1.2.atbx -Output changes.diff
    #>
    
    
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