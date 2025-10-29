$master_default = "ATBX_MASTER"
        
function Convert-Atbx {
    <#
    .SYNOPSIS
        This script will unzip or zip an ArcGIS Pro toolbox file (ATBX file).
    
    .DESCRIPTION
        This can be used for development work, where the unzipped atbx contents,
        which are all text files, can be checked into git. The reverse is also
        possible, which zips such unpacked contents back into a usable atbx file.
    
        This script has two modes (1) unpack and (2) pack.
    
        (1) Unpack unzips an atbx into a "master" folder, which is ideally the
        one checked into git. This "updates" the master (in a sense) with any
        changes made via the Arc Catalog (such as parameters). The code or other
        atbx metadata within the master can also be edited, checked in, etc. It
        should also be possible to unpack an atbx changed by another developer
        into your local master and merge toolboxes that way (possibly using git
        to resolve merge conflicts, etc).
        
        (2) Pack zips the master folder into an atbx. This allows one to create
        or replace an atbx with the changes made (and checked into git) within
        the master. These could be changes to code (or script paths to external
        code), parameter configuration, tool display names. It's even possible
        to create entirely new tools this way.
    
    .PARAMETER Action
        The action to perform. Must be "Pack" or "Unpack".

    .PARAMETER Name
        For unpacking, the name (with extension) or full path to the atbx.

        Examples:
          -Name MyGreat_Toolbox.atbx
          -Name I:\testing\MyGreat_Toolbox.atbx
        
        For packing, the name of the desired new/existing toolbox with or 
        without .atbx extension. Relative and absolute paths are acceptable. 
        All required parent folders for the destination will be created.

        Examples
          -Name MyGreat_Toolbox       ->  MyGreat_Toolbox.atbx
          -Name Another_Toolbox.atbx  ->  Another_Toolbox.atbx
          -Name C:\toolboxes\Las.atbx ->  C:\toolboxes\Las.atbx
          -Name C:\toolboxes\Las      ->  C:\toolboxes\Las.atbx

    .PARAMETER Date
        When packing a toolbox, this flag will make the script append the current
        date to the toolbox name in ISO8601 (YYYY-MM-DD) format following a _ 
        (underscore) separating character. Does nothing when unpacking.
        
        If the input Name already has a known date format appended in this manner, 
        it will be removed before the new date is appended. Any existing atbx is not 
        deleted, but if an atbx exists with the target filename, it will be 
        overwritten. This may be useful for making dated updates with the same "base"
        name as an existing atbx.

        Examples (assuming 2025-09-14 is current date)
        -Name Toolbox -Date                  ->  Toolbox_2025-09-14.atbx
        -Name Toolbox_2025-08-15.atbx -Date  ->  Toolbox_2025-09-14.atbx

    .PARAMETER Master
        Sets the "master" folder for unpacking/packing. Is "ATBX_MASTER" by default.
        May be useful for experimentally or temporarily working on a toolbox without
        disturbing the master. Can be an absolute or relative path. When unpacking, 
        all required parent folders in for the destination master will be created.

        Examples:
        -Action pack -Name temp -Master Temp_Master         ->  temp.atbx create from contents of .\Temp_Master
        -Action unpack -Name feral.atbx -Master temp\FERAL  ->  feral.atbx is unpacked into .\temp\FERAL
    #>

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][ValidateSet("Pack", "Unpack")][string]$Action,
        [Parameter(Mandatory = $true)][string]$Name,
        [switch]$Date,
        [string]$Master = $master_default
    )
    process {
        if ($Action -eq "Pack") {
            Pack-Atbx -Name $Name -Master $Master -Date:$Date
        }
        elseif ($Action -eq "Unpack") {
            Unpack-Atbx -Name $Name -Master $Master
        }
    }
}


