#
# Step 1: Install WMF5.0 Preview and reboot
#
$Workingdir = "c:\dsc"

if (!(Test-Path "c:\dsc")){mkdir $Workingdir}
Set-Location $Workingdir

Invoke-WebRequest -Uri http://download.microsoft.com/download/E/D/B/EDB86AD9-4D26-4C33-A8B2-82BE161682E2/WindowsBlue-KB2969050-x64.msu -OutFile WindowsBlue-KB2969050-x64.msu
& wusa .\WindowsBlue-KB2969050-x64.msu /quiet

#
# Step 2: Download & install DSC modules
#

Write-Host "==================== DSC Demo Preparation Start ====================" -ForegroundColor Yellow

$ModulePath = "C:\Program Files\WindowsPowerShell\Modules\"
$Workingdir = "c:\dsc"

if (!(Test-Path "c:\dsc")){mkdir $Workingdir}
Set-Location $Workingdir

Invoke-WebRequest -Uri https://gallery.technet.microsoft.com/DSC-Resource-Kit-All-c449312d/file/127764/1/DSC%20Resource%20Kit%20Wave%208%2010282014.zip -OutFile .\DSCResourceKitWave8.zip
Invoke-WebRequest -uri https://github.com/leshkinski/DSC/archive/master.zip -OutFile .\DSC-master.zip
Invoke-WebRequest -Uri https://github.com/PowerShellOrg/cChoco/archive/master.zip -OutFile .\cChoco.zip

Expand-Archive .\DSCResourceKitWave8.zip -DestinationPath $ModulePath -Force
Expand-Archive .\DSC-master.zip -DestinationPath .\ -Force
Expand-Archive .\cChoco.zip -DestinationPath .\ -Force
Copy-Item -Path ".\DSC-master\Resources\cGit" -Destination $ModulePath -Recurse  -Force
Copy-Item -Path ".\DSC-master\Resources\cWebAdministration" -Destination $ModulePath -Recurse  -Force
Move-Item -Path ".\cChoco-master" -Destination "$ModulePath\cChoco" -Force


(Get-ChildItem "C:\Program Files\WindowsPowerShell\Modules\" -Recurse -file).FullName | ForEach-Object {Unblock-File $_}
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force

Update-Help

Write-Host "`n `n `n `n ==================== DSC Demo Preparation Complete ====================" -ForegroundColor Green
