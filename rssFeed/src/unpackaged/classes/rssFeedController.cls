/* 
 * read from a feed, return a list of feed entry records
 */
public class rssFeedController {
	public Integer entriesCount = 5; // provide a default for this 
	public integer getEntriesCount() { return entriesCount; }
	public void setEntriesCount(integer i) {entriesCount = i;}
	
	public string feedURL;
	public void setFeedURL(String u) { feedURL=u; }
	public String getFeedURL() { return feedURL; }
		
	private String body ; 
	public string getBody() {return body; } 
	public void setBody(String b) { this.body = b; } 
	
	public  FeedEntry[] getfeedcontent() { 

	    HttpRequest req = new HttpRequest();
	    req.setEndpoint(feedURL);
	    req.setMethod('GET');    
	    // avoid getting more than we can process on the callout
	    // max is 32000, more will throw an exception from the server
	    // we could go back for a second range, but this will give ~10 normal blog entries
	    req.setHeader('Range','bytes=0-31000'); 
	    
	    Http h = new Http();
	    HttpResponse res = h.send(req);    	
	    setBody ( res.getBody() );
	    //system.debug( getBody() );
	    XmlStreamReader reader = new XmlStreamReader(body);

		// If you specify it as false, the parser may return text in multiple blocks.
		reader.setCoalescing (true); 
				
		FeedEntry[] feeds = parseFeedEntries(reader);
		//System.debug(feeds.size());
		//for (FeedEntry f : feeds) {		   System.debug(f);	}
		return feeds;
	}
	
	public class Feed { String title, id, modified; }
	public Feed mainFeed; 
	
	FeedEntry[] parseFeedEntries(XmlStreamReader reader) {
     FeedEntry[] entries = new FeedEntry[0];
	 mainFeed = new Feed(); 
     try { 
     	while(reader.hasNext()) {

         if (reader.getEventType() == XmlTag.START_ELEMENT) {
         	string lname = reader.getLocalName();
         	//system.debug(lname); 
         	if ( lname == 'title')  mainFeed.title = getValue(reader); 
          	if ( lname == 'id' ) 	mainFeed.id = getValue(reader); 
  			if ( lname == 'modified' ) 	mainFeed.modified = getValue(reader); 
  			// add more here
  			       	
            if (lname == 'entry' ) { // ATOM style
                FeedEntry e = parseFeedEntry(reader); //parse out single entry from feed
                entries.add(e);                
            } 
            if (lname == 'item' ) {  // RSS 2.0 style
            	system.debug('rss style');
            	FeedEntry e = parseFeedItem(reader);
            	entries.add(e);
            }  
            if (entries.size() >= getEntriesCount()) {
            	return entries; // stop processing if we hit the count
            }
         }
        reader.next();
      }
     } catch (exception parseerror) { 
     	system.debug ( 'parse error ' +parseerror); 
     }
    //system.debug(mainFeed);	system.debug(entries);
	return entries;
   }

	FeedEntry parseFeedItem(XmlStreamReader reader) {
		FeedEntry e = new FeedEntry(); 
     	while(reader.hasNext()) {
	       	System.XmlTag tag = reader.getEventType();
	        string lname = reader.getLocalName();
	        String txt = ''; 
	        try { txt = reader.getText(); } catch (exception ex) {}
			
			system.debug( lname + ' ' +tag + '  ' + txt);
	        if (reader.getEventType() == XmlTag.END_ELEMENT) {
	           if ( lname == 'item' ) break;
	        }
	     	if (reader.getEventType() == XmlTag.START_ELEMENT) {
	
			if (lname == 'title') e.title = getValue(reader);
			if (lname == 'id') e.id = getValue(reader);
			if (lname == 'description') e.summary = getValue(reader);
			if (lname == 'link') e.origlink = getValue(reader);
			if (lname == 'name') e.author = getValue(reader);
			if (lname == 'pubDate') e.created = getValue(reader);
	     	}
     		reader.next();	
     	}
     	return e;
	}

