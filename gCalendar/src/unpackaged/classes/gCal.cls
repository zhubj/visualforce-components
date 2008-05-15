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
public class gCal {

	transient  XMLDom dom;

	// open or create a session record for this user + calendar
	googSession__c SessionToken; 
	public gCal(string gsessionid) {
		if (gsessionid != null && gsessionid != '') { 
			this.SessionToken = [select id, scope__c, AuthSubSessionToken__c from 
					googSession__c where id = :gsessionid limit 1];
		}
		init(); 
	}
		
	public gCal() { 
		try { this.SessionToken = [select id, scope__c, AuthSubSessionToken__c from 
				googSession__c where ownerid = :UserInfo.getUserId() 
				and scope__c like '%calendar%' limit 1 ];
		} catch( exception e) {} 
		init(); }  
		 
	public void init() {
		googSession__c[] tmp ; //= new googSession__c[]{};
		if (SessionToken==null) {
			SessionToken = new googSession__c();
			SessionToken.ownerId = 	UserInfo.getUserId();
			SessionToken.name = 'Google Calendar for '+userInfo.getUserName();
			insert SessionToken;
		}
		system.assert(SessionToken!=null,' SessionToken is null, could not create token record');
		system.debug( 'SessionToken is '+SessionToken );
	}
	
	public string getCalSession() { 
		return this.SessionToken.AuthSubSessionToken__c;
	}
	
	/* updateSessionToken()
	 * make the update to save this 
	 *  response has a new line at the end, trimed when saved to DB
	 *
	20080329051527.002:Class.gCal.getAuthSubSessionToken: line 29, column 9: Token=CO3G_f-CGBDIlaye-P____8B
	
	20080329051527.002:Class.gCal.getAuthSubSessionToken: line 35, column 9: (Token, CO3G_f-CGBDIlaye-P____8B
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
 			//system.debug ('EXCP '+e); 
 		}
 		
		system.debug('updated '+ SessionToken);
	}
	

	
	private string defaultFeed = 'https://www.google.com/calendar/feeds/default';
	public string getDefaultFeed() { return defaultFeed; }
	
	/* this belongs in the page controller */
	public class calendars  { 
		xmldom.element e; 
		calendars( xmldom.element dd) { e = dd; }
		public string getTitle() { return e.getValue('title'); }	
	} 
	public list<calendars> getowncalendars() { 
		makeRequest( defaultFeed+ '/owncalendars/full');
		return getCalendarsList( getResponse().getBody() );
	}
	
	// take a response string, return a list of calendars marked by entries
	public list<calendars> getCalendarsList( string body ) { 
		dom = new xmldom( body );
		dom.dumpAll(); 
		list<calendars> ret = new list<calendars>{};
		for(xmldom.element e: dom.getElementsByTagName('entry') ) {
			ret.add( new calendars( e) );
		}
		return ret;
	}
	
	public static testMethod void test2() { 
  		gcal  g = new gcal(); 
  		list<event> le = g.getEvents();
	}
	public class event  { 
		xmldom.element e; 
		event( xmldom.element dd) { e = dd; }
		public string getTitle() { return e.getValue('title'); }
		public string getId() { return e.getValue('id'); }	
		public string getStartTime() { return e.getElementByTagName('gd:when').getAttribute('startTime'); }			
	}
	
	public List<event> getEvents() { 
		// use a date range or hit the response size too large...
		makeRequest(	defaultFeed+'/private/full?start-min=2008-01-16T00:00:00&start-max=2008-05-24T23:59:59' );
		return getEvents(getResponse().getBody()); 
	}
	
