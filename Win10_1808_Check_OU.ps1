#Windows build below, 1809 = 17763
$Buildnum = "17763"
$WinName = "Windows 10"

#Get machine OU 
$OU = (Get-Adcomputer -identity $env:computername).DistinguishedName -replace "CN=$($env:computername),",""

#Get all machines in previus machine OU
$Machines = (Get-AdComputer -Filter * -SearchBase $OU).Name

#Check if c$ is accessible - Creating text file with date&time and IP information into machine`s c$
foreach($Machine in $Machines){

    if(!(Test-Path "\\$($Machine)\c$")){
    Continue
    }

    if((Get-WmiObject -ComputerName $Machine -Class Win32_OperatingSystem).Caption -like "*$($WinName)*" -and (get-wmiobject -ComputerName $Machine -Class win32_OperatingSystem).BuildNumber -eq $Buildnum){

    "
Date & Time = $(Get-Date -Format "dd/MM/yy HH:mm")
Machine_IP(DNS) = $([System.Net.Dns]::GetHostByName("$($Machine)").AddressList.IpAddressToString)       
    
    
    
    " | Out-File "\\$($Machine)\c$\$($Machine).txt" -Force

    }
}