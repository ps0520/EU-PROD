public class FetchFromGoogleStorage {    
    /*public static Blob getGoogleDoc(String aDoc) {
        GoogleStorageReadDoc readFile = new GoogleStorageReadDoc(aDoc);
        if (readFile.requiresAjaxCall) {
            return null;
        } else {
            readFile.send();
            //system.debug('Response Body: ' + readFile.response.getBody());
            GCFileEntry gcfe = (GCFileEntry) JSON.deserialize(readFile.response.getBody(), GCFileEntry.class);
            //system.debug('mediaLine: ' + gcfe.mediaLink);
            //system.debug('Response Header Keys: ' + readFile.response.getHeaderKeys());
            if (readFile.response.getStatusCode() >= 200
                && readFile.response.getStatusCode() < 300) {
                readFile.setEndpoint(gcfe.mediaLink);
                readFile.send();
                //system.debug('Response Body: ' + readFile.response.getBody());
                //if (readFile.response.getStatusCode() == 302) system.debug('Redirect Location: ' + readFile.response.getHeader('Location'));
                if (readFile.response.getStatusCode() >= 200
                    && readFile.response.getStatusCode() < 300) {
                    // Success!
                    //Blob storedFile = readFile.response.getBodyAsBlob();
                    //system.debug(storedFile);
                    return EncodingUtil.base64Decode(readFile.response.getBody().substringbetween('"'));
                } else if (readFile.response.getStatusCode() >= 400
                            && readFile.response.getStatusCode() < 500) {
                    // Access token has expired and you have to renew it!
                    readFile.refreshAccessToken();
                } else {
                    // unexpected error
                }
            }
            return null;
        }
    }*/
    
    public static Blob getGoogleDoc(String aDoc, String accessToken) {
        GoogleStorageReadDoc readFile = new GoogleStorageReadDoc(aDoc, accessToken);
        readFile.send();
        if (readFile.response.getStatusCode() >= 200 && readFile.response.getStatusCode() < 300) {
            GCFileEntry gcfe = (GCFileEntry) JSON.deserialize(readFile.response.getBody(), GCFileEntry.class);
            System.debug('**--gcfe--'+gcfe);
            readFile.setEndpoint(gcfe.mediaLink);
            readFile.send();
            if (readFile.response.getStatusCode() >= 200 && readFile.response.getStatusCode() < 300) {
                return EncodingUtil.base64Decode(readFile.response.getBody().substringbetween('"'));
            } else {
                return null;
            }
        } else {
            return null;
        }
    }
    public class GCFileEntry{
        public String kind;
        public String id;
        public string selfLink;
        public string mediaLink;
        public string name;
        public string bucket;
        public String generation;
        public String metageneration;
        public String contentType;
        public String storageClass;
        public String size;
        public String md5Hash;
        public String crc32c;
        public String etag;
        public String retentionExpirationTime;
        public String timeCreated;
        public String updated;
        public String timeStorageClassUpdated;
        public metaData metadata;
    }
    public class metaData {
        public string Content_Decoding;
    }
}