function Pack-Atbx {
    <#
    .SYNOPSIS
        This script will zip an ArcGIS Pro toolbox file (ATBX file).

    .DESCRIPTION
        Pack zips the master folder into an atbx. This allows one to create
        or replace an atbx with the changes made (and checked into git) within
        the master. These could be changes to code (or script paths to external
        code), parameter configuration, tool display names. It's even possible
        to create entirely new tools this way. The packed atbx is always

    .PARAMETER Name
        The name of the desired new/existing toolbox with or without .atbx 
        extension. Relative and absolute paths are acceptable. All required
        parent folders for the destination will be created.

        Examples
          -Name MyGreat_Toolbox       ->  MyGreat_Toolbox.atbx
          -Name Another_Toolbox.atbx  ->  Another_Toolbox.atbx
          -Name C:\toolboxes\Las.atbx ->  C:\toolboxes\Las.atbx
          -Name C:\toolboxes\Las      ->  C:\toolboxes\Las.atbx

    .PARAMETER Date
        This flag will make the script append the current
        date to the toolbox name in ISO8601 (YYYY-MM-DD) format following a _ 
        (underscore) separating character. Does nothing when unpacking.
        
        If the input Name already has a known date format appended in this manner, 
        it will be removed before the new date is appended. Any existing atbx is not 
        deleted, but if an atbx exists with the target filename, it will be 
        overwritten. This may be useful for making dated updates with the same "base"
        name as an existing atbx.

        Examples (assuming 2025-09-14 is current date)
          -Name Toolbox -Date                  ->  Toolbox_2025-09-14.atbx
          -Name Toolbox_2025-08-15.atbx -Date  ->  Toolbox_2025-09-14.atbx

    .PARAMETER Master
        Sets the "master" folder for unpacking/packing. Is "ATBX_MASTER" by default.
        May be useful for experimentally or temporarily working on a toolbox without
        disturbing the master. Can be an absolute or relative path.

        Examples:
          -Action pack -Name temp -Master Temp_Master        ->  temp.atbx created from contents of .\Temp_Master
          -Action pack -Name good -Master T:\Why\TBContents  ->  good.atbx created from contents of T:\Why\TBContents
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [switch]$Date,
        [string]$Master = $master_default
    )

    process {

        $date_format = "yyyy-MM-dd" # ISO8601
        $sep = "_"
        
        # LeafBase itself will remove version periods from Name if Name doesn't
        # have an actual extension.
        $parent = Split-Path $Name -Parent
        $Name = (Split-Path $Name -Leaf).Replace(".atbx", "")

        if ($parent -eq "") {
            $parent = Get-Location
        }
        New-Item -Path $parent -ItemType Directory -Force -ErrorAction Stop | Out-Null # make destination dir

        $date_str = ""
        if ($Date) {
            $date_str = Get-Date -Format $date_format
            $date_str = "${sep}${date_str}"

            # attempt to clean date from input name
            $last_part = $Name.Split($sep)[-1] # ok if _ doesn't exist, gives full string
            try {
                [DateTime]$last_part | Out-Null # try converting from a known format ()
                $Name = $Name.Replace($sep + $last_part, "") # remove sep and date
            }
            catch [System.Exception] {
            }
        }

        $out_atbx = Join-Path $parent "${Name}${date_str}.atbx"
        Compress-Archive -Force -CompressionLevel NoCompression -DestinationPath $out_atbx -Path $Master\*
        # Push-Location $AtbxMaster
        # & $7zip a -tzip -mx0 ${out_atbx} *
        # Pop-Location
    }
}


function Unpack-Atbx {
    <#
    .SYNOPSIS
        This script will unzip an ArcGIS Pro toolbox file (ATBX file).

    .DESCRIPTION
        Unpack unzips an atbx into a "master" folder, which is ideally the
        one checked into git. This "updates" the master (in a sense) with any
        changes made via the Arc Catalog (such as parameters). The code or other
        atbx metadata within the master can also be edited, checked in, etc. It
        should also be possible to unpack an atbx changed by another developer
        into your local master and merge toolboxes that way (possibly using git
        to resolve merge conflicts, etc).
        
    .PARAMETER Name
        For unpacking, the name (with extension) or full path to the atbx.
        
        Examples:
          -Name MyGreat_Toolbox.atbx
          -Name I:\TheBadPlace\0_RESOURCE\test\ClickALot.atbx

    .PARAMETER Master
        Sets the "master" folder for unpacking/packing. Is "ATBX_MASTER" by default.
        May be useful for experimentally or temporarily working on a toolbox without
        disturbing the master. Can be an absolute or relative path. When unpacking, 
        all required parent folders in for the destination master will be created.

        Examples:
          -Action unpack -Name feral.atbx -Master FERAL       ->  feral.atbx is unpacked into .\FERAL
          -Action unpack -Name feral.atbx -Master temp\FERAL  ->  feral.atbx is unpacked into .\temp\FERAL
    #>

    [CmdletBinding()]    
    param (
        [Parameter(Mandatory = $true)][string]$Name,
        [string]$Master = $master_default
    )

    process {
        Expand-Archive -Force -Path $Name -DestinationPath $Master
        # & $7zip x $Name "-o${AtbxMaster}" -y
    }
}
