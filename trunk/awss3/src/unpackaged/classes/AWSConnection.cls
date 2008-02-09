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
 * example of connector class to send and retrieve data from Amazon S3 using REST
 * after install , you must add https://s3.amazonaws.com to your remote site access list 
 *
 * rhess at salesforce.com
 */ 
 
 /*
  * this class assumes the following user custom fields
  *
  
  <?xml version="1.0" encoding="UTF-8"?>
<CustomObject xmlns="http://soap.sforce.com/2006/04/metadata">
    <fields>
        <fullName>AWS_Key__c</fullName>
        <inlineHelpText>Amazon S3 Key</inlineHelpText>
        <label>AWS Key</label>
        <length>64</length>
        <type>Text</type>
    </fields>
    <fields>
        <fullName>AWS_Secret__c</fullName>
        <label>AWS Secret</label>
        <length>128</length>
        <type>Text</type>
    </fields>
</CustomObject>
  
  */
public class AWSConnection {
	private final string serviceEndPoint = 'https://s3.amazonaws.com:443/';
	integer debug = 3;	
 	private string AWS_ACCESS_KEY_ID = '';  
	private string AWS_SECRET_ACCESS_KEY = '';
	private string BUCKET_NAME = null; private string key = ''; 
	
	private HttpResponse res = null;
	private Map<String,String> headers = new Map<String, String>{};
	private string body=null; 
	private String dateString; 	
	private string userid = null;
	
	public AWSConnection() {
		userid = UserInfo.getUserId();
		User usr = [select AWS_Key__c, AWS_Secret__c from user where id=:userid limit 1];				
		AWS_ACCESS_KEY_ID = usr.AWS_Key__c;
		AWS_SECRET_ACCESS_KEY = usr.AWS_Secret__c;
		System.assert(AWS_ACCESS_KEY_ID != '','missing User.AWS_Key');
	}

	public void setBucket(string b) { BUCKET_NAME = b.tolowercase(); }
	public string getBucket() { return BUCKET_NAME; } 
	public void setKey(string b) { key = b; }
	public string getKey() { return key; } 
	
	public void setDateString() { 
		this.dateString = this.formatDateString(System.now()); 		
	}
	public string getDateString(){return dateString;}

	
	// helpers
	public void setBody(string b) { this.body = b; } 
	public void makeRequest(string method, string bucket_in, string key_in, Map<String, String> headers) {
		if (bucket_in != null) setBucket(bucket_in); 
		if (key_in != null ) setKey(key_in);
		if (body != null) setBody(body);
		if (headers != null ) setHeaders(headers);  
		makeRequest( method);		
	}
	public void setHeaders(Map<String, String> h) {headers = h.clone();}
	
	public void makeRequest(string method, string bucket_in, string key_in) {
		if (bucket_in != null) setBucket(bucket_in); 
		if (key_in != null ) setKey(key_in);
		makeRequest( method);		
	}
	/* 
	 * main callout method
	 */
	public void makeRequest(string method) {
		HttpRequest req = new HttpRequest(); 
		
		req.setMethod(method);
		if(method == 'PUT') { 
			if ( ! headers.containsKey('content-type') ) { 
				system.debug('ERROR: missing content-type in PUT request');	return; 
			} 
			system.debug('content-type is >' +headers.get('content-type'));
			req.setHeader('content-type', headers.get('content-type') );
			
			if ( body == null ) { 
				system.debug( 'body must not be null in PUT'); return; 
			}
			req.setBody(body); 
			req.setCompressed(true); // otherwise we hit a limit of 32000
		}
		System.assert(this.BUCKET_NAME != null,'Missing Bucket name :setBucket(name)');
		req.setEndpoint( this.serviceEndPoint + this.BUCKET_NAME +'/' + this.key);
		setDateString();
		req.setHeader('Date',getDateString()); 
		setAuthHeader(req); 	
		if ( ! headers.isEmpty() ) { 
			for(string k:headers.keySet() ) { 
				system.debug('setheader ' + k + ' => ' +headers.get(k) ); 
				req.setHeader(k, headers.get(k) ); 
			}
		}
		//this.res = null;
		Http http = new Http();
		try {
			system.debug(req);
			res = http.send(req);	
			if (debug > 1) {
				system.debug(res.toString());
				//System.debug('STATUS:'+res.getStatus());System.debug('STATUS_CODE:'+res.getStatusCode());
				System.debug('BODY: '+res.getBody());
			}
		} catch(System.CalloutException e) {
			if (res.getStatus()=='OK') { 
				system.debug(res.toString()); // for some reason HEAD ends up here
			} else { 
				System.debug('ERROR: '+ e);
				system.debug(res.toString());
			}
		}
		body = null; // don't reuse this
		headers.clear(); 
	}
	// deliver all results with this method
	public HTTPResponse getResponse() { return res; }
	
	public static testmethod void testDateStr() { 
		AWSConnection t = new AWSConnection(); 
		t.setDateString(); 
		system.debug (t.formatDateString(System.now()));
		system.debug (t.getDateString() );	
		t.setBody('ffdfsfsdf');
	}
	
	/* 
	 * private below here
	 */
	private string formatDateString(DateTime d) {
		String timeFormat = d.formatGmt('EEE, dd MMM yyyy HH:mm:ss') + ' GMT';
		if(debug>3) system.debug(timeFormat);
		return timeFormat; 
	}

