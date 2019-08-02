<#
 .SYNOPSIS
Report on Disk Hogs
.DESCRIPTION
Returns a list of the largest directories in use on the local machine
.NOTES
Copyright Keith Garner, All rights reserved.
.PARAMETER Start
Start of the search, usually c:\
.PARAMETER Path
Location of a custom rules *.csv file, otherwise use the default table
.LINK
http://keithga.wordpress.com
#>

[cmdletbinding()]
param(
    $Start = 'c:\',
    $path
)

###########################################################

$WatchList = @( 
    [pscustomobject] @{ Folder = 'c:\*'; SizeMB = '500' }
    [pscustomobject] @{ Folder = 'C:\$Recycle.Bin'; SizeMB = '100' }
    [pscustomobject] @{ Folder = 'c:\Program Files'; SizeMB = '0' }
    [pscustomobject] @{ Folder = 'C:\Program Files\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'C:\Program Files (x86)'; SizeMB = '0' }
    [pscustomobject] @{ Folder = 'C:\Program Files (x86)\Adobe\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'C:\Program Files (x86)\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'C:\ProgramData\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'C:\ProgramData'; SizeMB = '0' }
    [pscustomobject] @{ Folder = 'C:\Windows'; SizeMB = '0' }
    [pscustomobject] @{ Folder = 'C:\Windows\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'c:\users'; SizeMB = '0' }
    [pscustomobject] @{ Folder = 'C:\Users\*'; SizeMB = '100' }
    [pscustomobject] @{ Folder = 'C:\Users\*\*'; SizeMB = '500' }
    [pscustomobject] @{ Folder = 'C:\Users\*\AppData\Local\Microsoft\*'; SizeMB = '1000' }
    [pscustomobject] @{ Folder = 'C:\Users\*\AppData\Local\*'; SizeMB = '400' }
)

###########################################################

function parse-directoryrecurse {
    [cmdletbinding()]
    param( 
        [parameter(Mandatory=$true, ValueFromPipeline=$true)] [string] $path,
        [object] $ControlList
     )
    process {

        if ( $Path.split('\').length -le 3 ) {
            Write-Progress -Activity "Processing  [$Path]" -PercentComplete ( [math]::min( 100, $script:RunningTotal / $script:EstimatedTotal * 85 ) )
        }

        $DirTotal = 0
        $Items = $path | 
            get-childitem -force -ErrorAction SilentlyContinue | 
            where-object { ! $_.Attributes.HasFlag([System.IO.FileAttributes]::ReparsePoint) } 
        foreach ( $Item in $items ) {

            if ( $item.PSIsContainer ) {
                # Folders
                $NewLength = parse-directoryrecurse $Item.fullName -ControlList $ControlList
            }
            else {
                # Files
                $NewLength = $Item.Length
                $script:RunningTotal += $NewLength
            }

            $bFound = $False
            if ( $Item.FullName -in $ControlList.Path ) {
                $SizeRequired = $ControlList | 
                    Where-Object { $_.Path -eq $Item.FullName } |
                    Select-Object -first 1 |
                    ForEach-Object Size 

                if ( ( $SizeRequired * 1024 * 1024 ) -lt $NewLength ) {
                    $bFound = $True
                    $script:ResultTable += [PSCustomObject] @{
                        path = $item.FullName
                        Size = $NewLength.Tostring({N0}).PadLeft($script:PadSize,' ') 
                    }
                    write-verbose "$($NewLength.Tostring({N0}).PadLeft(20,' '))    Path: $($Item.FullName)"
                }
            }

            if ( !$bFound ) {
                $DirTotal += $NewLength 
            }

        }

        $DirTotal | Write-Output

    }

}

###########################################################

write-verbose "Generate a groupings Table"
if ( $Path ) {
    $WatchList = import-csv $path
}

$ControlList = foreach ( $Item in $WatchList ) { 
    get-item $Item.Folder -force -ErrorAction SilentlyContinue | %{ [pscustomobject]@{ Path = $_.FullName ; Size = 0 + $Item.SizeMB } }
} 

$ControlList | write-verbose

###################
write-verbose "Calculate Disk Size"

$script:RunningTotal = 0

get-volume -driveletter ($start[0]) | 
    ForEach-Object { 
        $Script:PadSize = $_.Size.ToString("N0").Length + 1
        $script:EstimatedTotal = $_.Size - $_.SizeRemaining
    } 

$script:EstimatedTotal | write-verbose

###################

$script:ResultTable = @()

$remainder = parse-directoryrecurse -Path $Start -controlList $ControlList

$script:ResultTable += [PSCustomObject] @{ path = 'c:\'; Size = $remainder.Tostring({N0}).PadLeft($script:PadSize,' ')  }

$script:ResultTable | write-output