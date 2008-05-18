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

This class currently does not have proper code coverage -- TODO

*/ 

public class UserAgent {

	public transient HttpResponse response_v = null;
	public string authSubToken = null;
	public string gsessionid; 
	transient  XMLDom dom = null;
	
	// default some stuff for the user agent, for gdata
	public UserAgent(string tok) { authSubToken = tok;	}
	public HttpResponse get(string url) { return request('GET',url,null);}
	public HttpResponse getResponse() {	return response_v;	}
	public integer getStatusCode() { return response_v.getStatusCode();}
	public string getBody() {		return response_v.getBody();	}
	public XmlDom getResponseDom() { 
		if ( dom!= null ) return dom;
		dom = new xmldom( response_v.getBody() ); 
		return dom;
	}
	public HttpResponse request(string method, string url) { 
		return request( method,  url, null); 
	}
	public HttpResponse request(string method, string url, string body)  { 
		HttpRequest req = new HttpRequest();   
		
		req.setEndpoint(url); 
	   	if ( this.gsessionid!=null ) {  // gcal wants this
	    	if ( url.contains('?') ) {
	    		req.setEndpoint(url + '&gsessionid=' + this.gsessionid );
	    	} else {
	    		req.setEndpoint(url + '?gsessionid=' + this.gsessionid );
	    	}
	   	}
	   	if ( method.tolowerCase() =='delete' ) {
	   		req.setMethod('POST');
	   		req.setHeader('X-HTTP-Method-Override','DELETE');	
	   	} else { 
	    	req.setMethod(method);
	   	} 
	    req.setHeader('content-type', 'application/atom+xml' );
	    req.setHeader('X-If-No-Redirect', '1' );
	    req.setHeader('Authorization','AuthSub token=' + authSubToken );
	//	req.setHeader('Range','bytes=0-100000'); // does not appear to be effective?
	//  req.setCompressed(true); // causes a gack
		
		if (body != null) req.setBody(body);
	//	system.debug(req);
		try {
			Http http = new Http();
			response_v = http.send(req);
			System.debug('STATUS:'+response_v.getStatus());
			if ( response_v.getStatusCode() == 412 ) { // status if no gsession passed in
				this.gsessionid = response_v.getHeader('X-Redirect-Location').split('gsessionid=')[1];
				response_v = request(method, url, body); // call back again to respond to this redirect
			}
/*			if (response_v.getStatusCode() != 200 ) {
				System.debug('STATUS:'+response_v.getStatus());
				System.debug('STATUS_CODE:'+response_v.getStatusCode());
				System.debug('BODY: '+response_v.getBody());
			}*/
			
		} catch( System.Exception e) {
			System.debug('ERROR: '+ e);
		}
		return response_v;
	}

	public static testMethod void test2() { 
  		useragent ua = new useragent('fff');
  		ua.gsessionid = 'somesess';
  		ua.get('http://google.com?f=e');
	}
	public static testMethod void test2a() { 
  		useragent ua = new useragent('fff');
  		ua.gsessionid = 'somesess';
  		ua.get('http://google.com');
	}
	public static testMethod void test3() { 
  		useragent ua = new useragent('fff');
  		ua.get('http://google');
	}	
 	public static testMethod void test4() { 
  		useragent ua = new useragent('fff'); 		
  		ua.request('DELETE','http://sdfsdfj.sss');
 	}
 	public static testMethod void test5() { 
  		useragent ua = new useragent('fff');
 		ua.request('POST','http://sdfsdfj.sss','body');
	}
}