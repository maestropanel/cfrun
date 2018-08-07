# cfrun
MaestroPanel Tetikleyicileri için CloudFlare Entegrasyonu / CloudFlare Management Script for MaestroPanel Triggers.

Bu scripti MaestroPanel'e entegre etmek  için lütfen aşağıdaki dokümanı inceleyiniz.

 - https://wiki.maestropanel.com/maestropanel-cloudflare-script-powershell/


### Download
----------

 - https://github.com/maestropanel/cfrun/blob/master/cfrun.ps1

### Kurulum
----------
*cfrun.ps1* dosyasını

	%MaestroPanelPath%\bin

klasörü altına kopyalayın. Bu kadar!

### Ayarlar
----------
*cfrun.ps1* dosyasını açarak CloudFlare bilgilerinizi tanıtmanız gerekiyor.

	$AUTH_EMAIL = "ENTER YOUR EMAIL"
	$AUTH_KEY = "ENTER YOR KEY"

### Parametreler

cfrun.ps1 PowerShell scriptinin alabileceği parametreler ve açıklamaları aşağıdaki gibidir.

| İsim  | Açıklama  |
|---|---|
| action  | Yapılacak işlem ZONE_CREATE, ZONE_DELETE, RECORD_ADD, RECORD_UPDATE, RECORD_DELETE   |
| domain  | Eklenecek veya işlem yapılacak domain ismi. |
| record_type  |  A, AAAA, CNAME, TXT, SRV, MX, NS, SPF  |
| record_name  |  DNS Kaydının ismi. |
| record_value  |  DNS kaydının değeri. |
| record_proto  |  SRV kaydı için protokol değeri. _tpc gibi. |
| record_target  | SRV kaydı için target domain değeri. FQDN değeri.  |
| record_priority  | MX veya SRV kaydı için kullanılan priority. Integer.  |
| record_weight  |  SRV kaydı için weight değeri. Integer. |
| record_port  |  SRV kaydı için port değeri. Integer. |

Özellikleri;

 - Yeni bir domain ekleyebilir.
 - Mevcut domain'i silebilir.
 - Yeni bir DNS kaydı ekleyebilir.
 - Mevcut DNS kaydını güncelleyebilir. 
 - Mevcut DNS kaydını silebilir.

### Örnekler
----------
Yeni Domain Eklemek

	.\cfrun.ps1 -action ZONE_CREATE -domain maestropanel.com

Yeni DNS Kaydı

	.\cfrun.ps1 -action RECORD_ADD -domain maestropanel.com -record_type A -record_name www -record_value 4.2.2.1

Yeni SRV Kaydı

	.\cfrun.ps1 -action RECORD_ADD -domain maestropanel.com -record_type SRV -record_service "_autodiscover" -record_proto "_tcp" -record_target "mx.maestropanel.com" -record_priority 5 -record_weight 10 -record_port 443

SRV Kaydını Silmek

	.\cfrun.ps1 -action RECORD_DELETE -domain maestropanel.com -record_type SRV -record_name "_autodiscover._tcp.maestropanel.com"
	
DNS Kaydını Güncellemek

	.\cfrun.ps1 -action RECORD_UPDATE -domain maestropanel.com -record_type CNAME -record_name "smtp" -record_value "mx.google.com"

### Yazar

Oğuzhan YILMAZ

oguzhan@maestropanel.com



