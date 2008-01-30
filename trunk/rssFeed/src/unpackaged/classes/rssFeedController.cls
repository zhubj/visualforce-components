/* 
 * read from a feed, return a list of feed entry records
 */
public class rssFeedController {
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
	    // max is 32000
	    req.setHeader('Range','bytes=0-31000'); 
	    
	    Http h = new Http();
	    HttpResponse res = h.send(req);    	
	    setBody ( res.getBody() );
	    
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
  			       	
            if ('entry' == lname ) {
                FeedEntry e = parseFeedEntry(reader); //parse out single entry from feed
                entries.add(e);
            }
         }
        reader.next();
      }
     } catch (exception parseerror) { 
     	system.debug ( parseerror); 
     }
     system.debug(mainFeed);
    return entries;
   }


	// Parse through the XML, deterimine the details of the feed entry
   FeedEntry parseFeedEntry(XmlStreamReader reader) {
     FeedEntry e = new FeedEntry();
     
     while(reader.hasNext()) {
        System.XmlTag tag = reader.getEventType();
        string lname = reader.getLocalName();
        String txt = ''; 
        try { txt = reader.getText(); } catch (exception ex) {}
		
		//system.debug( lname + ' ' +tag + '  ' + txt);
        if (reader.getEventType() == XmlTag.END_ELEMENT) {
           if ( lname == 'entry' ) break;
        }
        if (reader.getEventType() == XmlTag.START_ELEMENT && 
         	lname == 'content' ) { 	
			e.content = getUntilEndOfElement(reader,'content');
			 
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
     system.debug(e);
     return e;
   }

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

   /* return the inner text, removing the start and end elements 
   	* <f>bar</f> return bar
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
   
   	// not used currently
	public Integer entriesCount =4; // default this 
	public integer getEntriesCount() { return entriesCount; }
	public void setEntriesCount(integer i) {entriesCount = i;}
	
   
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
}