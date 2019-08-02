# Script to install the extra packages for R Statistics
# First set up an array and populate array with the names of the packages


# Stores the full path to the parent directory of this powershell script
# e.g. C:\Scripts\GoogleApps
$ScriptPathParent = split-path -parent $MyInvocation.MyCommand.Definition


$RPackages = "cluster_2.0.7-1.zip","ggplot2_3.1.0.zip","lattice_0.20-38.zip","rbacon_2.3.6.zip","tseries_0.10-46.zip"
$PathToBin = "c:\Program Files\R\R-3.5.1\bin"
Set-Location $ScriptPathParent
Foreach ($RPackage in $RPackages) {
    & $PathToBin\Rscript -e "install.packages('$($RPackage)', repos = NULL)" | Out-Null
    # Write-Host $RPackage " installed"
}