	public List<event> getEvents(string body) { 
		event [] ret = new event []{};
		dom = new xmldom( body );
		for( xmldom.element e: dom.getElementsByTagName('entry') ) { 
			e.dumpAll();
			system.debug( e.getValue('title') );
			system.debug( e.getValue('title') + ' ' + 
				e.getElementByTagName('when').getAttribute('startTime') );	
			ret.add( new event(e) );
		}		
		return ret; 
	}
	public static testMethod void test2c() { 
  		gcal  g = new gcal(); 
  		system.event ee = new System.Event(
			subject = 'Tennis with Beth',
			description = 'Meet for a quick lesson.',
			ActivityDateTime = system.now(),
			DurationInMinutes = 60
			) ;
		xmldom.element x = g.createEventAtomElement( ee ) ;
		g.getEvents(g.tstString); 
	}		

	
	public final string tstString = '<entry xmlns=\'http://www.w3.org/2005/Atom\' xmlns:gd=\'http://schemas.google.com/g/2005\'>'+
		'<category scheme=\'http://schemas.google.com/g/2005#kind\' term=\'http://schemas.google.com/g/2005#event\'></category>'+
		  '<title type=\'text\'>Tennis with Beth</title>'+
		  '<content type=\'text\'>Meet for a quick lesson.</content>'+
		  '<gd:transparency value=\'http://schemas.google.com/g/2005#event.opaque\'>  </gd:transparency>'+
		  '<gd:eventStatus    value=\'http://schemas.google.com/g/2005#event.confirmed\'>  </gd:eventStatus>'+
		  '<gd:where valueString=\'Rolling Lawn Courts\'></gd:where>'+
		  '<gd:when startTime=\'2006-04-17T15:00:00.000Z\' '+
		    'endTime=\'2006-04-17T17:00:00.000Z\'></gd:when></entry>';
	
	/*
		build this
	<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event'>
	</category>
	  <title type='text'>Tennis with Beth</title>
	  <content type='text'>Meet for a quick lesson.</content>
	  <gd:transparency
	    value='http://schemas.google.com/g/2005#event.opaque'>
	  </gd:transparency>
	  <gd:eventStatus
	    value='http://schemas.google.com/g/2005#event.confirmed'>
	  </gd:eventStatus>
	  <gd:where valueString='Rolling Lawn Courts'></gd:where>
	  <gd:when startTime='2006-04-17T15:00:00.000Z'
	    endTime='2006-04-17T17:00:00.000Z'></gd:when>
	</entry>

	using XmlDom and toXmlString() 
	given an event, construct an xml dom, then tostring it.
	
	TODO create a routine for Task
	*/
	
	public xmldom.element createEventAtomElement(System.Event e) { 
			//xmldom d = new xmldom();
		xmldom.element entry =new xmldom.element('entry'); 
		entry.attributes.put('xmlns','http://www.w3.org/2005/Atom');
		entry.attributes.put('xmlns:gd','http://schemas.google.com/g/2005');
		xmldom.element cat = new xmldom.element('category');
	
		cat.attributes.put('scheme','http://schemas.google.com/g/2005#kind');
		cat.attributes.put('term','http://schemas.google.com/g/2005#event');
		entry.appendChild(cat);
	
		entry.appendChild( createTextNode ( 'title',e.subject) );
		entry.appendChild( createTextNode ( 'content',e.description) );
		// TODO support for recurring events
		
		// construct start and end times
		xmldom.element ewhen = new xmldom.element('gd:when');
		ewhen.attributes.put('startTime',dateTimeToGDataString(e.activityDateTime));
		datetime endtime = e.activityDateTime.addMinutes(e.DurationInMinutes);
		ewhen.attributes.put('endTime',dateTimeToGDataString(endtime));
		entry.appendChild(ewhen); 
		
		return entry;
	}
	public string createEventAtom(System.Event e) { 
		return createEventAtomElement(e).toXmlString();  
	}
	private xmldom.element createTextNode(string name,string value) { 
		xmldom.element ret = new xmldom.element(name);
		ret.attributes.put('type','text');
		ret.nodeValue = value;
		return ret;
	}
	private string dateTimeToGDataString(datetime t) { 
		return string.valueofgmt(t).replace(' ','T') + '.000Z';
	}
	public static testMethod void testCalCreate1() {
		testCalCreate(''); }
	public static void testCalCreate(string id ) { 
		gcal  g = new gcal(id);
		string b  = g.createEventAtom( new System.Event(
			subject = 'Tennis with Beth',
			description = 'Meet for a quick lesson.',
			ActivityDateTime = system.now(),
			DurationInMinutes = 60
			) );
		system.debug (b);
		g.makeRequestMethod('POST',g.getDefaultFeed()+'/private/full', b);
	}
	
	
	/* 
	 * support for GData auth-sub process
	*/ 
	
