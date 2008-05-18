/* 
 * various routines to transform force.com objects , 
 * like event to gdata atoms, 
 * aka: xml strings 
 * TODO create a routine for Task
 */
public class GData {
	/*
		build this
	<entry xmlns='http://www.w3.org/2005/Atom' xmlns:gd='http://schemas.google.com/g/2005'>
	<category scheme='http://schemas.google.com/g/2005#kind' term='http://schemas.google.com/g/2005#event'>
	</category><title type='text'>Tennis with Beth</title>
	  <content type='text'>Meet for a quick lesson.</content>
	  <gd:transparency value='http://schemas.google.com/g/2005#event.opaque'>
	  </gd:transparency>
	  <gd:eventStatus value='http://schemas.google.com/g/2005#event.confirmed'>
	  </gd:eventStatus>
	  <gd:where valueString='Rolling Lawn Courts'></gd:where>
	  <gd:when startTime='2006-04-17T15:00:00.000Z'
	    endTime='2006-04-17T17:00:00.000Z'></gd:when>
	</entry>

	using XmlDom and toXmlString() 
	
	given an event, construct an xml dom, then to-string it.
	NB: not efficient in memory use or speed, strcat would be faster.
	
	*/
	public static xmldom.element createEventAtomXml(System.Event e) { 
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
	
	public static string createEventAtom(System.Event e) {
		return createEventAtomXml(e).toXmlString();
	} 
	private static xmldom.element createTextNode(string name,string value) { 
		xmldom.element ret = new xmldom.element(name);
		ret.attributes.put('type','text');
		ret.nodeValue = value;
		return ret;
	} 
	private static string dateTimeToGDataString(datetime t) { 
		return string.valueofgmt(t).replace(' ','T') + '.000Z';
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

	// TODO test methods
	public static testMethod void testCalCreate1() {
		testCalCreate(''); }
	public static void testCalCreate(string id ) { 
		string b  = gdata.createEventAtom( new System.Event(
			subject = 'Tennis with Beth',
			description = 'Meet for a quick lesson.',
			ActivityDateTime = system.now(),
			DurationInMinutes = 60
			) );
		system.debug (b);
	}
	 
}