# Set auto restart for service
Set-Itemproperty -path 'HKLM:\SYSTEM\CurrentControlSet\Services\Pixar Tractor Blade Service 2.4' -Name 'Start' -value '2'

# Run the service
Set-Service -Name "Pixar Tractor Blade Service 2.4" -Status Running -PassThru

# Open port 9005 on TCP
New-NetFirewallRule -DisplayName 'TractorBlade' -Profile Any -Direction Inbound -Action Allow -Protocol TCP -LocalPort @('9005')