	/* 
	 * begin the auth sub process to get a perm token, called if we 
	 * have a token but no perm token
	 */
	public string getAuthSubTokenInfo() { 
		makeRequest(	'https://www.google.com/accounts/AuthSubTokenInfo' );
		//		dom = new xmldom( getResponse().getBody() );
		//system.debug(getResponse().getBody());
		return getResponse().getBody();
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
		
		makeRequest('https://www.google.com/accounts/AuthSubSessionToken');

		string response = getResponse().getBody(); 	//	system.debug( response ); 
		
		updateSessionToken(response);		// parse and store to custom object
	
		//system.debug( SessionToken);
        return SessionToken.AuthSubSessionToken__c;
	}
	public PageReference AuthSubRevokeToken() {
		integer r = doAuthSubRevokeToken();
		return null; // stay on same page
	}
	public PageReference AuthSubSessionToken() {
		string s = getAuthSubSessionToken(); 
		//system.debug( s); 
		PageReference pageRef = new PageReference('/'+SessionToken.id);
		// go to SessionToken.id
		pageRef.setRedirect(true);
		return pageRef; 
		 
	}	
	
	public integer doAuthSubRevokeToken () { 		
		if ( this.SessionToken.AuthSubSessionToken__c == null ) 
			return 403; 

		makeRequest( 'https://www.google.com/accounts/AuthSubRevokeToken' );
		//system.debug( res.getBody() );
		if ( res.getStatusCode() != 200 ) {
			// could not revoke	
			if ( res.getStatusCode() == 403 ) // invalid token
				updateSessionToken('');
		} else { 
			// update the session record
			updateSessionToken('');
		}
		return Integer.valueof(res.getStatusCode());
	}
	 
	
	/* 
	 * construct all outgoing HTTP Rest requests here 
	 * makeRequest( url )
	 * makeRequestMethod( method, url, body )  
	 */
	private string gsessionid; 
	transient HttpResponse res = null;
	public  HttpResponse getResponse() { return this.res; }
//	transient Map<String,String> headers = new Map<String, String>{};
	
