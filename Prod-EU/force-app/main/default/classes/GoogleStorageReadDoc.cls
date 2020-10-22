public class GoogleStorageReadDoc extends HttpCallout {
	@TestVisible private String fileName;
	@TestVisible private String contentType;
	@TestVisible private Integer fileSize;
	@TestVisible private String fileBody;
	@TestVisible private String accessToken;
	public Boolean requiresAjaxCall;

	public static List<GoogleStorage__c> googleStorageSettings = GoogleStorage__c.getAll().values();
	@TestVisible private static final String MEDIA = 'media';
	@TestVisible private static final String RESUMABLE = 'resumable';
	@TestVisible private static final String AUTHOIZATION = 'Authorization';
	@TestVisible private static final String BEARER = 'Bearer ';
	@TestVisible private static final String CONTENT_TYPE = 'Content-Type';
	@TestVisible private static final String CONTENT_LENGTH = 'Content-Length';
	@TestVisible private static final String RANGE = 'Content-Range';
	@TestVisible private static final String PREDEFINED_CONTENT_TYPE = 'application/json; charset=UTF-8';
	
    // Method commented - Due to not used
	/*public GoogleStorageReadDoc(String objectName) {
		super('GET', buildEndpoint(objectName));
		this.fileName = objectName;
		//this.contentType = contentType;
		//this.fileBody = fileBody;
		//this.fileSize = fileSize;
		setAccessToken();
		//setRequestBody();
		setHeaders();
	}*/

    public GoogleStorageReadDoc(String objectName, String accessToken) {
		super('GET', buildEndpoint(objectName));
		this.fileName = objectName;
		//setAccessToken();
		this.accessToken = accessToken;
		setHeaders();
	}
    // Method commented - Due to not used
    /*@TestVisible
	private void setAccessToken() {
		GoogleAuthentication.AuthenticationResponse response =
                    GoogleAuthentication.getAccessToken(GoogleAuthentication.READ_SCOPE);
		this.accessToken = response.accessToken;
		this.requiresAjaxCall = response.requiresAjaxCall;
	}*/

	public void refreshAccessToken() {
		GoogleAuthentication.AuthenticationResponse response =
                    GoogleAuthentication.fetchNewAccessToken(GoogleAuthentication.READ_SCOPE);
		this.accessToken = response.accessToken;
		this.requiresAjaxCall = response.requiresAjaxCall;
	}
	// Method commented - Due to not used
	/*@TestVisible
	private void setRequestBody() {
		this.request.setBodyAsBlob(EncodingUtil.base64Decode(this.fileBody));
	}*/
	@TestVisible
	private void setHeaders() {
		this.request.setHeader(AUTHOIZATION, BEARER + this.accessToken);
	}
	
    // Method commented - Due to not used
	/*public void setAuthorizationHeader(String accessToken) {
		this.request.setHeader(AUTHOIZATION, BEARER + accessToken);
	}
	@TestVisible
	private static Integer calculateFileSize(Integer startByte, Integer endByte) {
		return endByte - startByte;
	} */
    @TestVisible
	private static String buildEndpoint(String fileName) {
       return googleStorageSettings[0].URL__c + 'b/' + googleStorageSettings[0].BucketName__c + '/o/' + EncodingUtil.urlEncode(fileName, 'UTF-8') ; // ----- This is good and worked
    }
    public void setEndpoint(String media) {
        this.request.setEndPoint(media);
    }
    // Method commented - Due to not used
	/*@TestVisible
	private static String buildRange(Integer startByte, Integer endByte) {
		return 'bytes=' + String.valueOf(startByte) + '-' + String.valueOf(endByte);
	}*/
}