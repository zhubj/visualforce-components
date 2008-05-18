public class pubCalCon {

    /* copy events from a candidate into a google Calendar */

    SFDC_Candidate__c obj;
    public pubCalCon(ApexPages.StandardController controller) {
        this.obj= (SFDC_Candidate__c)controller.getRecord();    
        if ( System.currentPageReference().getParameters().get('sid') != null ) 
            setcalendar( System.currentPageReference().getParameters().get('sid'));
    }
    
    String calendar = '';
     
    gcal g =null;

    // remove listed events from google
    private void deleteExistingCalendarEvents() {
        for (Event e:this.obj.Events) {
            if (e.Goog_Edit_Link__c == null ) { continue; }
            string editLink = e.Goog_Edit_Link__c.replace('http','https');
            g.makeRequestMethod('DELETE',editLink,'');      
        }
        for (Event e:this.obj.Events) {
            e.Goog_Edit_Link__c = null;
            e.GoogleEventId__c = null;
            e.Goog_Alternate_Link__c = null;
        }       
    }   
    
    // Action method from page
    public PageReference deleteEvents() {
        if (g==null) g = new gcal( this.calendar ); 
        deleteExistingCalendarEvents();
        update this.obj.Events;
        return thisCandidate(); 
    }
    
    public PageReference publish() { //publish to the current calendar
        if (g==null) g = new gcal( this.calendar ); 
        deleteExistingCalendarEvents();
        
        for (Event e:this.obj.Events) {
            // check to see if this event already has an edit link
            if (e.Goog_Edit_Link__c != null ) { continue; }
            string b  = gdata.createEventAtom(e);

            g.makeRequestMethod('POST',g.getDefaultFeed()+'/private/full', b);

            xmldom d = new xmldom( g.getResponse().getBody() );
            for (xmldom.element el : d.getElementsByTagName('link') ) {
                if (el.getAttribute('rel') == 'edit') {
                    string href = el.getAttribute('href');
                    e.Goog_Edit_Link__c = href;  // used to delete
                }
                if (el.getAttribute('rel') == 'alternate') {
                    string href = el.getAttribute('href');
                    e.Goog_Alternate_Link__c = href; // used to view
                }   
            }
            e.GoogleEventId__c = d.getElementByTagName('id').nodeValue; // for reference
            
        }
        system.debug(this.obj.events);
        update this.obj.events; // to avoid duplicates, store edit link, used to delete

        return thisCandidate(); 
    }
    private pageReference thisCandidate() { 
        PageReference pageRef = new PageReference('/'+ this.obj.id );
        pageRef.setRedirect(true);
        return pageRef; 
    }
    public string getCalSession() { 
        if (g==null) return '';
        return g.getCalSession();
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        for(googSession__c c: [select id,name from 
                    googSession__c where ownerid = :UserInfo.getUserId() 
                    and scope__c like '%calendar%'  ]) {
            selectoption so = new selectoption( String.valueof(c.id).substring(0,15), c.name);
            system.debug(so);
            options.add(so);        
        }
        return options;
    }
    public String getcalendar() {
        return calendar;
    }
    public void setcalendar(String calendar) {
        this.calendar = calendar;
    }
    
    
}