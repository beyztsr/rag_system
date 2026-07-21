<?xml version="1.0" encoding="UTF-8"?>
<schema xmlns="http://purl.oclc.org/dsdl/schematron" xmlns:sch="http://purl.oclc.org/dsdl/schematron" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fct="localFunctions" queryBinding="xslt2">
	<ns prefix="gl-plt" uri="http://www.xbrl.org/int/gl/plt/2010-04-16"/>
	<ns prefix="gl-cor" uri="http://www.xbrl.org/int/gl/cor/2006-10-25"/>
	<ns prefix="gl-bus" uri="http://www.xbrl.org/int/gl/bus/2006-10-25"/>
	<ns prefix="gl-muc" uri="http://www.xbrl.org/int/gl/muc/2006-10-25"/>
	<ns prefix="xbrli" uri="http://www.xbrl.org/2003/instance"/>
	<ns prefix="ds" uri="http://www.w3.org/2000/09/xmldsig#"/>
	<ns prefix="xades" uri="http://uri.etsi.org/01903/v1.3.2#"/>
	<ns prefix="edefter" uri="http://www.edefter.gov.tr"/>
	<ns prefix="fct" uri="localFunctions"/>
	<ns prefix="defterek" uri="http://www.edefter.gov.tr/ek"/>
	<title>Büyük defter dokümanlarını kontrol etmek için gerekli olan schematron kuralları</title>
	<let name="periodCoveredStart" value="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-cor:periodCoveredStart"/>
	<let name="periodCoveredEnd" value="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-cor:periodCoveredEnd"/>
	<let name="vknTckn" value="/edefter:defter/xbrli:xbrl/xbrli:context/xbrli:entity/xbrli:identifier"/>
	<let name="donemYil" value="substring($periodCoveredStart,1,4)"/>
	<let name="donemAy" value="substring($periodCoveredStart,6,2)"/>
	<let name="donem" value="number(concat($donemYil,$donemAy))"/>
	<let name="dosyaAdi" value="base-uri()"/>
	<pattern id="kok">
		<rule context="*">
			<assert test="not(@decimals) or  @decimals = 'INF'">Belge içerisindeki 'decimals' nitelikleri 'INF' değerini almalıdır.</assert>
		</rule>
		<rule context="/">
			<assert test="edefter:defter">Büyük defter dokümanı edefter:defter ana elemanı ile başlamalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="entity">
		<rule context="/edefter:defter/xbrli:xbrl/xbrli:context/xbrli:entity">
			<assert test="not(xbrli:segment/gl-bus:numberOfEntries)"> xbrli:segment/gl-bus:numberOfEntries sadece yevmiye beratında bulunabilir.</assert>
			<assert test="not(xbrli:segment/gl-cor:uniqueID)">xbrli:segment/gl-cor:uniqueID sadece beratlarda bulunabilir.</assert>
			<assert test="contains($dosyaAdi,concat(xbrli:identifier,'-'))">Dosya adına yazılan vkn/tckn ile xbrli:identifier elemanına yazılan vkn/tckn aynı olmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="defter">
		<rule context="/edefter:defter">
			<assert test="ds:Signature">ds:Signature zorunlu bir elemandır.</assert>
			<assert test="count(extensions/extension/defterek:binaryObject) = 0 ">defterek:binaryObject elemanı sadece yevmiye defterinde bulunabilir.</assert>
		</rule>
	</pattern>
	<pattern id="signature">
		<rule context="/edefter:defter/ds:Signature">
			<let name="signatureMethodAlgorithm" value="ds:SignedInfo/ds:SignatureMethod/@Algorithm"/>
			<assert test="ds:SignedInfo/ds:Reference/ds:Transforms">ds:SignedInfo/ds:Reference/ds:Transforms elemanı zorunlu bir elemandır.</assert>
			<assert test="ds:KeyInfo">ds:KeyInfo elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:KeyInfo) or ds:KeyInfo/ds:X509Data">ds:KeyInfo elemanı içerisindeki ds:X509Data elemanı zorunlu bir elemandır.</assert>
			<assert test="ds:Object">ds:Object elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:Object) or ds:Object/xades:QualifyingProperties/xades:SignedProperties/xades:SignedSignatureProperties/xades:SigningTime">xades:SigningTime elemanı zorunlu bir elemandır.</assert>
			<assert test="not(ds:Object) or ds:Object/xades:QualifyingProperties/xades:SignedProperties/xades:SignedSignatureProperties/xades:SigningCertificate">xades:SigningCertificate elemanı zorunlu bir elemandır</assert>
			<assert test="count(ds:SignedInfo/ds:Reference[@URI = '']) = 1 ">ds:SignedInfo elamanı içerisinde URI niteliği boşluğa("") eşit olan sadece bir tane ds:Reference elemanının bulunmaldır.</assert>
			<assert test="not(ends-with($signatureMethodAlgorithm,'sha1'))">İmzalama işleminde kullanılacak özet(hash) algoritması sha1 olmamalıdır.</assert>
		</rule>
		<rule context="/edefter:defter/ds:Signature/ds:KeyInfo/ds:X509Data">
			<assert test="ds:X509Certificate">ds:X509Data elemanı içerisindeki ds:X509Certificate elemanı zorunlu bir elemandır.</assert>
		</rule>
		<rule context="/edefter:defter/ds:Signature/ds:KeyInfo/ds:X509Data/ds:X509SubjectName">
			<assert test="string-length(normalize-space(.)) != 0 "> ds:X509SubjectName elemanının değeri boşluk olmamalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="xbrl">
		<rule context="/edefter:defter/xbrli:xbrl">
			<assert test="count(xbrli:context) = 1 ">xbrli:context zorunlu bir elemandır.</assert>
			<assert test="count(xbrli:unit) >= 1 ">xbrli:unit zorunlu bir elemandır.</assert>
			<assert test="count(gl-cor:accountingEntries) = 1 ">gl-cor:accountingEntries zorunlu bir elemandır.</assert>
			<assert test="count(xbrli:unit/xbrli:measure) >= 1 ">xbrli:measure zorunlu bir elemandır.</assert>
		</rule>
		<rule context="/edefter:defter/xbrli:xbrl/xbrli:context/xbrli:entity/xbrli:identifier">
			<assert test="matches(normalize-space(.) , '^[0-9]{10,11}$')">xbrli:identifier elemanına 10 haneli vergi kimlik numarası ve ya 11 haneli TC kimlik numarası yazılmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="measure">
		<rule context="/edefter:defter/xbrli:xbrl/xbrli:unit/xbrli:measure">
			<let name="currency" value="substring(.,9)"/>
			<let name="currencyCodeList" value="',AED,AFN,ALL,AMD,ANG,AOA,ARS,AUD,AWG,AZN,BAM,BBD,BDT,BGN,BHD,BIF,BMD,BND,BOB,BOV,BRL,BSD,BTN,BWP,BYN,BYR,BZD,CAD,CDF,CHE,CHF,CHW,CLF,CLP,CNY,COP,COU,CRC,CUC,CUP,CVE,CZK,DJF,DKK,DOP,DZD,EEK,EGP,ERN,ETB,EUR,FJD,FKP,GBP,GEL,GHS,GIP,GMD,GNF,GTQ,GWP,GYD,HKD,HNL,HRK,HTG,HUF,IDR,ILS,INR,IQD,IRR,ISK,JMD,JOD,JPY,KES,KGS,KHR,KMF,KPW,KRW,KWD,KYD,KZT,LAK,LBP,LKR,LRD,LSL,LTL,LVL,LYD,MAD,MAD,MDL,MGA,MKD,MMK,MNT,MOP,MRO,MUR,MVR,MWK,MXN,MXV,MYR,MZN,NAD,NGN,NIO,NOK,NPR,NZD,OMR,PAB,PEN,PGK,PHP,PKR,PLN,PYG,QAR,RON,RSD,RUB,RWF,SAR,SBD,SCR,SDG,SEK,SGD,SHP,SLL,SOS,SSP,SRD,STD,SVC,SYP,SZL,THB,TJS,TMT,TND,TOP,TRY,TTD,TWD,TZS,UAH,UGX,USD,USN,USS,UYI,UYU,UZS,VEF,VND,VUV,WST,XAF,XAG,XAU,XBA,XBB,XBC,XBD,XCD,XDR,XFU,XOF,XPD,XPF,XPT,XSU,XTS,XUA,XXX,YER,ZAR,ZMK,ZMW,ZWL,'"/>
			<assert test="not (starts-with(normalize-space(.),'iso4217:')) or contains($currencyCodeList, concat(',',$currency,','))">Gecersiz currency degeri: '<sch:value-of select="$currency"/>'.</assert>
			<assert test="count(parent::node()[contains($currencyCodeList, @id)]) &lt;=1 ">id'si iso4217 multicurrency kodlarından birisi olan en fazla 1 xbrli:unit elemanı olabilir. </assert>
			<assert test="not(parent::node()[contains($currencyCodeList, @id)]) or  .= concat('iso4217:',parent::node()/@id) ">xbrli:measure değeri (<sch:value-of select="."/>) hatalıdır. xbrli:unit id'nin değeri <sch:value-of select="parent::node()/@id"/> olduğu için xbrli:measure değeri <sch:value-of select="concat('iso4217:',parent::node()/@id)"/> olmalıdır. </assert>
			<assert test="not(parent::node()[contains($currencyCodeList, @id)]) or  not(/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency) or not(.= concat('iso4217:',parent::node()/@id)) or /edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency=."> gl-muc:defaultCurrency değeri (<sch:value-of select="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency"/>) hatalıdır. gl-muc:defaultCurrency elemanı varsa değeri xbrli:measure(<sch:value-of select="."/>) ile aynı olmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="accountingentries">
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries">
			<assert test="gl-cor:documentInfo">gl-cor:documentInfo zorunlu bir elemandır.</assert>
			<assert test="gl-cor:entityInformation">gl-cor:entityInformation zorunlu bir elemandır.</assert>
			<let name="accoundMainIdList" value="gl-cor:entryHeader/gl-cor:entryDetail[1]/gl-cor:account/normalize-space(gl-cor:accountMainID)"/>
			<assert test="fct:isSorted($accoundMainIdList)">Büyük defterde hesaplar, ana hesap numarası bazında sıralı olmalıdır.</assert>
			<let name="altHesabiOlmayanAnaHesapListesi" value="gl-cor:entryHeader/gl-cor:entryDetail[1]/gl-cor:account[count(gl-cor:accountSub)=0]/normalize-space(gl-cor:accountMainID)"/>
			<let name="altHesabiOlmayanAnaHesapSayisi" value="count($altHesabiOlmayanAnaHesapListesi)"/>
			<let name="farkliAltHesabiOlmayanAnaHesapSayisi" value="count(distinct-values($altHesabiOlmayanAnaHesapListesi))"/>
			<assert test="$altHesabiOlmayanAnaHesapSayisi = $farkliAltHesabiOlmayanAnaHesapSayisi">Alt hesabı olmayan aynı hesaplar aynı gl-cor:entryHeader elemanı içerisinde bulunmalıdır.</assert>
			<let name="altHesapListesi" value="gl-cor:entryHeader/gl-cor:entryDetail[1]/gl-cor:account/gl-cor:accountSub/normalize-space(gl-cor:accountSubID)"/>
			<let name="altHesapSayisi" value="count($altHesapListesi)"/>
			<let name="farkliAltHesapSayisi" value="count(distinct-values($altHesapListesi))"/>
			<assert test="$altHesapSayisi = $farkliAltHesapSayisi">Aynı alt hesaplar aynı gl-cor:entryHeader elemanı içerisinde bulunmalıdır.</assert>
		</rule>
	</pattern>
	<pattern id="documentinfo">
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo">
			<assert test="gl-cor:entriesType">gl-cor:entriesType zorunlu bir elemandır.</assert>
			<assert test="normalize-space(gl-cor:entriesType) = 'ledger'">gl-cor:entriesType elemanı büyük defter için 'ledger' değerini almalıdır.</assert>
			<assert test="gl-cor:uniqueID">gl-cor:uniqueID zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:uniqueID) or starts-with(normalize-space(gl-cor:uniqueID),'KEB')">gl-cor:uniqueID elemanı büyük defter için 'KEB' değeri ile başlamalıdır.</assert>
			<assert test="not(gl-cor:uniqueID) or string-length(normalize-space(gl-cor:uniqueID)) = 15">gl-cor:uniqueID elemanı 15 karakterden oluşmalıdır.</assert>
			<assert test="gl-cor:creationDate">gl-cor:creationDate zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredStart">gl-cor:periodCoveredStart zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredEnd">gl-cor:periodCoveredEnd zorunlu bir elemandır.</assert>
			<assert test="gl-cor:periodCoveredEnd >= gl-cor:periodCoveredStart">gl-cor:periodCoveredEnd elemanı gl-cor:periodCoveredStart elemanından büyük ve ya eşit olmalıdır. </assert>
			<assert test="gl-cor:creationDate >= gl-cor:periodCoveredEnd">gl-cor:creationDate elemanı gl-cor:periodCoveredEnd elemanından büyük veya eşit olmalıdır. </assert>
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
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation">
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
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:accountantInformation">
			<assert test="string-length(normalize-space(gl-bus:accountantName)) > 0">gl-bus:accountantInformation elemanı içerisindeki gl-bus:accountantName zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
			<assert test="string-length(normalize-space(gl-bus:accountantEngagementTypeDescription)) > 0">gl-bus:accountantInformation elemanı içerisindeki gl-bus:accountantEngagementTypeDescription zorunlu bir elemandır  ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityPhoneNumber">
			<assert test="string-length(normalize-space(gl-bus:phoneNumber)) > 0">gl-bus:phoneNumber zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityEmailAddressStructure">
			<assert test="string-length(normalize-space(gl-bus:entityEmailAddress)) > 0">gl-bus:entityEmailAddressStructure elemanı içerisinde gl-bus:entityEmailAddress zorunlu bir elemandır ve  ve değeri boşluk olmamalıdır.</assert>
		</rule>
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entityInformation/gl-bus:entityWebSite">
			<assert test="gl-bus:webSiteURL">gl-bus:entityWebSite elemanı içerisindeki gl-bus:webSiteURL zorunlu bir elemandır.</assert>
		</rule>
	</pattern>
	<pattern id="entryheader">
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entryHeader">
			<assert test="gl-bus:totalDebit">gl-bus:totalDebit zorunlu bir elemandır.</assert>
			<assert test="gl-bus:totalCredit">gl-bus:totalCredit zorunlu bir elemandır.</assert>
			<assert test="count(gl-cor:entryDetail) > 0">gl-cor:entryHeader elemanı en az bir gl-cor:entryDetail elemanı içermelidir.</assert>
			<assert test="gl-bus:totalDebit >= 0">gl-bus:totalDebit değeri 0 ve ya daha büyük bir değere eşit olmalıdır.</assert>
			<assert test="gl-bus:totalCredit >= 0">gl-bus:totalCredit değeri 0 ve ya daha büyük bir değere eşit olmalıdır.</assert>
			<assert test="gl-bus:totalDebit = 0 or gl-bus:totalCredit = 0">gl-bus:totalDebit ve gl-bus:totalCredit değerlerinden en az biri 0 olmalıdır.</assert>
			<let name="debitToplam" value="sum(gl-cor:entryDetail[gl-cor:debitCreditCode = 'D' or gl-cor:debitCreditCode = 'debit']/xs:decimal(gl-cor:amount))"/>
			<let name="creditToplam" value="sum(gl-cor:entryDetail[gl-cor:debitCreditCode = 'C' or gl-cor:debitCreditCode = 'credit']/xs:decimal(gl-cor:amount))"/>
			<assert test="gl-bus:totalDebit - gl-bus:totalCredit = $debitToplam - $creditToplam ">gl-bus:totalDebit ile gl-bus:totalCredit değerlerinin farkı, gl-cor:entryDetail elemanı içerisindeki gl-cor:debitCreditCode değeri 'D' ve ya 'debit' olan gl-cor:amount değerlerinin toplamı ile gl-cor:debitCreditCode değeri 'C' ve ya 'credit' olan gl-cor:amount değerlerinin toplamının farkına eşit olmalıdır.</assert>
			<assert test="count(distinct-values(gl-cor:entryDetail/gl-cor:account/normalize-space(gl-cor:accountMainID))) = 1">Buyuk defter için gl-cor:entryDetail elemanı içersindeki gl-cor:accountMainID değerleri birbirine eşit olmalıdır.</assert>
			<let name="farkliAltHesapSayisi" value="count(distinct-values(gl-cor:entryDetail/gl-cor:account/gl-cor:accountSub/normalize-space(gl-cor:accountSubID)))"/>
			<assert test="$farkliAltHesapSayisi = 0 or $farkliAltHesapSayisi = 1">Buyuk defter için gl-cor:entryDetail elemanı içersindeki gl-cor:accountSubID değerleri birbirine eşit olmalıdır.</assert>
			<assert test="matches(normalize-space(gl-bus:totalDebit) , '^[0-9]+(\.[0-9]{1,2})?$')">gl-bus:totalDebit (<value-of select="gl-bus:totalDebit"/>) virgülden sonra 2 haneden fazla olamaz.</assert>
			<assert test="matches(normalize-space(gl-bus:totalCredit) , '^[0-9]+(\.[0-9]{1,2})?$')">gl-bus:totalCredit (<value-of select="gl-bus:totalCredit"/>) virgülden sonra 2 haneden fazla olamaz.</assert>
		</rule>
	</pattern>
	<pattern id="entrydetail">
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entryHeader/gl-cor:entryDetail">
			<assert test="gl-cor:lineNumber">gl-cor:lineNumber zorunlu bir elemandır.</assert>
			<assert test="gl-cor:lineNumberCounter">gl-cor:lineNumberCounter zorunlu bir elemandır.</assert>
			<assert test="not(preceding-sibling::node()) or not(preceding-sibling::node()/gl-cor:lineNumberCounter) or not(gl-cor:lineNumberCounter) or xs:decimal(gl-cor:lineNumberCounter) >= max(preceding-sibling::node()/xs:decimal(gl-cor:lineNumberCounter))">gl-cor:entryDetail elemanı içersindeki gl-cor:lineNumberCounter değeri bir önceki gl-cor:entryDetail elemanları içerisindeki gl-cor:lineNumberCounter değerinden büyük ve ya eşit olmalıdır.</assert>
			<assert test="gl-cor:account">gl-cor:account zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:account) or not(gl-cor:account/gl-cor:accountMainID) or string-length(gl-cor:account/normalize-space(gl-cor:accountMainID)) = 3 or string-length(gl-cor:account/normalize-space(gl-cor:accountMainID)) = 4">gl-cor:account elemanı içerisinde gl-cor:accountMainID zorunlu bir elemandır ve en az 3 karakter olmalıdır.</assert>
			<assert test="not(gl-cor:account) or gl-cor:account/gl-cor:accountMainDescription">gl-cor:account elemanı içerisinde gl-cor:accountMainDescription zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:account/gl-cor:accountSub) or gl-cor:account/gl-cor:accountSub/gl-cor:accountSubID">gl-cor:accountSub elemanı içerisinde gl-cor:accountSubID zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:account/gl-cor:accountSub) or gl-cor:account/gl-cor:accountSub/gl-cor:accountSubDescription">gl-cor:accountSub elemanı içerisinde gl-cor:accountSubDescription zorunlu bir elemandır.</assert>
			<let name="anaHesapId" value="gl-cor:account/normalize-space(gl-cor:accountMainID)"/>
			<let name="altHesapId" value="gl-cor:account/normalize-space(gl-cor:accountSub/gl-cor:accountSubID)"/>
			<assert test="not($anaHesapId) or not($altHesapId) or starts-with($altHesapId, $anaHesapId)">gl-cor:accountSubID(alt hesap numarası) elemanı gl-cor:accountMainID(ana hesap numarası) değeri ile başlamalıdır.</assert>
			<assert test="gl-cor:amount">gl-cor:amount zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:amount) or gl-cor:amount > 0">gl-cor:amount elemanı 0'dan büyük bir değer almalıdır.</assert>
			<assert test="not(gl-muc:amountCurrency) or  /edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:documentInfo/gl-muc:defaultCurrency">gl-muc:amountCurrency olması durumunda gl-muc:defaultCurrency elemanı da bulunmalıdır </assert>
			<assert test="not(gl-muc:amountOriginalAmount) or gl-muc:amountOriginalExchangeRateDate"> gl-muc:amountOriginalAmount elemanı olması durumunda gl-muc:amountOriginalExchangeRateDate elemanı da bulunmalıdır.</assert>
			<assert test="not(gl-muc:amountOriginalAmount) or gl-muc:amountOriginalCurrency">gl-muc:amountOriginalAmount elemanı olması durumunda gl-muc:amountOriginalCurrency elemanı da bulunmalıdır.</assert>
			<assert test="not(gl-muc:amountOriginalCurrency) or gl-muc:amountOriginalExchangeRate">gl-muc:amountOriginalCurrency elemanı olması durumunda gl-muc:amountOriginalExchangeRate elemanı da bulunmalıdır.</assert>
			<assert test="gl-cor:debitCreditCode">gl-cor:debitCreditCode zorunlu bir elemandır.</assert>
			<assert test="gl-cor:postingDate">gl-cor:postingDate zorunlu bir elemandır.</assert>
			<assert test="not(gl-cor:postingDate) or (gl-cor:postingDate >= $periodCoveredStart and gl-cor:postingDate &lt;= $periodCoveredEnd)">gl-cor:postingDate elemanın değeri <value-of select="$periodCoveredStart"/> ile <value-of select="$periodCoveredEnd"/> değerleri arasında olmalıdır.</assert>
			<assert test="not(normalize-space(gl-cor:documentType) = 'other') or string-length(normalize-space(gl-cor:documentTypeDescription)) > 0">gl-cor:documentType eleman değerinin 'other' olması durumunda gl-cor:documentTypeDescription zorunlu bir elemandır ve değeri boşluk olmamalıdır.</assert>
			<assert test="not(normalize-space(gl-cor:documentType) = 'other') or (string-length(normalize-space(gl-cor:documentNumber)) > 0 and gl-cor:documentDate)">gl-cor:documentType elemanının değeri 'other' olması durumunda gl-cor:documentNumber ve gl-cor:documentDate elemanları da olmalıdır.</assert>
			<assert test="not(normalize-space(gl-cor:documentType) = 'invoice') or (string-length(normalize-space(gl-cor:documentNumber)) > 0 and gl-cor:documentDate)">gl-cor:documentType elemanının değeri 'invoice' (fatura) olması durumunda gl-cor:documentNumber ve gl-cor:documentDate elemanlarıda olmalıdır.</assert>
			<assert test="not(normalize-space(gl-cor:documentType) = 'check') or (string-length(normalize-space(gl-cor:documentNumber)) > 0 and gl-cor:documentDate)">gl-cor:documentType elemanının değeri 'check' (çek) olması durumunda gl-cor:documentNumber ve gl-cor:documentDate elemanlarıda olmalıdır.</assert>
			<assert test="not(gl-cor:documentNumber) or gl-cor:documentType">gl-cor:documentNumber elemanı olması durumunda gl-cor:documentType elemanı bulunmalıdır.</assert>
			<assert test="not(gl-cor:documentDate) or gl-cor:documentType">gl-cor:documentDate elemanı olması durumunda gl-cor:documentType elemanı bulunmalıdır.</assert>
			<assert test="count(gl-bus:measurable) &lt; 2">En fazla 1 adet gl-bus:measurable elemanı olabilir.</assert>
			<assert test="matches(normalize-space(gl-cor:amount) , '^[0-9]+(\.[0-9]{1,2})?$')">gl-cor:amount (<value-of select="gl-cor:amount"/>) virgülden sonra 2 haneden fazla olamaz.</assert>
		</rule>
	</pattern>
	<pattern id="measurable">
		<rule context="/edefter:defter/xbrli:xbrl/gl-cor:accountingEntries/gl-cor:entryHeader/gl-cor:entryDetail/gl-bus:measurable">
			<assert test="gl-bus:measurableCode">gl-bus:measurableCode elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableCodeDescription">gl-bus:measurableCodeDescription elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableQuantity">gl-bus:measurableQuantity elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableQualifier">gl-bus:measurableQualifier elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableUnitOfMeasure">gl-bus:measurableUnitOfMeasure elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableCostPerUnit">gl-bus:measurableCostPerUnit elemanı zorunludur.</assert>
			<assert test="gl-bus:measurableCode='NT'">gl-bus:measurableCode elemanının değeri "NT" olmalıdır.</assert>
			<assert test="gl-bus:measurableCodeDescription='Maddi Olmayan Kalemler'">gl-bus:measurableCodeDescription elemanının değeri "Maddi Olmayan Kalemler" olmalıdır.</assert>
			<assert test="gl-bus:measurableQualifier='Fon'">gl-bus:measurableQualifier elemanının değeri "Fon" olmalıdır.</assert>
			<assert test="gl-bus:measurableUnitOfMeasure='Adet'">gl-bus:measurableUnitOfMeasure elemanının değeri "Adet" olmalıdır.</assert>
			<assert test="parent::node()/gl-cor:amount=gl-bus:measurableCostPerUnit*gl-bus:measurableQuantity"> gl-bus:measurableCostPerUnit * gl-bus:measurableQuantity = gl-cor:amount olmalıdır.</assert>
		</rule>
	</pattern>
	<xsl:function name="fct:isSorted" as="xs:boolean">
		<xsl:param name="accoundMainIdList" as="xs:string*"/>
		<xsl:variable name="sortedAccountMainIdList" as="xs:string*">
			<xsl:for-each select="$accoundMainIdList">
				<xsl:sort/>
				<xsl:value-of select="."/>
			</xsl:for-each>
		</xsl:variable>
		<xsl:variable name="s1">
			<xsl:value-of select="string-join($accoundMainIdList,'|')"/>
		</xsl:variable>
		<xsl:variable name="s2">
			<xsl:value-of select="string-join($sortedAccountMainIdList,'|')"/>
		</xsl:variable>
		<xsl:choose>
			<xsl:when test="$s1 = $s2">
				<xsl:value-of select="true()"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:value-of select="false()"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
</schema>
