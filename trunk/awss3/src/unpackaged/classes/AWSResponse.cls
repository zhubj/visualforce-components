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
/* 
 * parse XML responses from AWS S3 
 * used with AWSConnection()
 *
 */ 
public class AWSResponse {
	/* need to parse the following XML from AWS
	 * 
	ListBucketResult
		
	AccessControlPolicy

	Error
	*/
	HttpResponse res;
	String bodyStr;
	public AWSResponse(HttpResponse r) { 
		res = r;
		bodyStr = res.getBody(); 
	}
	Integer debug = 0;
	/* <Contents><Key>apex/adnDevSignup</Key><LastModified>2008-01-31T09:50:41.000Z</LastModified>'+
	'<ETag>&quot;2d9ab36295e58d32db358aae0195c164&quot;</ETag><Size>27410</Size><Owner><ID>owner_id</ID><DisplayName>vnehess</DisplayName></Owner>'+
	'<StorageClass>STANDARD</StorageClass></Contents>
	*/
	public class Contents {  Map <string,string> values; }
	
	public class ListBucketResult { Map <string,string> bucketProperties; List<Contents> contents; }
	public ListBucketResult  parseListBucketResponse (string str ) { 

     	Map <string,string> results = new Map <string,string>();
		XmlStreamReader reader = new XmlStreamReader(str);
		reader.setCoalescing(true);
		ListBucketResult lbr = new ListBucketResult();
		lbr.contents = new List<Contents>{};
		while(reader.hasNext()) { 

			if (reader.isStartElement() ) {
				if (reader.getLocalName() == 'Contents') { 
					Contents c = new Contents();
					c.values = getContents(reader);
					lbr.contents.add(c);	
				} else { 
	 	 			if(debug >3) system.debug( 'parseACLResponse '+reader.getEventType() + reader.getLocalName()  );	
	 	 			results.put( reader.getLocalName(), getValue(reader) );
				}
			}
			reader.next();
		}
		
		return lbr;
    }
    
    private Map <string,string>  getContents (xmlstreamreader reader ) { 
		Map <string,string> results = new Map <string,string>();
		while(reader.hasNext()) { 
			if (reader.isEndElement() && reader.getLocalName() == 'Contents')  break;
			if (reader.isStartElement() ) {
 	 			results.put( reader.getLocalName(), getValue(reader) );
			}
			reader.next();
		}
		if(debug > 4) system.debug(results);
		return results;
	}
	private string testListBucketResponse = 
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
	 
	public class Grant { String owner, displayName, permission; }
	public class AccessControlPolicy { String owner, displayName; List<Grant> grants; }
	
	public AccessControlPolicy parseACLResponse ( string str ) { 
		Map <string,string> results = new Map <string,string>();
		XmlStreamReader reader = new XmlStreamReader(str);
		reader.setCoalescing(true);
		AccessControlPolicy acp = new AccessControlPolicy();
		acp.grants = new List<Grant>{};
		while(reader.hasNext()) { 
			if(debug >3) system.debug( 'parseACLResponse '+reader.getEventType() + reader.getLocalName()  );
			
			//if (reader.isEndElement())  break;
			
			if (reader.isStartElement() ) {
				string n = reader.getLocalName();
 	 		
 	 			if (n=='AccessControlPolicy') {
 	 				acp.owner = getValue(reader,'ID'); // assumes the order of elements
 	 				acp.displayName= getValue(reader,'DisplayName');
 	 			}
 	 			
 	 			if (n=='Grantee') {
 	 				Grant g = new grant(); 
 	 				g.owner = getValue(reader,'ID'); // assumes the order of elements
 	 				g.displayName= getValue(reader,'DisplayName');
 	 				g.permission = getValue(reader,'Permission');
 	 				acp.grants.add(g);
 	 			}
 	 			
			}
			reader.next();
		}
		if(debug > 4) system.debug(results);
		return acp;
	}

	string getValue(XmlStreamReader reader) { String value; 
     	while(reader.hasNext()) {
	     	if (debug>2) system.debug( 'getValue '+reader.getEventType() );
	        if (reader.isEndElement()) break;
	        if (reader.isCharacters()) value = reader.getText();
	        reader.next();
     	} return value;
     }
	string getValue(XmlStreamReader reader, string sn) { 
		String value; 
     	while(reader.hasNext()) {
	     	if (debug > 2) system.debug( 'getValue2 '+reader.getEventType() + reader.getLocalName()  );
	        if (reader.isEndElement() && reader.getLocalName() == sn) 
	        	break;
	        if (reader.isCharacters() ) { 
	        	value = reader.getText();
	        }
	        reader.next();
     	} return value;
    }
     
	private string testACLResponse = 
	 '<?xml version="1.0" encoding="UTF-8"?>'+ 
	 '<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/"><Owner><ID>owner_id</ID><DisplayName>vnehess</DisplayName></Owner>'+
	 '<AccessControlList><Grant><Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser"><ID>owner_id</ID>'+
	 '<DisplayName>vnehess</DisplayName></Grantee><Permission>FULL_CONTROL</Permission></Grant></AccessControlList></AccessControlPolicy>';
	 
	/* return a map that looks like this 
	 * 
	 {Code=NoSuchKey, 
	 HostId=PB4hNZso0Ihimz0LQOoVMMoPOt0BRE3QRHcNp5Ua98tOl9hv0e677fmEA0dhr4oz, 
	 Key=test-key, 
	 Message=The specified key does not exist., 
	 RequestId=49D1F35F2DD55EBD}
	 */
	Map <string,string>  parseError ( string str ) { 
		Map <string,string> results = new Map <string,string>();
		XmlStreamReader reader = new XmlStreamReader(str);
		reader.setCoalescing(true);
		while(reader.hasNext()) { 
			if (reader.isEndElement())  break;
			if (reader.isStartElement() ) {
 	 			results.put( reader.getLocalName(), getValue(reader) );
			}
			reader.next();
		}
		if(debug > 4) system.debug(results);
		return results;
	}
	
	private string testErrorResponse = 
	 '<?xml version="1.0" encoding="UTF-8"?>'+ 
	 '<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message><Key>test-key</Key><RequestId>49D135F2DD55EBD</RequestId>'+
	 '<HostId>PB4hNZso0IhimzQOoVMMoPOt0BRE3QRHcNp5Ua98tOl9hv0e677fmEA0dhr4oz</HostId></Error>';
	
	public static testmethod void test1() {
		
		HttpResponse res = new HttpResponse();
		AWSResponse r = new AWSResponse(res); 
		r.debug = 30;
		AWSResponse.ListBucketResult lbr =  r.parseListBucketResponse(r.testListBucketResponse);
		system.debug( lbr);
		for (contents c: lbr.contents) { 
			system.debug( 'Key is ' + c.values.get('Key'));
			for (string s: c.values.keySet()) { 
				system.debug(s + ' is ' +c.values.get(s));
			}	
		}
		system.debug( r.parseACLResponse(r.testACLResponse) );
		system.debug( r.parseError(r.testErrorResponse) );
	}
	
 
}