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

Extension class for collecting a google auth sub session token for 
 calendar or sheets
 
 TODO test coverage, refactor makeRequest to useragent
 
*/
public class gAuthSub {
	// open or create a session record for this user + scope
	// pull from the database if it exists, or create one that is empty
	googSession__c SessionToken; 
	public gAuthSub( apexpages.standardcontroller c) { 
		id gsid = c.getRecord().id;
		this.SessionToken = [select id, scope__c, AuthSubSessionToken__c from googSession__c where id = :gsid limit 1 ];
		ua = new useragent( getSessionToken() );	 	
	}
	useragent ua;
	
	public string getSessionToken() { 
		return this.SessionToken.AuthSubSessionToken__c;
	}
	
	public PageReference AuthSubSessionToken() {
		string s = getAuthSubSessionToken(); 
		//system.debug( s); 
		return null; 
	}	
	
	public pageReference AuthSubRevokeToken () { 
		pagereference p = null; 
		integer ret = doAuthSubRevokeToken();
		// system.debug( 'doAuthSubRevokeToken '+ret);
		return p;
	}
	string tinfo = '';
	public string getTokenInfo() { 
		return tinfo;
	}
	public pageReference AuthSubTokenInfo() { 
		tinfo = getAuthSubTokenInfo(); 
		return null;
	}
	public pageReference GoToGsession () { 
		PageReference p = Page.gsession;
		p.getParameters().put('id',SessionToken.id);
		p.getParameters().put('feed','https%3A%2F%2Fwww.google.com%2Fcalendar%2Ffeeds%2F');
		p.setRedirect(true); 
		return p;
	} 
	
	public integer doAuthSubRevokeToken () { 		
		if ( this.SessionToken.AuthSubSessionToken__c == null ) 
			return 403; 

		ua.get( 'https://www.google.com/accounts/AuthSubRevokeToken' );
		//system.debug( res.getBody() );
		if ( ua.getStatusCode() != 200 ) {
			// could not revoke	
			if ( ua.getStatusCode() == 403 ) // invalid token
				updateSessionToken('');
		} else { 
			// update the session record
			updateSessionToken('');
		}
		return Integer.valueof(ua.getStatusCode());
	}	
	
	public string getAuthSubTokenInfo() { 
		ua.get(	'https://www.google.com/accounts/AuthSubTokenInfo' );
		//		dom = new xmldom( getResponse().getBody() );
		system.debug(ua.getResponse().getBody());
		return ua.getResponse().getBody();
	}
	
	public string getAuthSubSessionToken() { 
		system.assert( this.SessionToken.AuthSubSessionToken__c == null , 
			'oops this auth is already set');
		system.debug( System.currentPageReference().getParameters() );
		system.assert( System.currentPageReference().getParameters().get('token') != null,
			'must have a single use token from google');

		// call with the temporary token in the auth paramater
		this.SessionToken.AuthSubSessionToken__c = 
			System.currentPageReference().getParameters().get('token');
		system.debug( this.SessionToken.AuthSubSessionToken__c ); 
		
		ua.get('https://www.google.com/accounts/AuthSubSessionToken');

		string response = ua.getResponse().getBody(); 		system.debug( response ); 
		
		updateSessionToken(response);		// parse and store to custom object
	
		system.debug( SessionToken);
        return SessionToken.AuthSubSessionToken__c;
	}
	
	/* updateSessionToken()
	 * make the update to save this 
	 *  response has a new line at the end, trimed when saved to DB
	 *
	20080329051527.002:Class.SubSessionToken: line 29, column 9: Token=CO3G_f-CGBDIlaye-P____8B
	
	20080329051527.002:Class.SubSessionToken: line 35, column 9: (Token, CO3G_f-CGBDIlaye-P____8B
	)
	*/	
	public void updateSessionToken(string body) { 
		string[] tok = body.split('=');
		if (tok.size()==2) { 
			system.debug('store token '+tok[1]);
			SessionToken.AuthSubSessionToken__c = tok[1];
		} else { 
			// passed empty string, clear out the token
			SessionToken.AuthSubSessionToken__c = null;
		}
 		try { 
 			system.debug('going to update '+ SessionToken);
 			update 	SessionToken;
 		} catch(Exception e) { 
 			system.debug ('EXCP '+e); 
 		}
 		
		system.debug('updated '+ SessionToken);
	}
	
	/* simple test methods begin here */
	
	public static testMethod void test4() {
		googSession__c gs = [select id from googSession__c limit 1];
		system.assert(gs != null);
		ApexPages.StandardController gsc  = new ApexPages.StandardController( gs);
		gAuthSub  g = new gAuthSub( gsc ); 
		g.getAuthSubTokenInfo();
	}
	
	public static testMethod void test5() {
		googSession__c gs = [select id from googSession__c limit 1];
		system.assert(gs != null);
		ApexPages.StandardController gsc  = new ApexPages.StandardController( gs);
		gAuthSub  g = new gAuthSub( gsc ); 
		g.SessionToken.AuthSubSessionToken__c = null;
		System.currentPageReference().getParameters().put('token', 'yyyy');
		g.updateSessionToken('');
		g.AuthSubSessionToken();

	}
	public static testMethod void test6() {
		googSession__c gs = [select id from googSession__c limit 1];
		system.assert(gs != null);
		ApexPages.StandardController gsc  = new ApexPages.StandardController( gs);
		gAuthSub  g = new gAuthSub( gsc ); 
		g.AuthSubTokenInfo();
	}

	public static testMethod void test7() {
		googSession__c gs = [select id from googSession__c limit 1];
		system.assert(gs != null);
		ApexPages.StandardController gsc  = new ApexPages.StandardController( gs);
		gAuthSub  g = new gAuthSub( gsc ); 
		g.GoToGsession();
		g.doAuthSubRevokeToken();
	}
	public static testMethod void test8() {
		googSession__c gs = [select id from googSession__c limit 1];
		system.assert(gs != null);
		ApexPages.StandardController gsc  = new ApexPages.StandardController( gs);
		gAuthSub  g = new gAuthSub( gsc ); 
		g.getTokenInfo();
	}

}