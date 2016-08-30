<#
.SYNOPSIS
	CloudFlare Management Script for MaestroPanel Triggers

.DESCRIPTION
	CloudFlare Management Script for MaestroPanel Triggers

.PARAMETER action
	CREATE, DELETE, RECORD_ADD, RECORD_UPDATE, RECORD_DELETE

.PARAMETER domain
	FQDN standart string input

.EXAMPLE
	./cfrun.ps1 -action CREATE -domain maestropanel.com
	./cfrun.ps1 -action RECORD_ADD -domain maestropanel.com -record_type A -record_name www -record_value 4.2.2.1

.LINK
	https://github.com/maestropanel/cfrun

.Notes
	Author : Oğuzhan YILMAZ	
	Filename: cfrun.ps1
#>

[Cmdletbinding()]
Param(
	[Parameter(Mandatory=$true)]
	[string] $ACTION,
	
	[Parameter(Mandatory=$true)]
	[string] $DOMAIN,
	
	[string] $RECORD_TYPE,
	[string] $RECORD_NAME,
	[string] $RECORD_VALUE,
	[string] $RECORD_PRIORITY	
)

$AUTH_EMAIL = "ENTER YOUR EMAIL"
$AUTH_KEY = "ENTER YOUR KEY"
$AUTH_HEADER = @{"X-Auth-Email" = $AUTH_EMAIL; "X-Auth-Key" = $AUTH_KEY}

function GetZoneId {
	$r = Invoke-RestMethod -Method GET -Uri "https://api.cloudflare.com/client/v4/zones?match=all&name=$DOMAIN" -Headers $AUTH_HEADER -ContentType 'application/json'	
	return $r.result[0].id	
}

if($ACTION -eq "CREATE"){
	$responseBody = ""
	$jsonBody = @{name=$DOMAIN; jump_start=$true} | ConvertTo-Json
	
	try{	
		$r = Invoke-RestMethod -Method POST -Uri "https://api.cloudflare.com/client/v4/zones" -Headers $AUTH_HEADER -Body $jsonBody -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$result = $_.Exception.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($result)
		$responseBody = $reader.ReadToEnd()
	}

	Write-Host $responseBody
}

if($ACTION -eq "DELETE"){

	$responseBody = ""
	$ZoneId = GetZoneId	
	
	try{	
		$r = Invoke-RestMethod -Method DELETE -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId" -Headers $AUTH_HEADER -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$result = $_.Exception.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($result)
		$responseBody = $reader.ReadToEnd()
	}

	Write-Host $responseBody
}

if($ACTION -eq "RECORD_ADD"){

	$responseBody = ""
	$jsonBody = @{type=$RECORD_TYPE; name=$RECORD_NAME;content=$RECORD_VALUE;ttl=120;proxiable=$true;proxied=$true} | ConvertTo-Json
	$ZoneId = GetZoneId	
		
	try{	
		$r = Invoke-RestMethod -Method POST -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records" -Headers $AUTH_HEADER -Body $jsonBody -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$result = $_.Exception.Response.GetResponseStream()
		$reader = New-Object System.IO.StreamReader($result)
		$responseBody = $reader.ReadToEnd()
	}

	Write-Host $responseBody
}


