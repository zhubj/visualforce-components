public class oppExt {
  private  Account acc;
  public oppExt(ApexPages.StandardController stdController) {
    if (stdController != null ) {
      this.acc = (Account)stdController.getSubject();
    } 
  } 
    
  private List<Opportunity> opps; 
  private List<Opportunity> getOpps() { 
    if (opps == null) { 
      opps = [select id,amount,closedate  
	      from opportunity where accountid = :this.acc.id order by CloseDate];
    }
    return opps;	
  }
  
  public List<Long> getChartData() {
    List<Long> retArray = new List<Long>();
    for (Opportunity obj : getOpps() ) {
      retArray.add( math.roundToLong( Double.valueof( string.valueof(obj.amount) ) ) );
    }
    system.debug(retArray);
    return retArray; 
  } 

  public gChartSeries[] getData() { 
    gChartSeries g = new gChartSeries( getChartData() ); 
    g.setTitle('Account Opportunities'); 
    return new gChartSeries[]{g};		
  }
 	
}