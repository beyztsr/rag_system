<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2">
	<ns prefix="gl-plt" uri="http://www.xbrl.org/int/gl/plt/2010-04-16"/>
	<ns prefix="gl-cor" uri="http://www.xbrl.org/int/gl/cor/2006-10-25"/>
	<ns prefix="gl-bus" uri="http://www.xbrl.org/int/gl/bus/2006-10-25"/>
	<ns prefix="gl-muc" uri="http://www.xbrl.org/int/gl/muc/2006-10-25"/>
	<ns prefix="xbrli" uri="http://www.xbrl.org/2003/instance"/>
	<ns prefix="ds" uri="http://www.w3.org/2000/09/xmldsig#"/>
	<ns prefix="xades" uri="http://uri.etsi.org/01903/v1.3.2#"/>
	<ns prefix="envanter" uri="http://www.edefter.gov.tr"/>
	<ns prefix="defterek" uri="http://www.edefter.gov.tr/ek"/>
	<title>Berat dokümanlarını kontrol etmek için gerekli olan schematron kuralları</title>
	<let name="vknTckn" value="/envanter:berat/xbrli:xbrl/xbrli:context/xbrli:entity/xbrli:identifier"/>
	<let name="beratTipi" value="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-cor:entriesType"/>
	<let name="periodCoveredStart" value="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-cor:periodCoveredStart"/>
	<let name="donemYil" value="substring($periodCoveredStart,1,4)"/>
	<let name="donemAy" value="substring($periodCoveredStart,6,2)"/>
	<let name="donem" value="number(concat($donemYil,$donemAy))"/>
	<let name="dosyaAdi" value="base-uri()"/>
	<pattern id="kok">
		<rule context="*">
			<assert test="not(@decimals) or  @decimals = 'INF'">Belge içerisindeki 'decimals' nitelikleri 'INF' değerini almalıdır.</assert>
		</rule>
		<rule context="/">
			<assert test="envanter:berat">Berat dokümanı envanter:berat ana elemanı ile başlamalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="entity">
		<rule context="/envanter:berat/xbrli:xbrl/xbrli:context/xbrli:entity">
			<assert test="not($beratTipi='assets') or xbrli:segment/gl-bus:numberOfEntries"> Envanter beratında xbrli:segment/gl-bus:numberOfEntries zorunlu bir elemandır.</assert>
			<assert test="xbrli:segment/gl-cor:uniqueID"> xbrli:segment/gl-cor:uniqueID zorunlu bir elemandır.</assert>
			<assert test="xbrli:segment/gl-bus:measurableQuantity"> xbrli:segment/gl-bus:measurableQuantity zorunlu bir elemandır.</assert>
			<assert test="not(xbrli:segment/gl-bus:measurableQuantity) or matches(normalize-space(xbrli:segment/gl-bus:measurableQuantity) , '^[0-9]+(\.[0-9]{1,2})?$')">xbrli:segment/gl-bus:measurableQuantity (<value-of select="xbrli:segment/gl-bus:measurableQuantity"/>) virgülden sonra 2 haneden fazla olamaz.</assert>
			<assert test="not(xbrli:segment/gl-cor:uniqueID) or matches(xbrli:segment/gl-cor:uniqueID,'^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$')">xbrli:segment/gl-cor:uniqueID elemanı UUID formatında olmalıdır.</assert>
			<assert test="contains($dosyaAdi,concat(xbrli:identifier,'-'))">Dosya adına yazılan vkn/tckn ile xbrli:identifier elemanına yazılan vkn/tckn aynı olmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="berat">
		<rule context="/envanter:berat">
			<assert test="ds:SignatureValue">ds:SignatureValue zorunlu bir elemandır.</assert>
			<assert test="count(extensions/extension/defterek:binaryObject) = 0 ">defterek:binaryObject elemanı sadece envanter defterinde bulunabilir.</assert>
		</rule>
	</pattern>
	
	<pattern id="signature">
		<rule context="/envanter:berat/ds:Signature">
			<let name="signatureMethodAlgorithm" value="ds:SignedInfo/ds:SignatureMethod/@Algorithm"/>
			<assert test="ds:SignatureValue/@Id">ds:SignatureValue elemanı Id niteliğine sahip olmalıdır.</assert>
			<assert test="ds:SignedInfo/ds:Reference/ds:Transforms">ds:SignedInfo/ds:Reference/ds:Transforms elemanı zorunlu bir elemandır.</assert>
			<assert test="ds:KeyInfo">ds:KeyInfo elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:KeyInfo) or ds:KeyInfo/ds:X509Data">ds:KeyInfo elemanı içerisindeki ds:X509Data elemanı zorunlu bir elemandır.</assert>
			<assert test="ds:Object">ds:Object elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:Object) or ds:Object/xades:QualifyingProperties/xades:SignedProperties/xades:SignedSignatureProperties/xades:SigningTime">xades:SigningTime elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:Object) or ds:Object/xades:QualifyingProperties/xades:SignedProperties/xades:SignedSignatureProperties/xades:SigningCertificate">xades:SigningCertificate elemanı zorunlu bir elemandır</assert>
			<assert test="count(ds:SignedInfo/ds:Reference[@URI = '']) = 1 ">ds:SignedInfo elamanı içerisinde URI niteliği boşluğa("") eşit olan sadece bir tane ds:Reference elemanının bulunmaldır.</assert>
			<assert test="not(ends-with($signatureMethodAlgorithm,'sha1'))">İmzalama işleminde kullanılacak özet(hash) algoritması sha1 olmamalıdır.</assert>
		</rule>
		<rule context="/envanter:berat/ds:Signature/ds:KeyInfo/ds:X509Data">
			<assert test="ds:X509Certificate">ds:X509Data elemanı içerisindeki ds:X509Certificate elemanı zorunlu bir elemandır.</assert>
		</rule>
		<rule context="/envanter:berat/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509SubjectName">
			<assert test="string-length(normalize-space(.)) != 0 "> ds:X509SubjectName elemanının değeri boşluk olmamalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="xbrl">
		<rule context="/envanter:berat/xbrli:xbrl">
			<assert test="count(xbrli:context) = 1 ">xbrli:context zorunlu bir elemandır.</assert>
			<assert test="count(xbrli:unit) >= 1 ">xbrli:unit zorunlu bir elemandır.</assert>
			<assert test="count(gl-cor:accountingEntries) = 1 ">gl-cor:accountingEntries zorunlu bir elemandır.</assert>
			<assert test="count(xbrli:unit/xbrli:measure) >= 1 ">xbrli:measure zorunlu bir elemandır.</assert>
		</rule>
		<rule context="/envanter:berat/xbrli:xbrl/xbrli:context/xbrli:entity/xbrli:identifier">
			<assert test="matches(normalize-space(.) , '^[0-9]{10,11}$')">xbrli:identifier elemanına 10 haneli vergi kimlik numarası ve ya 11 haneli TC kimlik numarası yazılmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="measure">
		<rule context="/envanter:berat/xbrli:xbrl/xbrli:unit/xbrli:measure">
			<let name="currency" value="substring(normalize-space(.),9)"/>
			<let name="currencyCodeList" value="',AED,AFN,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BIF,BMD,BND,BOB,BOV,BRL,BSD,BTN,BWP,BYN,BYR,BZD,CAD,CDF,CHE,CHF,CHW,CLF,CLP,CNY,COP,COU,CRC,CUC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EEK,EGP,ERN,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GWP,GYD,HKD,HNL,HRK,HTG,HUF,IDR,ILS,INR,IQD,IRR,ISK,JMD,JOD,JPY,KES,KGS,KHR,KMF,KPW,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LRD,LSL,LTL,LVL,LYD,MAD,MAD,MDL,MGA,MKD,MMK,MNT,MOP,MRO,MUR,MVR,MWK,MXN,MXV,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SDG,SEK,SGD,SHP,SLL,SOS,SSP,SRD,STD,SVC,SYP,SZL,THB,TJS,TMT,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,USN,USS,UYI,UYU,UZS,VEF,VND,VUV,WST,XAF,XAG,XAU,XBA,XBB,XBC,XBD,XCD,XDR,XFU,XOF,XPD,XPF,XPT,XSU,XTS,XUA,XXX,YER,ZAR,ZMK,ZMW,ZWL,'"/>
			<assert test="not (starts-with(normalize-space(.),'iso4217:')) or contains($currencyCodeList, concat(',',$currency,','))">Gecersiz currency degeri: '<sch:value-of select="$currency"/>'.</assert>
			<assert test="count(parent::node()[contains($currencyCodeList, @id)]) &lt;=1 ">id'si iso4217 multicurrency kodlarından birisi olan en fazla 1 xbrli:unit elemanı olabilir. </assert>
			<assert test="not(parent::node()[contains($currencyCodeList,@id)]) or  .= concat('iso4217:',parent::node()/@id) ">xbrli:measure değeri (<sch:value-of select="."/>) hatalıdır. xbrli:unit id'nin değeri <sch:value-of select="parent::node()/@id"/> olduğu için xbrli:measure değeri <sch:value-of select="concat('iso4217:',parent::node()/@id)"/> olmalıdır. </assert>
			<assert test="not(parent::node()[contains($currencyCodeList, @id)]) or  not(/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency) or not(.= concat('iso4217:',parent::node()/@id)) or /envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency=."> gl-muc:defaultCurrency değeri (<sch:value-of select="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency"/>) hatalıdır. gl-muc:defaultCurrency elemanı varsa değeri xbrli:measure(<sch:value-of select="."/>) ile aynı olmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="accountingentries">
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries">
			<assert test="gl-cor:documentInfo">gl-cor:documentInfo zorunlu bir elemandır.</assert>
			<assert test="gl-cor:entityInformation">gl-cor:entityInformation zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:entryHeader)">gl-cor:entryHeader elemanı olmamalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="documentinfo">
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo">
			<assert test="gl-cor:entriesType">gl-cor:entriesType zorunlu bir elemandır.</assert>
			<assert test="( normalize-space(gl-cor:entriesType) = 'assets')">gl-cor:entriesType elemanı envanter defteri beratı için 'assets' değerini almalıdır.</assert>
			<assert test="gl-cor:uniqueID">gl-cor:uniqueID zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:uniqueID) or not ($beratTipi='assets') or( starts-with(normalize-space(gl-cor:uniqueID),'ENV'))">gl-cor:uniqueID elemanı envanter defteri için 'ENV' değeri ile başlamalıdır.</assert>
			<assert test="not(gl-cor:uniqueID) or string-length(normalize-space(gl-cor:uniqueID)) = 15">gl-cor:uniqueID elemanı 15 karakterden oluşmalıdır.</assert>
			<assert test="gl-cor:creationDate">gl-cor:creationDate zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredStart">gl-cor:periodCoveredStart zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredEnd">gl-cor:periodCoveredEnd zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredEnd = gl-cor:periodCoveredStart">gl-cor:periodCoveredEnd elemanı gl-cor:periodCoveredStart elemanına eşit olmalıdır. </assert>
			<assert test="gl-cor:creationDate >= gl-cor:periodCoveredEnd">gl-cor:creationDate elemanı gl-cor:periodCoveredEnd elemanından büyük ve ya eşit olmalıdır. </assert>
			<assert test="string-length(normalize-space(gl-bus:sourceApplication)) > 0">gl-bus:sourceApplication zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
			<assert test="contains($dosyaAdi,concat('-',$donem,'-'))">Dosya adındaki dönem ile periodCoveredStart'daki dönem bilgisi aynı olmalıdır.</assert>
			<let name="donemYilPrdEnd" value="substring(gl-cor:periodCoveredEnd,1,4)"/>
			<let name="donemAyPrdEnd" value="substring(gl-cor:periodCoveredEnd,6,2)"/>
			<assert test="$donemYil=$donemYilPrdEnd">gl-cor:periodCoveredStart elemanındaki yıl bilgisi ile periodCoveredEnd elemanındaki yıl bilgisi aynı olmalıdır.</assert>
			<assert test="$donemAy=$donemAyPrdEnd">gl-cor:periodCoveredStart elemanındaki ay bilgisi ile periodCoveredEnd elemanındaki ay bilgisi aynı olmalıdır.</assert>
			<assert test="contains(gl-cor:uniqueID,concat($donemYil,$donemAy))">gl-cor:uniqueID elemanındaki dönem bilgisi ile gl-cor:periodCoveredStart elemanındaki dönem bilgisi aynı olmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="entityinformation">
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation">
			<assert test="gl-bus:entityPhoneNumber">gl-bus:entityPhoneNumber zorunlu bir elemandır.</assert>
			<assert test="gl-bus:entityEmailAddressStructure">gl-bus:entityEmailAddressStructure zorunlu bir elemandır.</assert>
			<assert test="count(gl-bus:organizationIdentifiers) >= 1">gl-bus:organizationIdentifiers zorunlu bir elemandır.</assert>
			<assert test="not(string-length($vknTckn) = 10) or count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Kurum Unvanı']) = 1">gl-bus:organizationDescription değeri 'Kurum Unvanı' olan bir tane gl-bus:organizationIdentifiers elemanı bulunmalıdır.</assert>
			<assert test="not(string-length($vknTckn) = 11) or count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Adı Soyadı']) = 1">gl-bus:organizationDescription değeri 'Adı Soyadı' olan bir tane gl-bus:organizationIdentifiers elemanı bulunmalıdır.</assert>
			<let name="countKurumUnvani" value="count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Kurum Unvanı'])"/>
			<let name="countAdiSoyadi" value="count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Adı Soyadı'])"/>
			<assert test="($countKurumUnvani=1 and not($countAdiSoyadi=1)) or ($countAdiSoyadi=1 and not($countKurumUnvani=1))">gl-bus:organizationDescription değeri 'Kurum Unvanı' veya 'Adı Soyadı' olan yalnızca bir tane gl-bus:organizationIdentifiers elemanı bulunmalıdır.</assert>
			<assert test="not(count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Kurum Unvanı']) = 1) or 
				string-length(normalize-space(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Kurum Unvanı']/gl-bus:organizationIdentifier)) >=2">gl-bus:organizationDescription değeri 'Kurum Unvanı' olan gl-bus:organizationIdentifiers elemanının  gl-bus:organizationIdentifier eleman değeri en az iki karakter olmalıdır.</assert>
			<assert test="not(count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Adı Soyadı']) = 1) or 
				string-length(normalize-space(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Adı Soyadı']/gl-bus:organizationIdentifier)) >=2">gl-bus:organizationDescription değeri 'Adı Soyadı' olan gl-bus:organizationIdentifiers elemanının  gl-bus:organizationIdentifier eleman değeri en az iki karakter olmalıdır.</assert>
			<let name="countSubeNo" value="count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Şube No'])"/>
			<let name="countSubeAdi" value="count(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Şube Adı'])"/>
			<assert test="(not($countSubeNo = 1) or $countSubeAdi = 1) and (not($countSubeAdi = 1) or $countSubeNo = 1)">Şube no ve şube adı birlikte bulunmalıdır.</assert>
			<assert test="($countSubeNo &lt; 2) and ($countSubeAdi &lt; 2)">Şube no veya şube adı birden fazla olamaz.</assert>
			<assert test="not($countSubeNo = 1) or matches(normalize-space(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Şube No']/gl-bus:organizationIdentifier) , '^[0-9]{4}$')">Şube no 4 haneli sayısal bir değer olmalıdır.</assert>
			<assert test="not($countSubeAdi = 1) or string-length(normalize-space(gl-bus:organizationIdentifiers[gl-bus:organizationDescription = 'Şube Adı']/gl-bus:organizationIdentifier)) >= 2">Şube adı değeri en az iki karakter olmalıdır.</assert>
			<assert test="gl-bus:organizationAddress">gl-bus:organizationAddress zorunlu bir elemandır.</assert>
			<assert test="not(gl-bus:organizationAddress) or gl-bus:organizationAddress/gl-bus:organizationBuildingNumber">gl-bus:organizationAddress elemanı içerisindeki gl-bus:organizationBuildingNumber zorunlu bir elemandır.</assert>
			<assert test="not(gl-bus:organizationAddress) or gl-bus:organizationAddress/gl-bus:organizationAddressStreet">gl-bus:organizationAddress elemanı içerisindeki gl-bus:organizationAddressStreet zorunlu bir elemandır.</assert>
			<assert test="not(gl-bus:organizationAddress) or gl-bus:organizationAddress/gl-bus:organizationAddressCity">gl-bus:organizationAddress elemanı içerisindeki gl-bus:organizationAddressCity zorunlu bir elemandır.</assert>
			<assert test="not(gl-bus:organizationAddress) or gl-bus:organizationAddress/gl-bus:organizationAddressZipOrPostalCode">gl-bus:organizationAddress' elemanı içerisindeki 'gl-bus:organizationAddressZipOrPostalCode zorunlu bir elemandır.</assert>
			<assert test="not(gl-bus:organizationAddress) or gl-bus:organizationAddress/gl-bus:organizationAddressCountry">gl-bus:organizationAddress elemanı içerisindeki gl-bus:organizationAddressCountry zorunlu bir elemandır.</assert>
			<assert test="gl-bus:entityWebSite">gl-bus:entityWebSite zorunlu bir elemandır.</assert>
			<assert test="string-length(normalize-space(gl-bus:businessDescription)) > 0">gl-bus:businessDescription zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
			<assert test="gl-bus:fiscalYearStart">gl-bus:fiscalYearStart zorunlu bir elemandır.</assert>
			<assert test="gl-bus:fiscalYearEnd">gl-bus:fiscalYearEnd zorunlu bir elemandır.</assert>
			<assert test="gl-bus:fiscalYearEnd > gl-bus:fiscalYearStart">gl-bus:fiscalYearEnd elemanı gl-bus:fiscalYearStart elemanından büyük olmalıdır.</assert>
			<assert test="gl-bus:accountantInformation">gl-bus:accountantInformation zorunlu bir elemandır.</assert>
		</rule>
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:accountantInformation">
			<assert test="string-length(normalize-space(gl-bus:accountantName)) > 0">gl-bus:accountantInformation elemanı içerisindeki gl-bus:accountantName zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
			<assert test="string-length(normalize-space(gl-bus:accountantEngagementTypeDescription)) > 0">gl-bus:accountantInformation elemanı içerisindeki gl-bus:accountantEngagementTypeDescription zorunlu bir elemandır  ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityPhoneNumber">
			<assert test="string-length(normalize-space(gl-bus:phoneNumber)) > 0">gl-bus:phoneNumber zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityEmailAddressStructure">
			<assert test="string-length(normalize-space(gl-bus:entityEmailAddress)) > 0">gl-bus:entityEmailAddressStructure elemanı içerisinde gl-bus:entityEmailAddress zorunlu bir elemandır ve  ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/envanter:berat/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityWebSite">
			<assert test="gl-bus:webSiteURL">gl-bus:entityWebSite elemanı içerisindeki gl-bus:webSiteURL zorunlu bir elemandır.</assert>
		</rule>
	</pattern>
</schema>