	public void makeRequest(string url)  { 	makeRequestMethod('GET',url,null); }
	public void makeRequestMethod(string method, string url, string body)  { // leaves result in res instance member	
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
	    req.setHeader('Authorization','AuthSub token=' + this.SessionToken.AuthSubSessionToken__c );
		req.setHeader('Range','bytes=0-100000'); // does not appear to be effective?
	//    req.setCompressed(true); // causes a gack
		
		if (body != null) req.setBody(body);
	//	system.debug(req);
		try {
			Http http = new Http();
			res = http.send(req);
			System.debug('STATUS:'+res.getStatus());
			if ( res.getStatusCode() == 412 ) { // status if no gsession passed in
				this.gsessionid = res.getHeader('X-Redirect-Location').split('=')[1];
				//system.debug( this.gsessionid );
				system.assert( this.gsessionid != null ,' must have a session id') ; 
				makeRequestMethod(method, url, body); // call back again to respond to this redirect
			}
			if (res.getStatusCode() != 200 ) {
				System.debug('STATUS:'+res.getStatus());System.debug('STATUS_CODE:'+res.getStatusCode());
				System.debug('BODY: '+res.getBody());
			}
			
		} catch( System.Exception e) {
			System.debug('ERROR: '+ e);
		}
	}	

/* nothing but test methods all the way down..
*/
	public static testMethod void test1() { 
  		gcal  g = new gcal(); 
  		Test.setCurrentPageReference(new PageReference('gsession'));
  		// Add parameters to page URL
		System.currentPageReference().getParameters().put('token', 'yyyy');
		g.SessionToken.AuthSubSessionToken__c =null;
  		system.debug( g.getAuthSubSessionToken() );
  		calendars[] le =g.getowncalendars();
  		for ( calendars e: le) { 
	  		system.debug(e.getTitle());
  		} 
	}
	public static testMethod void test2a() { 
  		gcal  g = new gcal(); 
  		g.getCalendarsList( g.tstString );
  		calendars[] cle =g.getowncalendars();
  		for ( calendars e: cle) { 
	  		system.debug(e.getTitle());
  		} 
	}
	public static testMethod void test2b() { 
  		gcal  g = new gcal(); 
  		system.event ee = new System.Event(
			subject = 'Tennis with Beth',
			description = 'Meet for a quick lesson.',
			ActivityDateTime = system.now(),
			DurationInMinutes = 60
			) ;
		xmldom.element x = g.createEventAtomElement( ee ) ;
		x.dumpAll();
		event mee = new gcal.event( x );	
		mee.getTitle(); 
		mee.getId(); 
		mee.getStartTime();
		g.AuthSubRevokeToken();
	}	
	public static testMethod void test3() { 
  		string te = ' Token=CO3G_f-CGBDIlaye-P____8B\n';
		gcal  g = new gcal();
		g.updateSessionToken( te);
		system.assert( g.getCalSession() == 'CO3G_f-CGBDIlaye-P____8B',' token not stored ');
		g.updateSessionToken('');
		system.debug( g.getCalSession() );
	}
	public static testMethod void testConstructor() { 
		googSession__c gs = new googSession__c(); 
		insert gs;
		gcal  g = new gcal(gs.id);
		system.debug(g);
		system.assert(g.SessionToken != null);		
		gcal  gg = new gcal('');
		gg.init();
		system.assert(gg.SessionToken != null);	
		
	}	
	public static testMethod void test4() { 
		gcal  g = new gcal(); 
		g.getAuthSubTokenInfo();
	}
	public static testMethod void test5() { 
		gcal  g = new gcal(); 
		g.SessionToken.AuthSubSessionToken__c = null;
		//Test.setCurrentPageReference(new PageReference('gsession'));
  		// Add parameters to page URL
		System.currentPageReference().getParameters().put('token', 'yyyy');
	
		try { g.getAuthSubSessionToken(); } catch(exception e) {}
	}
	public static testMethod void testEventCreate() {
		gcal  g = new gcal(); 
		string b  = g.createEventAtom( new System.Event(
			subject = 'Tennis with Beth',
			description = 'Meet for a quick lesson.',
			ActivityDateTime = system.now(),
			DurationInMinutes = 60
			) );
		system.debug (b);
		g.makeRequestMethod('POST',g.defaultFeed+'/private/full', b);
		
		/* 
		 * the response looks like this
		 * if we want to store the resulting event into the force.com app, we can grab the event link 
		 * and save it into the task/event
		
		20080412015717.876:Class.gCal.makeRequestMethod: line 348, column 17: BODY: 
		<?xml version='1.0' encoding='UTF-8'?><entry xmlns='http://www.w3.org/2005/Atom' 
		xmlns:batch='http://schemas.google.com/gdata/batch' xmlns:gCal='http://schemas.google.com/gCal/2005' 
		xmlns:gd='http://schemas.google.com/g/2005'>
		<id>http://www.google.com/calendar/feeds/default/private/full/8dtll9emdgi9t3qujnhrq1r5vg</id>
		<published>2008-04-12T01:57:18.000Z</published><updated>2008-04-12T01:57:18.000Z</updated>
		<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event'/>
		<title type='text'>Tennis with Beth</title><content type='text'>Meet for a quick lesson.</content>
		<link rel='alternate' type='text/html' 
			href='http://www.google.com/calendar/hosted/salesforce.com/event?eid=OGR0bGw5ZW1kZ2k5dDNxdWpuaHJxMXI1dmcgcmhlc3NAc2FsZXNmb3JjZS5jb20' 
			title='alternate'/>
		<link rel='self' type='application/atom+xml' 
			href='http://www.google.com/calendar/feeds/default/private/full/8dtll9emdgi9t3qujnhrq1r5vg'/>
		<link rel='edit' type='application/atom+xml' 
			href='http://www.google.com/calendar/feeds/default/private/full/8dtll9emdgi9t3qujnhrq1r5vg/63343648638'/>
		<author><name>Ron Hess</name>
		<email>info@salesforce.com</email></author>
		<gd:comments>
		<gd:feedLink href='http://www.google.com/calendar/feeds/default/private/full/8dtll9emdgi9t3qujnhrq1r5vg/comments'/></gd:comments>
		<gd:eventStatus value='http://schemas.google.com/g/2005#event.confirmed'/>
		<gd:visibility value='http://schemas.google.com/g/2005#event.default'/>
		<gd:transparency value='http://schemas.google.com/g/2005#event.opaque'/><gCal:uid value='8dtll9emdgi9t3qujnhrq1r5vg@google.com'/><gCal:sequence value='0'/>
		<gd:when startTime='2008-04-11T18:57:17.000-07:00' endTime='2008-04-11T19:57:17.000-07:00'/>
		<gd:who rel='http://schemas.google.com/g/2005#event.organizer' valueString='Ron Hess' email='rhess@salesforce.com'/>
		<gd:where/>
		</entry>
		
		*/
	}


	
}