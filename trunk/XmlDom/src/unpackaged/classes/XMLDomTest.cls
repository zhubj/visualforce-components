/*
Copyright (c) 2008 salesforce.com, inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions
are met:

1. Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
3. The name of the author may not be used to endorse or promote products
   derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR "AS IS" AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT, 
INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/
public class XMLDomTest { 
	
	public static testmethod void test1() { 
		xmldom d;		 
		d = new xmldom('<book  author="Manoj" >My Book</book>');
		d.dumpAll(); 
	 	XMLdom.Element e = d.getElementsByTagName('book')[0];
		system.debug( 'Author is ' + e.getAttribute('author') ); 
		
		d = new xmldom(); d.parseFromString('<book  author="Manoj" >My Book</book>');
		d.dumpAll(); 
		 
		d = new xmldom('<books><book>My Book</book></books>');
		d.dumpAll(); 
		//system.debug( d.getElements() ); 
		system.debug ( d.getElementsByTagName('book')[0].nodeValue );
		system.assert ( d.getElementsByTagName('book')[0].nodeValue == 'My Book' );
		
		d = new xmldom('<books><book author="Manoj" date="1999" >My Book</book><book author="Ron" >Your Book</book></books>'); 
		d.dumpAll();
		system.debug ( d.getElementsByTagName('book') );
		for(XMLdom.Element ee:d.getElementsByTagName('book')) { system.debug( 'Author is ' + ee.getAttribute('author')); }
		XMLdom.Element ee  = new xmldom.Element(); 
		
		
		string testListBucketResponse = 
			 '<?xml version="1.0" encoding="UTF-8"?>'+ 
			'<ListBucketResult xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Name>12gkzwnp21m8nw02-test-bucket</Name><Prefix>'+
			'</Prefix><Marker></Marker><MaxKeys>1000</MaxKeys><IsTruncated>false</IsTruncated><Contents><Key>/apex/adnDevSignup</Key>'+
			'<LastModified>2008-01-27T21:13:58.000Z</LastModified><ETag>&quot;630581ddc40fa0a3b7e521c67962baba&quot;</ETag><Size>27411</Size>'+
			'<Owner><ID>173ea00b3418d9a715d5f5a0d85290c3be11135ecf9a085504a4b1bbb6ea1</ID><DisplayName>vnehess</DisplayName></Owner>'+
			'<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>apex/adnDevSignup</Key><LastModified>2008-01-31T09:50:41.000Z</LastModified>'+
			'<ETag>&quot;2d9ab36295e58d32db358aae0195c164&quot;</ETag><Size>27410</Size><Owner><ID>owner_id</ID><DisplayName>vnehess</DisplayName></Owner>'+
			'<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>apex/adnRoot</Key><LastModified>2008-01-31T09:50:40.000Z</LastModified>'+
			'<ETag>&quot;f956a9612c95c206f3208f023d1edefb&quot;</ETag><Size>20036</Size><Owner><ID>owner_id</ID><DisplayName>vnehess</DisplayName></Owner>'+
			'<StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test-key-public</Key><LastModified>2008-02-02T04:02:59.000Z</LastModified>'+
			'<ETag>&quot;12f3e46f80c24c997c4304953edc3612&quot;</ETag><Size>32</Size><Owner><ID>173ea00891b39a715d5f5a0d85290c3be11135ecf9a085504a4b1bbb6ea1</ID>'+
			'<DisplayName>vnehess</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents><Contents><Key>test-two</Key>'+
			'<LastModified>2008-02-02T00:40:29.000Z</LastModified><ETag>&quot;327b6f07435811239bc47e1544353273&quot;</ETag><Size>7</Size>'+
			'<Owner><ID>173</ID><DisplayName>vnehess</DisplayName></Owner><StorageClass>STANDARD</StorageClass></Contents></ListBucketResult>';
		d = new xmldom(testListBucketResponse); 
		d.dumpAll();
		List<xmldom.Element> keys = d.getElementsByTagName('Key');
		
		//system.debug ( keys ); 
		for(XMLdom.Element e2:keys) { system.debug( 'Key is '  + e2.nodeValue ); }
		
		integer count= keys.size();
		system.assert(count>1);
		system.debug(count);
		
		XMLdom.Element p = keys[0].parentNode;
		p.removeChild(p.firstChild());
		
		keys = d.getElementsByTagName('Key');
		system.assert(keys.size() == count-1);
		
		keys = d.root.getElementsByTagName('Key');
		for(XMLdom.Element e2: keys ) { system.debug( 'Key is ' + e2.nodeValue ); 
		 e2.dump(); 
		 }
		count= keys.size();
		system.assert(count>1);
		system.debug(count);
		
		string testErrorResponse = 
		 '<?xml version="1.0" encoding="UTF-8"?>'+ 
		 '<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message><Key>test-key</Key><RequestId>49D135F2DD55EBD</RequestId>'+
		 '<HostId>PB4hNZso0IhimzQOoVMMoPOt0BRE3QRHcNp5Ua98tOl9hv0e677fmEA0dhr4oz</HostId></Error>';
	
		d = new xmldom(testErrorResponse); 
		d.root.dumpAll();
		
		// uses namespaces
		 string testACLResponse = 
	 '<?xml version="1.0" encoding="UTF-8"?>'+ 
	 '<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>owner_id</ID><DisplayName>vnehess</DisplayName></Owner>'+
	 '<AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser" foo="bar" ><ID>owner_id</ID>'+
	 '<DisplayName>vnehess</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant></AccessControlList></AccessControlPolicy>';
		d = new xmldom(testACLResponse); 
		d.dumpAll(); 
		system.debug ('has child '+ d.root.hasChildNodes()) ; 
		
		system.assert(  d.root.isEqualNode(d.root) ,' is equal node');
		system.assert( d.root.textContent() == '' );
		 
		d.getElementsByTagName('Grantee')[0].dump(); 
		
		system.assert( d.getElementsByTagName('Grantee')[0].hasAttributes() );
		
			
		
	}
	
	public static testmethod void test2() { 
	 	 string testNotification = '<?xml version="1.0" encoding="UTF-8"?>' +
'<notification-data-response xmlns="http://checkout.google.com/schema/2" serial-number="9d0e62c6-afc8-44ce-a985-180b37356059">' + 
'  <notifications>' + 
'   <new-order-notification  serial-number="377345681025137-00001-7">' + 
      '<timestamp>2008-03-04T20:56:40.606Z</timestamp>' + 
      '<buyer-id>756525894341880</buyer-id>' + 
      '<shopping-cart>' + 
        '<items>' + 
          '<item>' + 
          '  <merchant-item-id>33</merchant-item-id> '+
            '<item-name>Donate to our Cause</item-name>' + 
            '<item-description>Thank you for your contribution!</item-description>' + 
            '<unit-price currency="USD">55.0</unit-price>' + 
            '<quantity>1</quantity>' + 
          '</item>' + 
        '</items>' + 
      '</shopping-cart>' + 
      '<order-adjustment>' + 
        '<merchant-codes />' + 
        '<total-tax currency="USD">0.0</total-tax>' + 
       '<adjustment-total currency="USD">0.0</adjustment-total>' + 
     '</order-adjustment>' + 
     '<google-order-number>377345681025137</google-order-number>' + 
     '<buyer-shipping-address>' + 
       '<email>sfdctestbuyer2@gmail.com</email>' + 
       '<company-name></company-name>' + 
       '<contact-name>Bob Cardholder</contact-name>' + 
       '<phone></phone>' + 
       '<fax></fax>' + 
       '<address1>1234 MainShipping St.</address1>' + 
       '<address2>apt 2</address2>' + 
       '<country-code>US</country-code>' + 
       '<city>Moline</city>' + 
       '<region>TX</region>' + 
       '<postal-code>61265</postal-code>' + 
     '</buyer-shipping-address>' + 
     '<buyer-billing-address>' + 
       '<email>sfdctestbuyer2@gmail.com</email>' + 
       '<company-name></company-name>' + 
       '<contact-name>Bob Cardholder</contact-name>' + 
       '<phone></phone>' + 
       '<fax></fax>' + 
       '<address1>1234 MainBilling St.</address1>' + 
       '<address2>apt 1</address2>' + 
       '<country-code>US</country-code>' + 
       '<city>Moline</city>' + 
       '<region>IL</region>' + 
       '<postal-code>61266</postal-code>' + 
     '</buyer-billing-address>' + 
     '<buyer-marketing-preferences>' + 
       '<email-allowed>false</email-allowed>' + 
     '</buyer-marketing-preferences>' + 
     '<order-total currency="USD">55.0</order-total>' + 
     '<fulfillment-order-state>NEW</fulfillment-order-state>' + 
     '<financial-order-state>REVIEWING</financial-order-state>' + 
   ' </new-order-notification>' +

   ' <order-state-change-notification serial-number="377345681025137-00010-1">' +
     '<timestamp>2008-03-04T20:57:42.530Z</timestamp>' +
     '<google-order-number>377345681025137</google-order-number>' +
     '<new-fulfillment-order-state>PROCESSING</new-fulfillment-order-state>' +
     '<new-financial-order-state>CHARGED</new-financial-order-state>' +
     '<previous-fulfillment-order-state>PROCESSING</previous-fulfillment-order-state>' +
     '<previous-financial-order-state>CHARGING</previous-financial-order-state>' +
   ' </order-state-change-notification>' +
   ' <order-state-change-notification serial-number="377345681025137-00011-1">' +
     '<timestamp>2008-03-04T20:57:42.561Z</timestamp>' +
     '<google-order-number>377345681025137</google-order-number>' +
     '<new-fulfillment-order-state>DELIVERED</new-fulfillment-order-state>' +
     '<new-financial-order-state>CHARGING</new-financial-order-state>' +
     '<previous-fulfillment-order-state>PROCESSING</previous-fulfillment-order-state>' +
     '<previous-financial-order-state>CHARGING</previous-financial-order-state>' +
   '</order-state-change-notification> ' +
 '</notifications></notification-data-response>' ;
		xmldom d;
		list<xmldom.element> tmp ; 
	 	d = new xmldom(testNotification);  
	
		// select nodes with a path type specification
		tmp =  d.root.getElementsByTagName('notifications'); 
		system.assertEquals( 1, tmp.size() ); 
		d.dumpList( tmp );
	
		tmp =  d.root.getElementsByTagName('timestamp'); 
		system.assertEquals( 3, tmp.size() ); 
		d.dumpList( tmp );
	  
		tmp =  d.root.getElementsByTagName('new-fulfillment-order-state'); 
		system.assertEquals( 2, tmp.size() ); 
		d.dumpList( tmp );
	
	}
	

	public static testmethod void test3() { 
	 	 string testNotification = '<?xml version="1.0" encoding="UTF-8"?>' +
			'<bookstore><book><title lang="eng">Harry Potter</title><price>29.99</price>' +
			'</book><book><title lang="eng">Learning XML</title>' +
			'<price>39.95</price></book></bookstore>';

 		xmldom d;
	 	d = new xmldom(testNotification);  
	 	list<xmldom.element> tmp ; 

		tmp =  d.root.getElementsByTagName('book');  // matching by name
		system.assertEquals( 2, tmp.size() ); 
		d.dumpList( tmp );
		
		XMLdom.Element a = d.ownerDocument();
		XMLdom.Element f = a.firstChild();
		XMLdom.Element c = f.ownerDocument(); 
		system.assert( a.isSameNode( c ) );
		XMLdom.Element b = a.cloneNode();
		system.assert( ! a.isSameNode(f) ); 
						
	 }
	
}