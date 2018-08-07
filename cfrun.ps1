<#
.SYNOPSIS
	CloudFlare Management Script for MaestroPanel Triggers

.DESCRIPTION
	CloudFlare Management Script for MaestroPanel Triggers

.PARAMETER action
	ZONE_CREATE, ZONE_DELETE, RECORD_ADD, RECORD_UPDATE, RECORD_DELETE

.PARAMETER domain
	FQDN standart string input

.PARAMETER record_type
	Supported DNS types: A, AAAA, CNAME, TXT, SRV, MX, NS, SPF 
	
.EXAMPLE
	Create Domain Zone
	.\cfrun.ps1 -action ZONE_CREATE -domain maestropanel.com
	
	New DNS Record
	.\cfrun.ps1 -action RECORD_ADD -domain maestropanel.com -record_type A -record_name www -record_value 4.2.2.1
	
	New SRV Record
	.\cfrun.ps1 -action RECORD_ADD -domain maestropanel.com -record_type SRV -record_service "_autodiscover" -record_proto "_tcp" -record_target "mx.maestropanel.com" -record_priority 5 -record_weight 10 -record_port 443

	Delete SRV Record
	.\cfrun.ps1 -action RECORD_DELETE -domain maestropanel.com -record_type SRV -record_name "_autodiscover._tcp.maestropanel.com"
		
	Update DNS Record
	.\cfrun.ps1 -action RECORD_UPDATE -domain maestropanel.com -record_type CNAME -record_name "smtp" -record_value "mx.google.com"
.LINK
	https://github.com/maestropanel/cfrun

.Notes
	Author : Oguzhan YILMAZ	
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
	[string] $RECORD_SERVICE,
	[string] $RECORD_PROTO,
	[string] $RECORD_TARGET,
	[int32] $RECORD_PRIORITY=10,
	[int32] $RECORD_WEIGHT=5,
	[int32] $RECORD_PORT=443
)

$AUTH_EMAIL = "PLEASE ENTER YOUR CLOUDFLARE EMAIL"
$AUTH_KEY = "PLEASE ENTER YOUR API KEY"
$AUTH_HEADER = @{"X-Auth-Email" = $AUTH_EMAIL; "X-Auth-Key" = $AUTH_KEY}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function WriteLog($message){
	if($message -ne ""){
		Write-EventLog -LogName "Windows PowerShell"  -Source "PowerShell" -EntryType Information -Message $message -EventId 1
	}
}

function GetZoneId {
	try{
		$r = Invoke-RestMethod -Method GET -Uri "https://api.cloudflare.com/client/v4/zones?match=all&name=$DOMAIN" -Headers $AUTH_HEADER -ContentType 'application/json'	
		return $r.result[0].id	
	}
	catch
	{
		$responseBody =  $_.Exception.Message
		
		WriteLog $responseBody
		Write-Host $responseBody

		Exit
	}
}

function GetRecordIdByValue {
	$ZoneId = GetZoneId

	try{
	
		$r = Invoke-RestMethod -Method GET -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records?type=$RECORD_TYPE&name=$RECORD_NAME.$DOMAIN&content=$RECORD_VALUE&match=all" -Headers $AUTH_HEADER -ContentType 'application/json'	
		return $r.result[0].id		
	}
	catch
	{
		$responseBody =  $_.Exception.Message
		
		WriteLog $responseBody
		Write-Host $responseBody
		
		Exit
	}
}

function GetRecordIdByName {
	$ZoneId = GetZoneId
	
	try{
		$r = Invoke-RestMethod -Method GET -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records?type=$RECORD_TYPE&name=$RECORD_NAME.$DOMAIN&match=all" -Headers $AUTH_HEADER -ContentType 'application/json'
		return $r.result[0].id
	}
	catch
	{
		$responseBody =  $_.Exception.Message
		
		WriteLog $responseBody
		Write-Host $responseBody
		
		Exit
	}
}

WriteLog "Parameters Action: $ACTION, Domain: $DOMAIN, Type: $RECORD_TYPE, Name: $RECORD_NAME, Value: $RECORD_VALUE"

