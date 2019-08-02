function New-IsoFile
{
  <#
      .Synopsis
      Creates a new .iso file

      .Description
      The New-IsoFile cmdlet creates a new .iso file containing content from chosen folders

      .Example
      New-IsoFile "c:\tools","c:Downloads\utils"

      This command creates a .iso file in $env:temp folder (default location) that contains c:\tools and c:\downloads\utils folders. The folders themselves are included at the root of the .iso image.

      .Example
      New-IsoFile -FromClipboard -Verbose

      Before running this command, select and copy (Ctrl-C) files/folders in Explorer first.

      .Example
      dir c:\WinPE | New-IsoFile -Path c:\temp\WinPE.iso -BootFile "${env:ProgramFiles(x86)}\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\efisys.bin" -Media DVDPLUSR -Title "WinPE"

      This command creates a bootable .iso file containing the content from c:\WinPE folder, but the folder itself isn't included.
      Boot file etfsboot.com can be found in Windows ADK. Refer to IMAPI_MEDIA_PHYSICAL_TYPE enumeration for possible media types: http://msdn.microsoft.com/en-us/library/windows/desktop/aa366217(v=vs.85).aspx

      .Notes
      NAME:  New-IsoFile
      AUTHOR: Chris Wu
      LASTEDIT: 03/23/2016 14:46:50
      Source: https://gallery.technet.microsoft.com/scriptcenter/New-ISOFile-function-a8deeffd
  #>

  [CmdletBinding(DefaultParameterSetName='Source')]
  Param(
    [parameter(Position=1,Mandatory=$true,ValueFromPipeline=$true, ParameterSetName='Source')]
    $Source,
    [parameter(Position=2)]
    [string]$Path = "$env:temp\$((Get-Date).ToString('yyyyMMdd-HHmmss.ffff')).iso",
    [ValidateScript({Test-Path -LiteralPath $_ -PathType Leaf})]
    [string]$BootFile = $null,
    [ValidateSet('CDR','CDRW','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','BDR','BDRE')]
    [string] $Media = 'DVDPLUSRW_DUALLAYER',
    [string]$Title = (Get-Date).ToString("yyyyMMdd-HHmmss.ffff"),
    [switch]$Force,
    [parameter(ParameterSetName='Clipboard')]
    [switch]$FromClipboard
  )

  Begin
  {
    ($cp = new-object System.CodeDom.Compiler.CompilerParameters).CompilerOptions = '/unsafe'
    if (!('ISOFile' -as [type]))
    {
      Add-Type -CompilerParameters $cp -TypeDefinition @'
public class ISOFile  
{
  public unsafe static void Create(string Path, object Stream, int BlockSize, int TotalBlocks)
  {
    int bytes = 0;
    byte[] buf = new byte[BlockSize];
    var ptr = (System.IntPtr)(&bytes);
    var o = System.IO.File.OpenWrite(Path);
    var i = Stream as System.Runtime.InteropServices.ComTypes.IStream;
  
    if (o != null) {
      while (TotalBlocks-- > 0) {
        i.Read(buf, BlockSize, ptr); o.Write(buf, 0, bytes);
      }
      o.Flush(); o.Close();
    }
  }
}
'@
    }

    if ($BootFile)
    {
      if('BDR','BDRE' -contains $Media) { Write-Warning "Bootable image doesn't seem to work with media type $Media" }
      ($Stream = New-Object -ComObject ADODB.Stream -Property @{Type=1}).Open()  # adFileTypeBinary
      $Stream.LoadFromFile((Get-Item -LiteralPath $BootFile).Fullname)
      ($Boot = New-Object -ComObject IMAPI2FS.BootOptions).AssignBootImage($Stream)
    }

    $MediaType = @('UNKNOWN','CDROM','CDR','CDRW','DVDROM','DVDRAM','DVDPLUSR','DVDPLUSRW','DVDPLUSR_DUALLAYER','DVDDASHR','DVDDASHRW','DVDDASHR_DUALLAYER','DISK','DVDPLUSRW_DUALLAYER','HDDVDROM','HDDVDR','HDDVDRAM','BDROM','BDR','BDRE')

    Write-Verbose -Message "Selected media type is $Media with value $($MediaType.IndexOf($Media))"
    Write-CMLogEntry -Value "Selected media type is $Media with value $($MediaType.IndexOf($Media))" -Severity 1
    ($Image = New-Object -com IMAPI2FS.MsftFileSystemImage -Property @{VolumeName=$Title}).ChooseImageDefaultsForMediaType($MediaType.IndexOf($Media))

    if (!($Target = New-Item -Path $Path -ItemType File -Force:$Force -ErrorAction SilentlyContinue)) { Write-Error -Message "Cannot create file $Path. Use -Force parameter to overwrite if the target file already exists."; break }
  }

  Process
  {
    if($FromClipboard)
    {
      if($PSVersionTable.PSVersion.Major -lt 5) { Write-Error -Message 'The -FromClipboard parameter is only supported on PowerShell v5 or higher'; break }
      $Source = Get-Clipboard -Format FileDropList
    }

    foreach($item in $Source)
    {
      if($item -isnot [System.IO.FileInfo] -and $item -isnot [System.IO.DirectoryInfo])
      {
        $item = Get-Item -LiteralPath $item
      }

      if($item)
      {
        Write-Verbose -Message "Adding item to the target image: $($item.FullName)"
        Write-CMLogEntry -Value "Adding item to the target image: $($item.FullName)" -Severity 1
        try { $Image.Root.AddTree($item.FullName, $true) } catch { Write-Error -Message ($_.Exception.Message.Trim() + ' Try a different media type.') }
      }
    }
  }

  End
  {
    if ($Boot) { $Image.BootImageOptions=$Boot }
    $Result = $Image.CreateResultImage()
    [ISOFile]::Create($Target.FullName,$Result.ImageStream,$Result.BlockSize,$Result.TotalBlocks)
    Write-Verbose -Message "Target image ($($Target.FullName)) has been created"
    Write-CMLogEntry -Value "Target image ($($Target.FullName)) has been created" -Severity 1
    $Target
  }
}


