public class MVCFlexController {
        
        private Boolean show = false;
        private List<Contact> contacts = new List<Contact>();
        
        public PageReference getData() {
                show = true;
                return null;
        }
        public Boolean getShow() {
                return show;
        }
        public List<Contact> getContacts() {
                if (contacts.size() == 0 && show == true) {
                        contacts = [Select Id, FirstName, LastName, Email From Contact Limit 10];
                }
                return contacts;
        } 
}