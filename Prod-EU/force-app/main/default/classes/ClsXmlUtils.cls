/**
 * xmlUtils
 * Helper class for xml operations
 * @author Sundog (Katie Wilson original author)
 * @date 06/13/19
 */

public class ClsXmlUtils {/*
    public static String getStringValueFromXML(String xmlString, String keyField) {
        //Get the value inside of a matching tags
        String valueFound = '';
        if(xmlString.contains('<' + keyField + '>') && xmlString.contains('</' + keyField + '>')) {
            valueFound = xmlString.substring(xmlString.indexOf('<' + keyField + '>') + keyField.length() + 2, 
                                             xmlString.indexOf('</' + keyField + '>'));	           
        }
        return valueFound;
    }
    
    public static List<String> retrieveListBySplit(String stringToSplit, String splitValue, Boolean trimStartTag) {
        //Splits based on the passed in tag
        String sTemp = '';
        List<String> returnListTemp = new List<String>();
        List<String> returnListFinal = new List<String>();
        
        if(String.isBlank(stringToSplit)) {
            return returnListFinal;
        }
        
        stringToSplit = stringToSplit.trim();
        returnListTemp = stringToSplit.split('</' + splitValue + '>');
        
        for(String splitString : returnListTemp) {
            splitString = splitString.trim();
            if(trimStartTag){
                if(splitString.startsWith('<' + splitValue + '>')) {
                    sTemp = '<' + splitValue + '>';
                    splitString = splitString.substring(sTemp.length());
                }
            }            
            returnListFinal.add(splitString);
        }
        return returnListFinal;
    } */
}