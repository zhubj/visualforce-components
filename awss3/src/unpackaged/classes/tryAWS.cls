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
public class tryAWS {
 // to test AWS, run this in the execute anony window
 // tryaws  t = new tryaws(); t.t1();
 
 public void t1() { 
 	AWSConnection conn = new AWSConnection();
	string bkt = 'your-key-lower-case-test-bucket';
	
 	// list bucket
 	conn.makeRequest('GET', bkt,'');
 	system.debug(conn.getResponse().getBody());
	ok(conn);

  	// put test file	
 	conn.setBody('bar gac \nwaz');
 	conn.makeRequest('PUT', bkt,'test-key' , 
 		new Map<String, String>{ 'content-type'=>'text/plain'}	 );
	ok(conn);
	
	
	// check exists 
	conn.makeRequest('HEAD',bkt, 'test-key');
	ok(conn);
	 
 	// list ACL
 	conn.makeRequest('GET', bkt,'test-key?acl');
 	system.debug(conn.getResponse().getBody());
 	ok(conn);
 		
 	// put again, but make it public and HTML 
 	// set header { 'x-amz-acl' => 'public-read' }
 	conn.setBody('<html><h1>bar gac waz</h1></html>');
 	conn.makeRequest('PUT', bkt,'test-key-public-html', 
 		new Map<String, String>{ 
 			'content-type'=>'text/html', 
 			'x-amz-acl' => 'public-read' } );
 	ok(conn);
 	
 	// get contents 
 	conn.makeRequest('GET', bkt,'test-key-public-html');
 	ok(conn);
 	system.debug(conn.getResponse().getBody());
 	  	
 	// delete a key (file)
 	conn.makeRequest('DELETE', bkt,'test-key');
 	System.assertEquals(204,conn.getResponse().getStatusCode());
 	
 	// make sure it was deleted 
 	conn.makeRequest('GET', bkt,'test-key');
 	System.assertEquals(404,conn.getResponse().getStatusCode());
 	
 	// list all buckets
 	
 	// parse responses
 	
 }
 
 public void ok(AWSConnection conn) { 
 	string s = conn.getResponse().getBody(); 
 	if (s==null) s= 'null';
 	System.assertEquals(200,conn.getResponse().getStatusCode(),s);
 }
}