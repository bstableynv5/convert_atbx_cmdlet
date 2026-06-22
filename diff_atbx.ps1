function Diff-Atbx {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$A,
        [Parameter(Mandatory = $true)][string]$B,
        [string]$TempDir = ".diffatbx_temp"
    )
        
    begin {
        . $PSScriptRoot\convert_atbx.ps1
    }
    
    process {

        try {
            $ADir = (Join-Path $TempDir "A")
            Unpack-Atbx -Name $A -Master $ADir

            $BDir = (Join-Path $TempDir "B")
            Unpack-Atbx -Name $B -Master $BDir

            git diff --no-index $ADir $BDir
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