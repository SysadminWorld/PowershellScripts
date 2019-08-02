[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
 
Function Set-OSDComputerName
 
{
 
$ErrorProvider.Clear()
 
$Error.Clear()
 
if ($objComputerName.Text.Length -eq 0)
 
{
 
$ErrorProvider.SetError($objComputerName, "Please enter a computer name.")
 
}
 
 
 
#Validation Rule for computer names.
 
elseif ($objComputerName.Text -match "^[-_]|[^a-zA-Z0-9-_]")
 
{
 
$ErrorProvider.SetError($objComputerName, "Computer name invalid, please correct the computer name.")
 
}
 
 
 
else
 
{
 
$OSDComputerName = $objComputerName.Text.ToUpper()
 
$TSEnv.Value("OSDComputerName") = $OSDComputerName
 
}
 
}
 
 
 
Function Set-OUPath
 
{
 
if (($objListBox.Items.Count -ne 0) -and `
 
    ($objListBox.SelectedItem.Length -eq 0))
 
{
 
$ErrorProvider.SetError($objListBox, "Please select an OU.")
 
}
 
else
 
{
 
$TSEnv.Value("OUPath") = $objListBox.SelectedItem
 
}
 
}
 
 
 
$ErrorProvider = New-Object System.Windows.Forms.ErrorProvider
 
$TSEnv = New-Object -COMObject Microsoft.SMS.TSEnvironment
 
 
 
$objForm = New-Object System.Windows.Forms.Form
 
$objForm.Text = "Computer Configuration"
 
$objForm.Size = New-Object System.Drawing.Size(300,300)
 
$objForm.StartPosition = "CenterScreen"
 
 
 
$objForm.KeyPreview = $True
 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Enter")
 
{$x=$objListBox.SelectedItem;$objForm.Close()}})
 
$objForm.Add_KeyDown({if ($_.KeyCode -eq "Escape")
 
{$objForm.Close()}})
 
 
 
$OKButton = New-Object System.Windows.Forms.Button
 
$OKButton.Location = New-Object System.Drawing.Size(10,230)
 
$OKButton.Size = New-Object System.Drawing.Size(75,23)
 
$OKButton.Text = "OK"
 
$OKButton.Add_Click({
 
Set-OSDComputerName
 
Set-OUPath
 
#If ($Error.Count -eq 0){$objForm.Close()}
 
if (($ErrorProvider.GetError($objListBox) -eq "") -and `
 
($ErrorProvider.GetError($objComputerName) -eq ""))
 
{
 
    Write-Host "Populated ComputerName: $objComputerName.Text"
 
    Write-Host "Populated OUPath: $objListBox.SelectedItem.Text"
 
    $objForm.Close()
 
}
 
})
 
$objForm.Controls.Add($OKButton)
 
 
 
$objLabel = New-Object System.Windows.Forms.Label
 
$objLabel.Location = New-Object System.Drawing.Size(10,20)
 
$objLabel.Size = New-Object System.Drawing.Size(280,20)
 
$objLabel.Text = "Please Select a Target OU:"
 
$objForm.Controls.Add($objLabel)
 
 
 
$objListBox = New-Object System.Windows.Forms.ListBox
 
$objListBox.Location = New-Object System.Drawing.Size(10,40)
 
$objListBox.Size = New-Object System.Drawing.Size(260,20)
 
$objListBox.Height = 135
 
$objListBox.ScrollAlwaysVisible = $true
 
 
 
$TSEnv.GetVariables() | ?{$_ -like "PATH*"} | %{
 
$objListBox.Items.Add($TSEnv.Value("$_"))
 
}
 
 
 
If ($objListBox.Items.Count -eq 0) {
 
    Write-Error "No OUPaths located"
 
}
 
else {$objListBox.SetSelected(0, $true)}
 
 
 
$objComputerNameLabel = New-Object System.Windows.Forms.Label
 
$objComputerNameLabel.Location = New-Object System.Drawing.Size(10,180)
 
$objComputerNameLabel.Size = New-Object System.Drawing.Size(280,20)
 
$objComputerNameLabel.Text = "Please Specify a ComputerName:"
 
$objForm.Controls.Add($objComputerNameLabel)
 
 
 
$objComputerName = New-Object System.Windows.Forms.TextBox
 
$objComputerName.Location = New-Object System.Drawing.Size(10,200)
 
$objComputerName.Size = New-Object System.Drawing.Size(260,20)
 
$objComputerName.MaxLength = 15
 
$objComputerName.Text = $TSEnv.Value("OSDComputerName")
 
$objForm.Controls.Add($objComputerName)
 
 
 
$objForm.Controls.Add($objListBox)
 
 
 
$objForm.Topmost = $True
 
 
 
$objForm.Add_Shown({$objForm.Activate()})
 
[void] $objForm.ShowDialog()