$Debug = $False
<#
If (!$Debug) 
{ 
    $tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
    $UAAComputerName = $TSEnv.Value("UAAComputerName")
}
#>
# Create Archive folder if it doesn't exist for this log file and for sending logs
$TestPath = Test-Path -path c:\Archive
If (!$TestPath) { $LogsDirectory = New-Item -Path 'c:\Archive' -Force -ItemType Directory }
Else { $LogsDirectory = 'C:\Archive' }

function Write-CMLogEntry {
    param (
        [parameter(Mandatory = $true, HelpMessage = 'Value added to the log file.')]
        [ValidateNotNullOrEmpty()]
        [string]$Value,
        [parameter(Mandatory = $true, HelpMessage = 'Severity for the log entry. 1 for Informational, 2 for Warning and 3 for Error.')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('1', '2', '3')]
        [string]$Severity,
        [parameter(Mandatory = $false, HelpMessage = 'Name of the log file that the entry will written to.')]
        [ValidateNotNullOrEmpty()]
        [string]$FileName = 'CreateISO.log'
    )
    # Determine log file location
    $LogFilePath = Join-Path -Path $LogsDirectory -ChildPath $FileName
		
    # Construct time stamp for log entry
    $Time = -join @((Get-Date -Format 'HH:mm:ss.fff'), '+', (Get-WmiObject -Class Win32_TimeZone | Select-Object -ExpandProperty Bias))
		
    # Construct date for log entry
    $Date = (Get-Date -Format 'MM-dd-yyyy')
		
    # Construct context for log entry
    $Context = $([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
		
    # Construct final log entry
    $LogText = "<![LOG[$($Value)]LOG]!><time=""$($Time)"" date=""$($Date)"" component=""PackageMapping"" context=""$($Context)"" type=""$($Severity)"" thread=""$($PID)"" file="""">"
		
    # Add value to log file
    try {
        Out-File -InputObject $LogText -Append -NoClobber -Encoding Default -FilePath $LogFilePath -ErrorAction Stop
    }
    catch {
        Write-Warning -Message "Unable to append log entry to CreateISO.log file. Error message at line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    }
}


# Code to create the ISO file

Write-CMLogEntry -Value '***********************************************************' -Severity 1
Write-CMLogEntry -Value 'Beginning creation of ISO file for backup' -Severity 1

# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
#$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition

# Get the list of available drive information
Write-CMLogEntry -Value 'Finding all available drives with file systems on the device' -Severity 1
$OldDrive = Get-PSDrive -p FileSystem
ForEach ($Drive in $OldDrive) {
    Write-CMLogEntry -Value "Found $Drive drive that has a file system" -Severity 1
}

# Retrieve only those drives that have a size bigger than 75GB
Write-CMLogEntry -Value 'Looking for Drives that have at least 20GB of space left.' -Severity 1
$Letters = $OldDrive | Where-Object {$_.Name -ne "X"-and (($_.Used/1gb) + ($_.Free/1gb)) -gt '20'}
ForEach ($Letter in $Letters) {
    Write-CMLogEntry -Value "Found Drive Letter $Letters with at least 20GB of space" -Severity 1
}

# From the list of those drives that are bigger than 75GB, find the drive that currently has a Windows folder in the root.
Write-CMLogEntry -Value 'Finding just the drive that has windows installed on it.' -Severity 1
$NewDrive = $Letters | Where-Object {(Test-Path "$($_.Root)\Windows") -eq $true}
Write-CMLogEntry -Value "Found Windows on $NewDrive drive" -Severity 1

# Assign the correct drive letter to a variable that can be used to put OS on
$DriveLetter = $NewDrive.Name + ":\"
Write-CMLogEntry -Value "Set the drive to backup to $DriveLetter" -Severity 1


#Write-CMLogEntry -Value 'Attempting to map a network drive to Q:\' -Severity 1
#& net use q: \\anc-sccm-src01.ua.ad.alaska.edu\vhd$ /user:ua\sccm-naa Pr0v1denc3 /p:no
#Write-CMLogEntry -Value 'Mapped Network Drive to Q:\' -Severity 1

# Path to store ISO
#Write-CMLogEntry -Value 'Set the Location to store the VHD file to q:\' -Severity 1
$StoreLocale = "$($DriveLetter)Archive"
Write-CMLogEntry -Value "Set where to store the ISO file to $StoreLocale" -Severity 1

# ISO File Name
#$FileName = $UAAComputerName
$FileName = $env:COMPUTERNAME
Write-CMLogEntry -Value "Set the filename for the ISO file to $FileName" -Severity 1

# Full Path for VHD Storage
$FullPath = "$StoreLocale\$FileName.iso"
Write-CMLogEntry -Value "Set the full filename including path to $FullPath" -Severity 1

Write-CMLogEntry -Value 'Beginning creation of ISO file for backup' -Severity 1
If (!$Debug) { (Get-ChildItem -Path $DriveLetter | Where { ($_.PsIsContainer -and $_.FullName -notmatch 'archive') -and ($_.PsIsContainer -and $_.FullName -notmatch "$($DriveLetter)Users\All Users\Application Data")  } ) | New-IsoFile -Path $FullPath -Media BDRE -Force | Out-Null }