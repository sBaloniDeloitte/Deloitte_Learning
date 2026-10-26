public with sharing class XMLConvertor {
    private static Map<String,Object> attributeMap = new Map<String,Object>();
    public XMLConvertor() {
 
    }
 
    //method to initiate recursive parsing of XML stream
    public static Map<String, Object> xmlToMap(String xml){
        //initialzing XML document
        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        //getting the root element and parsing it recursively
        Dom.XMLNode root = doc.getRootElement();
        Object temp = parse(root);
        //map to store parsed data
        Map<String, Object> jsonResult = new Map<String, Object>{root.getName() => temp};
        //result map having data from the XML string as a map
        System.debug('jsonResult=:'+jsonResult);
        return jsonResult;
    }
 
    //method to initiate recursive parsing of XML stream
    public static Map<String, Object> attributeOnly(String xml){
        //initialzing XML document
        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        //getting the root element and parsing it recursively
        Dom.XMLNode root = doc.getRootElement();
        Object temp = parse(root);
        //map to store parsed data
        Map<String, Object> jsonResult = new Map<String, Object>{root.getName() => temp};
        //result map having data from the XML string as a map
        return attributeMap;
    }
   
    //method to recursively parse child nodes from XML document
    private static Object parse(Dom.XMLNode node){
        //map to store data of current XML node
        Map<String, Object> jsonResult = new Map<String, Object>();
        //getting list of child elements
        List<Dom.XMLNode> children = node.getChildElements();
        //if no child elements found, we simply return the text value
        if(children.isEmpty()){
            return node.getText();
        }
        //map to store occurence count of child elements against their names      
        Map<String, Integer> nodeNameCount = new Map<String, Integer>();
        //iterating over child elements and populating the count in map
        for(Dom.XMLNode child : children){
        //System.debug('The parent Value is : '+child.getChildElement('OtpResponse',''));
            String nodeName = child.getName();
            //System.debug('The Attribute Value is : '+child.getAttribute('txn',''));
            if(!nodeNameCount.containsKey(child.getName())){
                nodeNameCount.put(nodeName, 0);
            }
            Integer oldCount = nodeNameCount.get(nodeName);
            nodeNameCount.put(nodeName, oldCount + 1);
 
           
           
        }
        //iterating over child elements and parsing them recursively
        for(Dom.XMLNode child : children) {
            Object temp = parse(child);
            String nodeName = child.getName();
            //checking if this child is an array
            Boolean childIsArray = (nodeNameCount.get(nodeName) > 1);
            //if child is array, save the values as array, else as strings.
            if(childIsArray) {  
                if(jsonResult.get(nodeName) == null){
                    jsonResult.put(nodeName, new List<Object>{ temp });
                }
                else{
                    List<Object> tempList = (List<Object>)jsonResult.get(nodeName);
                    tempList.add(temp);
                    jsonResult.put(nodeName, tempList);
                }
               
            }
            else{
                jsonResult.put(nodeName, temp);
            }
 
            Integer attributeCount = child.getAttributeCount();
           
            if(attributeCount > 0){
                for(Integer index = 0;index<attributeCount;index++){
                    String attributeKey = child.getAttributeKeyAt(index);
                    String attributeValue = child.getAttribute(attributeKey, '');
                    attributeMap.put(attributeKey,attributeValue);
                }
            }
        }
        //result map for current node
        return jsonResult;
    }
}