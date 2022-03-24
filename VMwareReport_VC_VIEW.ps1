##Params_Below
$DomainName = "mosh.corp"
$OU = 'OU=קבוצה נוספת,OU=עוד קבוצה,OU=טכנולוגיה,OU=מוש,OU=moshe,DC=mosh,DC=corp'
#End Hardcodded params


#Connect to View, Vsphere servers.
try {
	$HVServer = Connect-HVServer -Server HVSERVERHERE.mosh.corp -Domain $DomainName
	$VIServer = Connect-VIServer -Server VISERVERHERE.mosh.corp
}

catch {
	Write-Host -ForegroundColor Red "Error connecting to VMware Horizon"
	Write-Host "If you don't have VMware powershell tools installed, Please install it via:"
	Write-Host "PATH TO INSTALL HERE"
	break
}


#Get all users in OU to Array
[array]$OU_users = (Get-Aduser -Filter * -SearchBase $OU).SamAccountName

#Find all machines with OU users assigments and put them into array
$OU_UsersMachines = $null
foreach ($OU_User in $OU_users) {
	[array]$OU_UsersMachines += Get-HVMachineSummary | Where-Object { $_.NamesData.Username -contains "$($DomainName)\$($OU_user)" }

}
##Processing machine information to array - Export to CSV
$vms = $OU_UsersMachines
$results = @()
foreach ($vm in $vms) {
	Write-Host "Collecting info for $($vm.Base.Name)"
	$properties = @{
		MachineName = $vm.Base.Name
		DNSNAME = $vm.Base.DNSNAME
		VDIPool = $vm.NamesData.DesktopName
		Username = $vm.NamesData.Username
		Num_CPUs = Get-VM -Name $vm.Base.Name | Select-Object -ExpandProperty NumCPU
		RAM = Get-VM -Name $vm.Base.Name | Select-Object -ExpandProperty MemoryMB	}
	$results += New-Object psobject -Property $properties
}

$results | Export-Csv -NoTypeInformation -Path C:\temp\PersistentInfo.csv




#Second part of mission 1

$ViewPools = $null
#Get all pools with Linked Clone , Instant clone types and processing data. - Export to CSV
$ViewPools = Get-hvpool | Where-Object { $_.Source -eq "VIEW_COMPOSER" -or $_.Source -eq "INSTANT_CLONE_ENGINE" }
foreach ($ViewPool in $ViewPools) {
	$SourceType = $null
	switch ($ViewPool.Source) {
		'VIEW_COMPOSER' { $SourceType = "Linked_Clone" }
		'INSTANT_CLONE_ENGINE' { $SourceType = "Instant_Clone" }
		default { $SourceType = "Unknown" }
	}
	$row = New-Object System.Object
	$row | Add-Member -MemberType NoteProperty -Name "PoolName" -Value $ViewPool.Base.Name
	$row | Add-Member -MemberType NoteProperty -Name "PoolType" -Value $SourceType
	$row | Add-Member -MemberType NoteProperty -Name "Protocol" -Value (Get-hvpool $Viewpool.Base.Name).DesktopSettings.DisplayProtocolSettings.DefaultDisplayProtocol
	$row | Add-Member -MemberType NoteProperty -Name "Available_workstations" -Value ((Get-HVMachineSummary $($viewpool.Base.Name)).Base | Where-Object { $_.BasicState -eq "Available" }).Count
	$row | Add-Member -MemberType NoteProperty -Name "Connected_workstations" -Value ((Get-HVMachineSummary $($viewpool.Base.Name)).Base | Where-Object { $_.BasicState -eq "Connected" }).Count
	[array]$tocsv += $row
}

[array]$tocsv | Export-Csv -Path c:\temp\nonplist.csv -NoTypeInformation
