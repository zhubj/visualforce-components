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
		system.assert( e.getAttribute('author') =='Manoj' ); 
		
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
	

	public static testmethod void test3() { 
	 	 string testNotification = 
	 	 '<?xml version="1.0" encoding="UTF-8"?>' +
			'<bookstore><book><title lang="eng">Harry Potter</title><price>29.99</price>' +
			'</book><book><title lang="eng">Learning XML</title><price>39.95</price></book></bookstore>';

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
		
		a = new XMLdom.Element(); 
		system.assertEquals( a.firstChild(), null, ' must be null' );
		
		system.assertEquals( a.getElementByTagName('bad'), null);				
	 }
	
}