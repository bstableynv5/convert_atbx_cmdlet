function Diff-Atbx {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][Alias("A")][string]$Old,
        [Parameter(Mandatory = $true)][Alias("B")][string]$New,
        [string]$TempDir = ".diffatbx_temp"
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

            # no-pager dumps entire diff to screen non-interactively
            git --no-pager diff --no-index $OldDir $NewDir
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