if($ACTION -eq "ZONE_CREATE"){
	
	$responseBody = ""
	$jsonBody = @{name=$DOMAIN; jump_start=$true} | ConvertTo-Json
	
	try{	

		$r = Invoke-RestMethod -Method POST -Uri "https://api.cloudflare.com/client/v4/zones" -Headers $AUTH_HEADER -Body $jsonBody -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$responseBody =  $_.Exception.Message
	}

	WriteLog $responseBody
	Write-Host $responseBody
}

if($ACTION -eq "ZONE_DELETE"){

	$responseBody = ""
	$ZoneId = GetZoneId	
	
	try{	
		$r = Invoke-RestMethod -Method DELETE -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId" -Headers $AUTH_HEADER -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$responseBody =  $_.Exception.Message
	}

	WriteLog $responseBody
	Write-Host $responseBody
}

if($ACTION -eq "RECORD_ADD"){

	$proxied=$false
	
	if($RECORD_TYPE -eq "A" -Or $RECORD_TYPE -eq "CNAME"){$proxied=$true}
		
	$responseBody = ""	
	$jsonBody = @{type=$RECORD_TYPE; 
					name=$RECORD_NAME; 
					content=$RECORD_VALUE; 
					ttl=120; 
					proxiable=$proxied; 
					proxied=$proxied; 
					priority=$RECORD_PRIORITY} | ConvertTo-Json
					
	$ZoneId = GetZoneId
	
	if($RECORD_TYPE -eq "SRV"){
		$jsonBody = @{type=$RECORD_TYPE;
					ttl=120; 
					proxiable=$proxied; 
					proxied=$proxied; 
						data=@{service=$RECORD_SERVICE; 
								proto=$RECORD_PROTO; 
								name=$DOMAIN; 
								priority=$RECORD_PRIORITY; 
								weight=$RECORD_WEIGHT; 
								port=$RECORD_PORT; 
								target=$RECORD_TARGET} 
								} | ConvertTo-Json
	}
	
	try{
		$r = Invoke-RestMethod -Method POST -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records" -Headers $AUTH_HEADER -Body $jsonBody -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$responseBody =  $_.Exception.Message
	}

	WriteLog $responseBody
	Write-Host $responseBody
}

if($ACTION -eq "RECORD_UPDATE"){

	$responseBody = ""						
	$RecordId = GetRecordIdByName
	$ZoneId = GetZoneId	

	if($RECORD_TYPE -eq "A" -Or $RECORD_TYPE -eq "CNAME"){$proxied=$true}
	
	$jsonBody = @{id=$RecordId; 
					type=$RECORD_TYPE; 
					name=$RECORD_NAME; 
					content=$RECORD_VALUE;
					proxiable=$proxied; 
					proxied=$proxied;					
					priority=$RECORD_PRIORITY} | ConvertTo-Json
					
	try{
		$r = Invoke-RestMethod -Method PUT -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$RecordId" -Headers $AUTH_HEADER -Body $jsonBody -ContentType 'application/json'
		$responseBody = $r | Out-String
	}
	catch
	{
		$responseBody =  $_.Exception.Message
	}
	
	WriteLog $responseBody
	Write-Host $responseBody
}

if($ACTION -eq "RECORD_DELETE"){

	$responseBody = ""						
	$RecordId = ""
	$ZoneId = GetZoneId	

	if($RECORD_TYPE -eq "SRV"){
		$RecordId = GetRecordIdByName
	}else{
		$RecordId = GetRecordIdByValue
	}

	try{
	
		$r = Invoke-RestMethod -Method DELETE -Uri "https://api.cloudflare.com/client/v4/zones/$ZoneId/dns_records/$RecordId" -Headers $AUTH_HEADER -ContentType 'application/json'
		$responseBody = $r | Out-String	

	}
	catch
	{
		$responseBody =  $_.Exception.Message
	}

	WriteLog $responseBody
	Write-Host $responseBody
}
