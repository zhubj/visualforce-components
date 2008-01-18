/* implements some or all of
 * http://code.google.com/apis/chart/
 */
public class gChart {
    /* 
     * Extended Google Charting Data Encode
     * 
     *  AA = 0, AZ = 25, Aa = 26, Az = 51, A0 = 52, A9 = 61, A- = 62, A. = 63
     *  BA = 64, BZ = 89, Ba = 90, Bz = 115, B0 = 116, B9 = 125, B- = 126, B. = 127
     *  .A = 4032, .Z = 4057, .a = 4058, .z = 4083, .0 = 4084, .9 = 4093, .- = 4094, .. = 4095.
     *  Specify a missing value with two underscore (__) characters.
     *   If you have more than one set of data, separate each set with a comma (,).
     */ 
    public static String extEncoding = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-.';      
        // 
        // encode a single value using extended encode, will normalize value passed in  
        // 
    public string getEncodeSingleValue(Long val, Long max) {
        String encValue = '__';
        Integer currentValue = normalizeValue( val, max );
        if ( currentValue >= 0 ) {
            Integer upper = currentValue / 64;
            Integer remdr = Math.mod(currentValue,64);
            encValue = extEncoding.substring(upper,upper+1) + extEncoding.substring(remdr,remdr+1);
        } 
        return encValue; 
    }
   
    public              gChart() {}     // constructor
    public String       getChartURL() { return 'http://chart.apis.google.com/chart?'; }

    // list of series to plot, each series is one set of data with it's own labels       
    public List<gChartSeries> data; 
    public void setData(List<gChartSeries>  d) { data =d;} 
    public void setData( gChartSeries  d) { // allow a singleton to be set
        if (data==null) 
                data = new List<gChartSeries>();
        data.add(d);
    } 
    public List<gChartSeries> getData(){ return data; }
        
    public String options='';
    public void setOptions(String o) { options =o;} 
    public string getOptions(){ return options; }

        public Integer maxValue; // max of any value in every series
    
    // spread the values into the set 0-4095

    public Integer normalizeValue(Long value, Long maxValue) { 
        Integer ret = Integer.valueof( string.valueof( Math.roundToLong( (value * 4095.0)  / maxValue ) ) );
        return ret;
    }
    // encodes the first element in the array of data (for now)   
    public string getEncodedData() {
            if ( data!=null && data.size()>0) {
                    gChartSeries d = data[0]; 
                    return encodeData(d);
            } else { 
                    return 's:hW';
            }
    }
    
    // encode the values found in a signle series, will normalize values in this data list
    public string encodeData(gchartseries d) {
            List <Long> values = d.getValues(); 
            String ret; 
            // find largest value, 
            // TODO determine this from a survey of all data series, not just this list
            Long max =      maxListValue(values);
            String chartData = 'e:'; // specify extended encode values
            for (Integer i = 0; i < values.size(); i++) {
                    chartData = chartData + getEncodeSingleValue(values[i],max);
            }               
            return chartData;
    }
    

           
    // Chart Size and Type, setters and getters with defaults
    public string defaultSize = '300x100';
    public String getChartSize() { return 'chs='+defaultSize; } 
    public void setChartSize(string s) {
        /* TODO : should assert that this is a valid size, validate against a patern nnnxnnn */
        defaultSize = s; 
    }

    public String getChartTypeEncode() {
        if (chartType=='pie') return 'cht=p';
        if (chartType=='pie3') return 'cht=p3';
        if (chartType=='line') return 'cht=lc';
        // TODO add more chart types supported here
        // default  
        return 'cht=p3';
    }

    public string       chartType; 
    public String       getCharttype() {  return chartType; }
    public void         setChartType(string typein) { this.chartType = typein; } 
                
    /* 
     * simple Encoding can also be used
     */
    String simpleEncoding = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    public String simpleEncode ( List<Integer> values, Integer maxValue) {
        String chartData = 's:';
        for (Integer i = 0; i < values.size(); i++) {
            Integer currentValue = values[i];
            if ( currentValue >= 0 ) {
                Integer w = Math.round( (simpleEncoding.length()-1) * currentValue / maxValue );
                chartData = chartData + simpleEncoding.substring(w,w+1);
                
            } else {
                chartData = chartData + '_';
            }
        }
        return chartData;
    }
        
    
    /*
     * find the largest value in this list, used to spread the 
     * values across the available charting surface (0-4095)
     */
    public Long maxListValue(List<Long> values) { 
        Long ret = 0; 
        for (Integer i = 0; i < values.size(); i++) { 
                if (values[i]>ret) { ret = values[i];}
        }
        return ret;
    }
    
    /*
    Build Labels string in one of these formats
    use data found in each series, combine this into one chx1 string
    example:
    
    chxl=
        <axis index>:|<label 1>|<label n>|
        ...
        <axis index>:|<label 1>|<label n>
        The index parameter specifies the index of the axis to which the labels apply.
        */
    public string getEncodedLabels() {
        // TODO fix me
        return 'chl=March%2006|November%2007'; // sample only
    }
        
}