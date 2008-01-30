public class FeedEntry {
 public String content;
 public string id;
 public string author; 
 public string summary;
 public string title;
 public string origLink; 
 public string created; 
 
 public string getDate() { return created; } // TODO format this
 public string getSummary() { return summary; } 
 public string getTitle() { return title; } 
 public string getHref() { return origLink; }	
 public string getAuthor() { return author; }	
}