	private void setAuthHeader(HTTPRequest req) { 	
		// TODO process the header map into the string array paramater here    vvvvvv
		string buf = make_canonicalBuffer(req.getMethod(),getDateString(),new string[]{}, req.getEndpoint());
		if(debug>2) system.debug ('>'+buf +'<');
		string signature  = make_sig(buf);		
		req.setHeader('authorization','AWS '+AWS_ACCESS_KEY_ID+':'+signature);
	}
		
	/*
	 * construct the buffer used to build the signature
	 */
	private String make_canonicalBuffer(string method, string datestr, string[] aws_headers, string resource) {
		String canonicalBuffer = method + '\n';
		// Add all interesting headers to a list, then sort them.  'Interesting'
		// is defined as Content-MD5, Content-Type, Date, and x-amz-
		// this code ported from the Perl library S3.pm
		
		canonicalBuffer += '\n';
		if ( method == 'PUT' ) { 
			// we already know that content-type is present, add it
			canonicalBuffer += headers.get('content-type') + '\n';
			headers.remove('content-type'); // so we don't add it twice
		} else {
			canonicalBuffer += '\n';
		}
		canonicalBuffer += datestr + '\n';
		
		// Finally, add all the interesting headers (i.e.: all that startwith
		// x-amz- ;-))
		// TODO this headers map must be sorted or we will fail sig match at amazon
		// 
		if ( ! headers.isEmpty() ) { 
			for(string k:headers.keySet() ) {
				// if (k starts with x-amz- then  
				canonicalBuffer += k + ':' + headers.get(k) + '\n';
			}
		}
				
		resource = resource.replace(this.serviceEndPoint , '');
		// don't include the query parameters...
		integer queryIndex = resource.indexOf('?');
		if (queryIndex == -1) {
		    canonicalBuffer += '/' + resource;
		} else {
		    canonicalBuffer += '/' + resource.substring(0, queryIndex);
		}
		
		// ...unless there is an acl or torrent parameter
		if ( Pattern.matches('.*[&?]acl($|=|&).*',resource)) {
		    canonicalBuffer += '?acl';
		} else if (Pattern.matches('.*[&?]torrent($|=|&).*',resource)) {
		    canonicalBuffer += '?torrent';
		}
		return 	canonicalBuffer;
	}
		
	/* 
	 * construct the signature that AWS expects, given the key and cannon string
	 * see http://docs.amazonwebservices.com/AmazonS3/2006-03-01/gsg/authenticating-to-s3.html
	 */
	static testmethod void testMakeSig() { AWSConnection t = new AWSConnection(); 
		string signature  = t.make_sig(
			'GET\n\n\nThu, 31 Jan 2008 21:24:40 GMT\n/12gkzwnp21m82yy5nw02-test-bucket/'
			);
		System.assertEquals('Am6owg7cfiiLFw3r7UxVp/Xkd18=',signature, 'mis match sig');
		
		signature = 'GET\n\n\nFri, 01 Feb 2008 00:59:23 GMT\n/12gkzwnp21m82yy5nw02-test-bucket/';
		System.assertEquals('dsSHD104cF1VqyzOHe7pC9fIMBE=',t.make_sig(signature));
	}
	private string make_sig(string canonicalBuffer) {
		//system.debug(canonicalBuffer);
		String macUrl ;
		String signingKey = EncodingUtil.base64Encode(Blob.valueOf(AWS_SECRET_ACCESS_KEY));
		Blob mac = Crypto.generateMac('HMacSHA1', blob.valueof(canonicalBuffer),blob.valueof( AWS_SECRET_ACCESS_KEY ));	
		macUrl = EncodingUtil.base64Encode(mac);		
		if (debug > 1) system.debug(macUrl);
		return macUrl;
	}	

	/* 
	 * test methods here
	 */
	public static testmethod void test1()  {
		AWSConnection conn = new AWSConnection(); 
		system.debug(conn); 
		conn.setBucket('boo');
		System.assertEquals('boo',conn.getBucket(),'bucket mismatch');
		conn.setKey('foo'); 
		System.assertEquals('foo',conn.getKey(),'Key mismatch');
		conn.makeRequest('GET','bar','fooo'); 
	}
	public static testmethod void test2()  {
		AWSConnection conn = new AWSConnection(); 
		system.debug(conn); 
		conn.setBucket('boo');
		System.assertEquals('boo',conn.getBucket(),'bucket mismatch');
		conn.setKey('foo'); 
		System.assertEquals('foo',conn.getKey(),'Key mismatch');
		conn.setBody('sdfsdf');
		conn.makeRequest('PUT','bar','fooo'); 
	}
	public static testmethod void test3()  {
		AWSConnection conn = new AWSConnection(); 
		system.debug(conn); 
		conn.setBucket('boo');
		System.assertEquals('boo',conn.getBucket(),'bucket mismatch');
		conn.setKey('foo'); 
		conn.formatDateString(system.now());
		System.assertEquals('foo',conn.getKey(),'Key mismatch');
		conn.setBody('sdfsdf');
		conn.makeRequest('PUT','bar','fooo', new Map<String, String>{ 
 			'content-type'=>'text/html', 
 			'x-amz-acl' => 'public-read' } ); 
	}
 
}