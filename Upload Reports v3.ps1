<#
.SYNOPSIS
    Bulk import SSRS Reports from a folder and update the reports data source.
.DESCRIPTION
    This script takes all the RDL files in a folder and imports them into a SSRS and updates the reports data source to the Configmgr shared data source.
.NOTES
    File Name  : Upload Reports.ps1
    Version    : 1.03 ,05.jan-2015
    Author     : Thomas Larsen - thomas.larsen@tromsfylke.no
    Requires   : Version 3
.LINK
    Blog
      http://larsenconfigmgr.blogspot.com

.PARAMETER webServiceUrl
Base URL to the report server ,usualy the Configmgr Site server

.PARAMETER reportFolder
 Report Server folder where the reports are imported to, the script creates the folder if it's not there.
 
.PARAMETER SourceDirectory
The local folder where the .rdl files are located.

.Example
& '.\Upload Reports v3.ps1' -webServiceUrl "http://Reportserver.domain.local" -reportFolder "Larsen Reports -SourceDirectory "c:\ReportsToUpload"

#>

Param(
   [string]$webServiceUrl,
   	  
   [string]$reportFolder = "Larsen Reports",

   [string]$SourceDirectory = $PSScriptRoot,

   [bool]$overwrite = $false
   )

Write-Host "Thomas Larsen - December 2015 - http://larsenconfigmgr.blogspot.com" -ForegroundColor Cyan
Write-Host "This Script is provided AS-IS, no warrenty is provided" 
Write-host ""

#Connect to SSRS
Write-Host "Reportserver: $webServiceUrl" -ForegroundColor DarkMagenta
Write-Host "Estabishing Proxy connection, connecting to : $webServiceUrl/ReportServer/ReportService2010.asmx?WSDL"
Write-Host ""

$ssrsProxy = New-WebServiceProxy -Uri $webServiceUrl'/ReportServer/ReportService2010.asmx?WSDL' -UseDefaultCredential

#######
#Get Configmgr shared datasource
$Items = $ssrsProxy.listchildren("/", $true) | where {$_.TypeName -eq "Datasource" }
foreach ($item in $items)
    {
    #Check to see if Datasource name patches Guid Pattern
    if ($item.name -match '{([a-zA-Z0-9]{8})-([a-zA-Z0-9]{4})-([a-zA-Z0-9]{4})-([a-zA-Z0-9]{4})-([a-zA-Z0-9]{12})}' -and $item.path -like '/ConfigMgr*')
        {
        Write-Host "Datasource:" $item.Name -ForegroundColor Magenta  
        Write-host "Type:" $item.TypeName 
        Write-Host "Path:" $item.Path

        #Save parameters for later use.
        $DatasourceName = $item.Name
        $DatasourcePath = $item.Path
        }
    }

function SSRSFolder ([string]$reportFolder,[string]$reportPath)
{
##########################################    
#Create Folder     
        try
        {
            $ssrsProxy.CreateFolder($reportFolder, $reportPath, $null) | out-null
            if($reportPath -eq '/')
            {
            Write-Host "Folder `"$reportpath$reportFolder`" Created"
            }
            else
            {
            Write-Host "Folder `"$reportpath/$reportFolder`" Created"
            }
        }
        catch [System.Web.Services.Protocols.SoapException]
        {
            if ($_.Exception.Detail.InnerText -match "rsItemAlreadyExists400")
            {
                Write-Host "Folder: $reportFolder already exists."
            }
            else
            {
                $msg = "Error creating folder: $reportFolder. Msg: '{0}'" -f $_.Exception.Detail.InnerText
                Write-Error $msg
            }
        }
}

