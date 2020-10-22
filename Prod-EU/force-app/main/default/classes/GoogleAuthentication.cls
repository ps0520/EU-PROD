public class GoogleAuthentication {
    private final static String PRIVATE_KEY = 'privatekey'; // replace with what you named your jks token
    private final static String AUTH_ENDPOINT = 'https://www.googleapis.com/oauth2/v4/token';
    private final static String JWS_SCOPE = 'scope';
    private final static String JWS_IAT = 'iat';
    private final static String JWS_EXP = 'exp';
    public final static String WRITE_SCOPE = 'https://www.googleapis.com/auth/cloud-platform';
    public final static String READ_SCOPE = 'https://www.googleapis.com/auth/devstorage.read_only';
    public static String expirationTime = '';

    // Store the access token in custom settings to reuse accross transactions
    // private static GoogleStorage__c googleStorageSettings = GoogleStorage__c.getOrgDefaults();
	
    @TestVisible private static GoogleStorage__c googleStorageSettings = GoogleStorage__c.getAll().values()[0];
    /**
     * Scope is defined as : A space-delimited list of the permissions that the application requests.
     * Can be https://www.googleapis.com/auth/cloud-platform for example to edit and manage. Return an
     * AuthenticationResponse to inform code if we have commit to DB to not make another callout in
     * the same transaction.
     */
    public static AuthenticationResponse getAccessToken(String scope) {
        system.debug('Current Access Token Value: ' + googleStorageSettings.AccessToken__c);
        AuthenticationResponse response = new AuthenticationResponse(googleStorageSettings.AccessToken__c);
        if (response.accessToken == null) {
        	response = fetchNewAccessToken(scope);
        }
        return response;
    }

    /**
     * JSON Web Token (JWT) bundles private key and some additional required information 
     */
    public static AuthenticationResponse fetchNewAccessToken(String scope) {
        Auth.JWT jwt = new Auth.JWT();
        String serviceAccountEmail = googleStorageSettings.ServiceAccountEmail__c;
        Map<String, Object> claimMap = buildClaimMap(scope);
        jwt.setIss(serviceAccountEmail);
        jwt.setAud(AUTH_ENDPOINT);
        jwt.setAdditionalClaims(claimMap);

        // 'privatekey' cert created using java keytool converting p12 file obtained from google to jks
        Auth.JWS jws = new Auth.JWS(jwt, PRIVATE_KEY);
        // may throw a Auth.JWTBearerTokenExchange.​JWTBearerTokenExchangeException​
        Auth.JWTBearerTokenExchange bearer = new Auth.JWTBearerTokenExchange(AUTH_ENDPOINT, jws);
         AuthenticationResponse response ;
        if(!Test.isRunningTest()){
             response = new AuthenticationResponse(bearer.getAccessToken());
        }else{
            String Mockresponse = '{"accessToken":"AYDWAgEzUqeVsVtcA4ndY25qGFVyaId75im2glOV5Eoog2XajaEjdQlndD7RveqpL7G","token_type":"Bearer"}';
            response = (AuthenticationResponse) JSON.deserialize(Mockresponse, AuthenticationResponse.class);
            
        }
        if (response.accessToken != null) {
        	googleStorageSettings.AccessToken__c = response.accessToken;
            googleStorageSettings.Expiration_Time__c = expirationTime;
        	update googleStorageSettings;
        	response.requiresAjaxCall = true;
        }
        return response;
    }
	@TestVisible
    private static Map<String, Object> buildClaimMap(String scope) {
        Map<String, Object> claimMap = new Map<String, Object>();
        String issueTime = getIssueTime();
        expirationTime = getExpirationTime(issueTime);

        claimMap.put(JWS_SCOPE, scope);
        claimMap.put(JWS_IAT,   issueTime);
        claimMap.put(JWS_EXP,   expirationTime);

        return claimMap;
    }
	@TestVisible
    private static String getIssueTime() {
        Long timeSince = System.now().getTime();
        String iatTime = String.valueOf(timeSince);
        return iatTime;
    }
	@TestVisible
    private static String getExpirationTime(String issueTime) {
        Long longIssueTime = Long.valueOf(issueTime);
        String expTime = String.valueOf(longIssueTime + 3600000); // 1 hr
        return expTime;
    }

    public class AuthenticationResponse {
        public String accessToken;
        public Boolean requiresAjaxCall; // Must use javascript to start another transaction

        public AuthenticationResponse(String accessToken) {
            if (String.isBlank(expirationTime) && (String.isBlank(googleStorageSettings.Expiration_Time__c) || Long.Valueof(googleStorageSettings.Expiration_Time__c) < System.now().getTime()) )  
                this.accessToken = null;
            else this.accessToken = accessToken;
            this.requiresAjaxCall = false;
        }
    }
}