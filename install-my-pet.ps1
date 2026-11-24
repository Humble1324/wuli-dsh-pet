param([Parameter(Mandatory=$true)][string]$DshHome)
$ErrorActionPreference='Stop'
$sourcePet=Join-Path $PSScriptRoot 'pet'
$homePath=[IO.Path]::GetFullPath($DshHome)
if (-not (Test-Path -LiteralPath $homePath -PathType Container)) { throw "DSH_HOME directory does not exist: $homePath" }
$targetPet=Join-Path $homePath 'dsh-pet\pet'
$configPath=Join-Path $sourcePet 'my-pet-config.json'
$config=Get-Content -LiteralPath $configPath -Raw -Encoding UTF8 | ConvertFrom-Json
$animationDir=Join-Path $sourcePet 'my-pet-animation'
$required=@($config.animations.idle)+@($config.animations.turn)+@($config.animations.drag)+@($config.animations.clicks)
$required+=@($config.animations.moves.actions | ForEach-Object { $_.name })
$required+=@($config.animations.categories | ForEach-Object { $_.actions })
$required+=@($config.animations.events.balance)+@($config.animations.events.whisper)+@($config.animations.events.workStatus)
foreach($suite in $config.animations.sleep){$required+=@($suite.start)+@($suite.loop)+@($suite.end)}
foreach($name in ($required | Select-Object -Unique)){
 $file=Join-Path $animationDir ($name+'.webm')
 if(-not (Test-Path -LiteralPath $file -PathType Leaf)){throw "Missing animation: $name"}
 if((Get-Item -LiteralPath $file).Length -eq 0){throw "Empty animation: $name"}
}
Write-Host "Install my-pet into: $targetPet"
$answer=Read-Host 'Confirm this is the DSH_HOME used by your running instance. Type YES to install'
if($answer -cne 'YES'){Write-Host 'Cancelled';return}
New-Item -ItemType Directory -Path $targetPet -Force | Out-Null
$names=@('my-pet-config.json','my-pet-avatar.png','my-pet-animation')
$backup=Join-Path $homePath ('dsh-pet\backups\my-pet-'+[DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff'))
foreach($name in $names){
 $existing=Join-Path $targetPet $name
 if(Test-Path -LiteralPath $existing){
  New-Item -ItemType Directory -Path $backup -Force | Out-Null
  Copy-Item -LiteralPath $existing -Destination (Join-Path $backup $name) -Recurse
 }
}
foreach($name in $names){Copy-Item -LiteralPath (Join-Path $sourcePet $name) -Destination $targetPet -Recurse -Force}
Write-Host "Installed. Refresh/restart DSH and enable my-pet in pet settings."
if(Test-Path -LiteralPath $backup){Write-Host "Previous files backed up to: $backup"}
