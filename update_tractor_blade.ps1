$bladeFiles = Get-ChildItem $PSScriptRoot\blade -Filter *.py
$restart = $false
$tractorService = "Pixar Tractor Blade Service 2.4"
$destinationBladeFiles = "C:\Program Files\Pixar\Tractor-2.4\lib\python2.7\Lib\site-packages\tractor\apps\blade"

$tractorServiceExists = Get-Service -Name "$tractorService" -ErrorAction SilentlyContinue

if ($tractorServiceExists.Length -gt 0) {
  # For every file in ./blade check the content and update it
  for ($i=0; $i -lt $bladeFiles.Count; $i++) {
    $filename = $bladeFiles[$i]
    $source = $bladeFiles[$i].FullName
    $destination = "$destinationBladeFiles\$filename"
    
    if (Compare-Object -ReferenceObject $(Get-Content $source) -DifferenceObject $(Get-Content $destination)) {
      Write-Output "[UPDATE] $destination"
      Copy-Item $source -Destination $destination -force
      $restart = $true
    }
  }

  # Restart the Tractor service if needed
  if ($restart) {
    Write-Output "[INFO] Restarting blade"
    Restart-Service -Name $tractorService
  } else {
    Write-Output "[INFO] Blade up to date"
  }
} else {
  Write-Output "[ERROR] Service $tractorService doesn't exist"
  exit 1
}