	// Parse through the XML, deterimine the details of the feed entry
    FeedEntry parseFeedEntry(XmlStreamReader reader) {
     FeedEntry e = new FeedEntry();
     //system.debug('parse entry');
     while(reader.hasNext()) {
        System.XmlTag tag = reader.getEventType();
        string lname = reader.getLocalName();
        String txt = ''; 
        try { txt = reader.getText(); } catch (exception ex) {}
		
		system.debug( lname + ' ' +tag + '  ' + txt);
        if (reader.getEventType() == XmlTag.END_ELEMENT) {
           if ( lname == 'entry' ) break;
        }
        if (reader.getEventType() == XmlTag.START_ELEMENT && 
         	lname == 'content' ) { 	
			// ignore content for now, this method is not working consistently
			// we will display the summary 
			// e.content = getUntilEndOfElement(reader,'content');
			 
        } else if (reader.getEventType() == XmlTag.START_ELEMENT) {
	
			if (lname == 'title') e.title = getValue(reader);
			if (lname == 'id') e.id = getValue(reader);
			if (lname == 'summary') e.summary = getValue(reader);
			if (lname == 'origLink') e.origlink = getValue(reader);
			if (lname == 'name') e.author = getValue(reader);
			if (lname == 'created') e.created = getValue(reader);
		} 
        reader.next();
     }
     //system.debug(e);
     return e;
   }

	/* 
	 * NB: unresolved bugs prevent this method from working properly, use summary instead.
	 *
   // special case, we want the raw inner HTML of this element
   string getUntilEndOfElement(XmlStreamReader reader,string endLocalName) {
   	 String value; 
   	 integer jj,ii = Integer.valueof(reader.getlocation().split(': ',3)[2]);
   	 
     while(reader.hasNext()) {
     	//system.debug( 'eol ' + reader.getEventType() + ' ' );
        if (reader.getEventType() == XmlTag.END_ELEMENT && 
         reader.getLocalName() == endLocalName ) {
           break;
        } else if (reader.getEventType() == XmlTag.CHARACTERS) {
           value = reader.getText();
        } else { 
      		// system.debug ( reader.getEventType() ); 
        }
        jj = integer.valueof(reader.getlocation().split(': ',3)[2]);
        reader.next();
     }
     value = getBody().substring( ii-1,jj -1);
     //system.debug('content is '+value);
     return value ;
   }
   */

