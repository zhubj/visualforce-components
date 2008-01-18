public class gChartSeries {
	// a series is one set of values to plot
	// TODO add labels to the series object
	// TODO Y labels also
	public List<Long> values;
	public List<Long> getValues() { 
		return values; 
	}
	public void setValues(List<Long> vin) {
		this.values = vin;
	}
	public gChartSeries() { }
	public gChartSeries(List<Long> vin) { 
		setValues(vin);	
	}
	public String title; 
	public void setTitle(String t) { title = t;} 
	public String getTitle() { return title; } 
	
	List<String> xlabels=null;
    public void setXLabels(String[] ls) { xlabels = ls; } 
    public string[] getXLabels() { return xlabels; } 

    List<String> ylabels=null;
    public void setYLabels(String[] ls) { ylabels = ls; } 
    public string[] getYLabels() { return ylabels; } 

}