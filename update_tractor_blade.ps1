$files = Get-ChildItem "\\prod.silex.artfx.fr\rez\windows\blade_tractor\blade" -Filter *.py
$restart = $false

for ($i=0; $i -lt $files.Count; $i++) {
	$filename = $files[$i]
	$source = $files[$i].FullName
	$destination = "C:\Program Files\Pixar\Tractor-2.4\lib\python2.7\Lib\site-packages\tractor\apps\blade\$filename"
	
	if (Compare-Object -ReferenceObject $(Get-Content $source) -DifferenceObject $(Get-Content $destination)) {
		Write-Output "$destination modified"
		Copy-Item $source -Destination $destination -force
		$restart = $true
	}
}

if ($restart) {
  Write-Output "Restarting blade"
  Restart-Service -Name "Pixar Tractor Blade Service 2.4"
  New-Item -Path \\prod.silex.artfx.fr\rez\windows\blade_tractor\status\updated -Force -Name $env:computername
} else {
  Write-Output "Blade up to date"
  New-Item -Path \\prod.silex.artfx.fr\rez\windows\blade_tractor\status\uptodate -Force -Name $env:computername 
}