   /* return the inner text, removing the start and end elements 
   	* thus: <f>bar</f> return bar
   	*/
   	string getValue(XmlStreamReader reader) { String value; 
     while(reader.hasNext()) {
     	//system.debug( 'getValue '+reader.getEventType() );
        if (reader.getEventType() == XmlTag.END_ELEMENT) {
           break;
        } else if (reader.getEventType() == XmlTag.CHARACTERS) {
           value = reader.getText();
        }
        reader.next();
     }
     //system.debug( 'getValue return '+value);
     return value ;
   	}   
   	
   
/* test method and data below here 
 * can't test using callout, must test with static string for feed
 */
  	String testfeed = '<?xml version="1.0" encoding="UTF-8"?>'+
'<feed xmlns="http://purl.org/atom/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:feedburner="http://rssnamespace.org/feedburner/ext/1.0" version="0.3">'+
  '<title>Force.com Blog</title>' +
  '<link rel="alternate" type="text/html" href="http://blog.sforce.com/sforce/" />' +
  '<id>tag:typepad.com,2003:weblog-125619</id>' +
  '<link rel="service.post" type="application/x.atom+xml" href="http://www.typepad.com/t/atom/weblog/blog_id=125619" title="Force.com Blog" />' +
  '<modified>2008-01-23T20:27:30Z</modified>' +
  '<tagline></tagline>' +
  '<generator url="http://www.typepad.com/">TypePad</generator>' +
  '<info type="application/xhtml+xml">' +
  '<div xmlns="http://www.w3.org/1999/xhtml">This is an Atom formatted XML site feed. It is intended to be viewed in a Newsreader or syndicated to another site. Please visit <a href="http://blog.sforce.com/sforce/">Force.com Blog</a> for more info.</div>' +
  '</info>' +
  '<entry>' +
    '<title>Tour de Force Global Kickoff - it\'s a wrap!</title>' +
    '<link rel="alternate" type="text/html" href="http://feeds.feedburner.com/~r/SforceBlog/~3/221839184/tour-de-force-g.html" />' +
    '<link rel="service.edit" type="application/x.atom+xml" href="http://www.typepad.com/t/atom/weblog/blog_id=125619/entry_id=44564390" title="Tour de Force Global Kickoff - it\'s a wrap!" />' +
    '<id>tag:typepad.com,2003:post-44564390</id>' +
    '<issued>2008-01-23T12:27:30-08:00</issued>' +
    '<modified>2008-01-23T20:27:30Z</modified>' +
    '<created>2008-01-23T20:27:30Z</created>' +
    '<summary>Thank you to everyone that joined us last Thursday in San Francisco as we kicked off Tour de Force - we\'re delighted that you were able help us launch the Tour de Force roadshow to unleash the Force.com platform around...</summary>' +
    '<author><name>Mark Trang</name></author>' +
    '<content type="application/xhtml+xml" xml:lang="en-US" xml:base="http://blog.sforce.com/sforce/"><div xmlns="http://www.w3.org/1999/xhtml">'+
	'<p>Thank you to everyone that joined us last Thursday in San Francisco as we kicked off Tour de Force - </p></div></content>'+
	'<feedburner:origLink>http://blog.sforce.com/sforce/2008/01/tour-de-force-g.html</feedburner:origLink></entry></feed>';
	
	
	public static testMethod void t1() { 
  	 rssFeedController rss = new rssFeedController();
  	 rss.setFeedURL('');
  	 string s = rss.getFeedURL();
  	 rss.setEntriesCount(2);
  	 Integer rr = rss.getEntriesCount();
  	 rss.setBody( rss.testfeed ) ;
     XmlStreamReader reader = new XMLstreamreader(rss.testfeed);
     
     FeedEntry[] feeds = rss.parseFeedEntries(reader);
     System.debug(feeds.size());
     for (FeedEntry f : feeds) {
       System.debug(f);
     }	
  	}
	
	// another rss type looks like this
	string feed2test = '<?xml version="1.0" encoding="UTF-8"?>'+
'<rss version="2.0"><channel><title>'+
		'<![CDATA[Latest Listings]]>' +
'</title><link><![CDATA[http://www.salesforce.com/appexchange/]]></link>' +
'<description><![CDATA[Applications in the All Applications category]]></description><language>en-us</language>'+
'<item><title><![CDATA[Absolute Automation: Email to Case]]></title>'+
'<description><![CDATA[Emails going to your support email address automatically create cases in Salesforce.  Emails with an active case number in the subject are automatically logged to the correct case.]]></description>' +
'<link><![CDATA[http://www.salesforce.com/appexchange/detail_overview.jsp?id=a0330000004Zs39AAC]]></link>'+
'<category><![CDATA[Application Integration & Mashups]]></category>' +
'<pubDate><![CDATA[Wed, 30 Jan 2008 12:00:00 GMT]]></pubDate></item></channel></rss>';
                            
     
	public static testMethod void t2() {                
	 rssFeedController rss = new rssFeedController();
  	 rss.setFeedURL('');
  	 string s = rss.getFeedURL();
  	 rss.setEntriesCount(2);
  	 Integer rr = rss.getEntriesCount();
  	 rss.setBody( rss.testfeed ) ;
     XmlStreamReader reader = new XMLstreamreader(rss.feed2test);
     
     FeedEntry[] feeds = rss.parseFeedEntries(reader);
     System.debug(feeds.size());
     for (FeedEntry f : feeds) {
       System.debug(f);
     }	     
	}            
}