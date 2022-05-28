Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Pixar Tractor Blade Service 2.4' -Name 'Start' -value '2'
Set-Service -Name "Pixar Tractor Blade Service 2.4" -Status Running -PassThru
New-NetFirewallRule -DisplayName 'TractorBlade' -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('9005')
