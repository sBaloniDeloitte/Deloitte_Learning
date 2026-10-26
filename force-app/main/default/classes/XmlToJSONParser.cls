public class XmlToJSONParser {
    public static String rootElementName;
    public static String XMLToJSON(String xml) {
        Dom.Document doc = new Dom.Document();
        doc.load(xml);
        
        Dom.XMLNode root = doc.getRootElement();
        doc = null;
        xml = null;

        return XmlToJSONParser.parse(root, false);
    }

    public static String parse(Dom.XMLNode node, Boolean isChild){
        String json = '';
        Boolean isArray = false;
        if(rootElementName == null) {
            rootElementName = node.getName();
        }

        if(node.getNodeType() == Dom.XmlNodeType.ELEMENT){
            Map<String, List<String>> MapOfJSON = new Map<String, List<String>>();
            List<String> listOfJSON = new List<String>();

            for(Dom.XMLNode child : node.getChildElements()){
                String tmp = parse(child, true);
                if(tmp != '') {
                    if(!MapOfJSON.containsKey(child.getName())){

                        MapOfJSON.put(child.getName(), new List<String>());
                    }
                    MapOfJSON.get(child.getName()).add(tmp);
                }
            }

            for(String key : MapOfJSON.keySet()){
                if(MapOfJSON.get(key).size() >1){
                    // if(isChild) {
                    //     listOfJSON.add('[' + String.join(MapOfJSON.get(key), ', ') + ']');
                    // }
                    // else {
                        listOfJSON.add('"' + key + '": [' + String.join(MapOfJSON.get(key), ', ') + ']');
                    // }
                    isArray = true;
                }
                else { 
                    listOfJSON.add('"' + key + '": ' + MapOfJSON.get(key)[0]);
                }
            }
            MapOfJSON.clear();

            List<String> last_Value = new List<String>(listOfJSON);
            for(Integer i=0; i< node.getAttributeCount(); i++){
                String key = node.getAttributeKeyAt(i);
                String value = node.getAttribute(key, '');
                last_Value.add('"' + key + '": "' + value + '"');
            }
            listOfJSON.clear();

            String textContent = node.getText();
            if(textContent != null && textContent.trim() != '') {
                textContent = textContent.replace('"', '\\"');
                last_Value.add('"ele_text": "' + textContent + '"');
            }

            if(!isChild){ 
                if(!isArray) {
                    json = '"' + node.getName() + '": {' + String.join(last_Value, ', ') + '}';
                }
                else {
                    json = ' {' + String.join(last_Value, ', ') + '}';
                }
            }
            else {
                if(last_Value.size() == 1 && textContent != null && textContent.trim() != ''){ 
                    json = '"' + textContent + '"';
                }
                else {
                    // if(!isArray) { 
                        if(last_Value.size() >0){ 
                            json = '{' + String.join(last_Value, ', ') + '}';
                        }
                    // }
                    // else {
                    //     json = String.join(last_Value, ', ');
                    // }
                }
            }
        }

        if(rootElementName == node.getName()) {
            if(!isArray) { 
                json = '{' + json + '}';
            }
            else {
                json = '{"' + node.getName() + '" : ' + json + '}';
            }
        }
        return json;
    }
}