Function SSRSItem ([string]$ItemType,$item,[string]$folder)
 {
 Write-host ""
 #ReportName
 if ($ItemType -ne "Resource")
 {
 $ItemName = [System.IO.Path]::GetFileNameWithoutExtension($item);
 }
 else
 {
 $ItemName = $item.Name
 }
 write-host $ItemName -ForegroundColor Green 

 #Upload File
     try
    {
        #Get Report content in bytes
        Write-Host "Getting file content of : $item"
        $byteArray = Get-Content $item.FullName -encoding byte
        $msg = "Size: {0} KB" -f "{0:N0}" -f ($byteArray.Length/1KB) 
        Write-Host $msg 
        
        Write-Host "Uploading to: $folder"
 
        #Sets property for images(only png)
        $type = $ssrsProxy.GetType().Namespace
        $datatype = ($type + '.Property')              
        $property =New-Object ($datatype);
        if ($ItemType -eq "Resource" -and $item -like "*.png")
        {
        $property.Name = "MimeType"
        $property.Value = “image/png”
        }
        else
        {
        $property = $null
        }

        #Call Proxy to upload report  
        $warnings =@();    
        $ssrsProxy.CreateCatalogItem($ItemType,$itemName,$folder,$overwrite,$byteArray,$property,[ref]$warnings) | out-null
        if($warnings.Length -le 1) { Write-Host "Upload Success." -ForegroundColor Green }
        else 
        {        
            foreach ($message in $warnings)
                {
                if ($message.Code -ne "rsDataSourceReferenceNotPublished")
                    {
                    write-host "$($message.Severity) $($message.Code) $($message.Message)" -ForegroundColor Yellow
                    }
                }
        }
    }
    catch [System.IO.IOException]
    {
        $msg = "Error while reading rdl file : '{0}', Message: '{1}'" -f $rdlFile, $_.Exception.Message
        Write-Error msg
    }
    catch [System.Web.Services.Protocols.SoapException]
	{
    $caught = $false
            if ($_.Exception.Detail.InnerText -match 'rsItemAlreadyExists400')
            {
                $caught = $true
                Write-Host "Report: $itemName already exists." -ForegroundColor Red
            }
            if ($_.Exception.Detail.InnerText -match 'CoretechSSRS')
            {
                $caught = $true
                Write-Host "Cant't find Coretech Reporting Extention File." -ForegroundColor Red
            }
            elseif ($caught -eq $false)
            {
                $msg = "Error uploading report: $reportName. Msg: '{0}'" -f $_.Exception.Detail.InnerText
                Write-Error $msg
            }
		
	}
}

Function SSRSDatasource ([string]$ReportPath,$DataSourceName,$DataSourcePath)
{
$report = $ssrsProxy.GetItemDataSources($ReportPath)
ForEach ($Source in $report)
    {
    $proxyNamespace = $Source.GetType().Namespace
        $constDatasource = New-Object ("$proxyNamespace.DataSource")
        $constDatasource.Name = $DataSourceName
        $constDatasource.Item = New-Object ("$proxyNamespace.DataSourceReference")
        $constDatasource.Item.Reference = $DataSourcePath

   $Source.item = $constDatasource.Item
    $ssrsProxy.SetItemDataSources($ReportPath, $Source)
    Write-Host "Changing datasource `"$($Source.Name)`" to $($Source.Item.Reference)"
    }
}

#TEst


##Create Folder Structure
#Create Base Folder

Write-Host "Creating Folders Structure:" -ForegroundColor DarkMagenta
SSRSFolder $reportFolder "/"

ForEach($Folder in Get-ChildItem $SourceDirectory -Directory)
    {
    #Add each folder in the sourcefolder to the reporting service 
    SSRSFolder $Folder.Name /$reportFolder
    }

     
#Upload Reports in root folder
ForEach ($rdlfile in Get-ChildItem $SourceDirectory -Filter *.rdl )
{
SSRSItem Report $rdlfile /$reportFolder

#Change Report Datasource
$ReportPath = "/" + $reportFolder + "/" +  $rdlfile.BaseName 
SSRSDatasource $ReportPath $DataSourceName $DataSourcePath
}

##For Each folder
 
ForEach($Folder in Get-ChildItem $SourceDirectory -Directory)
    {
    #Add each folder in the sourcefolder to the reporting service 
    #SSRSFolder $Folder.Name /$Basefolder 
    
    #Add reports in the folder
    ForEach ($rdlfile in Get-ChildItem $Folder -Filter *.rdl )
        {
        SSRSItem Report $rdlfile /$reportFolder/$($folder.Name) 

        #Change Report Datasource
        $ReportPath = "/" + $reportFolder + "/" + $folder.Name + "/" + $rdlfile.BaseName 
        SSRSDatasource $ReportPath $DataSourceName $DataSourcePath
        }
    }
