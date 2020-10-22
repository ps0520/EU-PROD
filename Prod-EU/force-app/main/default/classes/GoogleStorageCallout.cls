public class GoogleStorageCallout extends HttpCallout {
	private String fileName;
	private String contentType;
	private Integer fileSize;
	private String fileBody;
	private String accessToken;
	public Boolean requiresAjaxCall;

	public static GoogleStorage__c googleStorageSettings = GoogleStorage__c.getInstance();
	private static final String MEDIA = 'media';
	private static final String RESUMABLE = 'resumable';
	private static final String AUTHOIZATION = 'Authorization';
	private static final String BEARER = 'Bearer ';
	private static final String CONTENT_TYPE = 'Content-Type';
	private static final String CONTENT_LENGTH = 'Content-Length';
	private static final String RANGE = 'Content-Range';
	private static final String PREDEFINED_CONTENT_TYPE = 'application/json; charset=UTF-8';

	public GoogleStorageCallout(String fileName, String contentType, String fileBody,
                                    Integer fileSize) {
		// super(Util.HTTP_POST, buildEndpoint(fileName));
        super('post', buildEndpoint(fileName));
		this.fileName = fileName;
		this.contentType = contentType;
		this.fileBody = fileBody;
		this.fileSize = fileSize;
		setAccessToken();
		setRequestBody();
		setHeaders();
	}

	private void setAccessToken() {
		GoogleAuthentication.AuthenticationResponse response =
                    GoogleAuthentication.getAccessToken(GoogleAuthentication.WRITE_SCOPE);
		this.accessToken = response.accessToken;
		this.requiresAjaxCall = response.requiresAjaxCall;
	}

	public void refreshAccessToken() {
		GoogleAuthentication.AuthenticationResponse response =
                    GoogleAuthentication.fetchNewAccessToken(GoogleAuthentication.WRITE_SCOPE);
		this.accessToken = response.accessToken;
		this.requiresAjaxCall = response.requiresAjaxCall;
	}

	private void setRequestBody() {
		this.request.setBodyAsBlob(EncodingUtil.base64Decode(this.fileBody));
	}

	private void setHeaders() {
		this.request.setHeader(AUTHOIZATION, BEARER + this.accessToken);
                this.request.setHeader(CONTENT_TYPE, this.contentType);
                this.request.setHeader(CONTENT_LENGTH, String.valueOf(this.fileSize));
	}

	public void setAuthorizationHeader(String accessToken) {
		this.request.setHeader(AUTHOIZATION, BEARER + accessToken);
	}

	private static Integer calculateFileSize(Integer startByte, Integer endByte) {
		return endByte - startByte;
	}

	private static String buildEndpoint(String fileName) {
		return 'endpoint =' + googleStorageSettings.URL__c + googleStorageSettings.BucketName__c
                  + '/o?uploadType=' + MEDIA + '&name=' + fileName;
	}

	private static String buildRange(Integer startByte, Integer endByte) {
		return 'bytes=' + String.valueOf(startByte) + '-' + String.valueOf(endByte);
	}
}