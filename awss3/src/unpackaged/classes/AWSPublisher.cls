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
 * take a document specified in the published page record and 
 * send the bits to Amazon S3 using the AWSConnection class
 *
 * this class is written to act as a simple Visualforce page custom controller 
 * extension
 *
 */
public class AWSPublisher {	
	// The extension constructor initializes the private member
	// variable  by using the getRecord method from the standard
	// controller.
	public AWSPublisher(ApexPages.StandardController stdController) {
		this.page = (Published_Page__c)stdController.getRecord();
		page = [select name,active__c,bucket__c,Source_Page__c, key__c from Published_Page__c where id=:this.page.id limit 1];
		system.debug(page);
	}
	
	public String getPageBody() { 
		if ( pageBody != null )  
			return pageBody; 
		
		// Pass in the endpoint to be used using the string url
		PageReference pageRef = new PageReference( getVisualforcePageName() );
		system.assert(pageRef != null); 
		
		// run the requested page thru the visualforce page generator now
		pageBody = pageRef.getContent();
		
		system.assert(pageBody != null && pageBody != '');
		return pageBody;
	}
 
	public  PageReference doPublish() {	// publish the page to S3 at the bucket/key location
		AWSConnection conn = new AWSConnection(); 
		conn.setBody( getPageBody() );
 		conn.makeRequest('PUT', getBucket(), getKey(), 
 			new Map<String, String>{
 				'content-type'=>'text/html', 
 				'x-amz-acl' => 'public-read' } );
		system.debug(conn.getResponse().toString());
		return null; 
	}
	
	public PageReference deletePublishedPage() { // remove this page from S3
		AWSConnection conn = new AWSConnection(); 
		conn.makeRequest('DELETE', getBucket(), getKey() );
 		system.debug(conn.getResponse().toString());
 		return null;
	}
	
	public pagereference getSubjectURL() { 	
		PageReference pageRef = new PageReference('/'+page.id);
		pageRef.setRedirect(true);
		return pageRef ;
	}
	public string getBucket () { return page.Bucket__c; } 
	public string getKey () {
		string key = page.Key__c;
		if ( key.startsWith('/') ) 
			key = key.substring(1);
		return key;	
	}
	public string getVisualforcePageName () {
		return page.Source_Page__c;	
	}
	public  integer getPageBodyLength() { 
		return getPageBody().length();
	}
		
	public static testmethod void test1() {
		// TODO 
	}
	
	private string pageBody = null ; 
	private Published_Page__c page;
}