/**
 * Common helper for every outbound interface (IF) from Salesforce.
 * One place for the request settings and error handling, so each interface
 * class only has to describe its own data.
 */
public with sharing class IF_Callout {

    /** Raised when the other system answers with an error status. */
    public class CalloutFailedException extends Exception {}

    /** Two minutes, the longest Salesforce allows. */
    private static final Integer TIMEOUT_MS = 120000;

    /**
     * Sends a JSON POST through a Named Credential and returns the response.
     *
     * @param namedCredential API name of the Named Credential, for example 'Lead_Form_Web'
     * @param path            path on the target system, starting with '/'
     * @param payload         the data to send; it is converted to JSON
     */
    public static HttpResponse postJson(String namedCredential, String path, Object payload) {
        HttpRequest request = new HttpRequest();
        // Salesforce replaces "callout:<name>" with the address stored in the Named Credential,
        // fetches an access token if needed, and attaches it to the request.
        request.setEndpoint('callout:' + namedCredential + path);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(TIMEOUT_MS);
        request.setBody(JSON.serialize(payload));

        HttpResponse response = new Http().send(request);

        Integer status = response.getStatusCode();
        if (status < 200 || status >= 300) {
            throw new CalloutFailedException(
                'Interface call to ' + namedCredential + path + ' failed: '
                + status + ' ' + response.getBody());
        }
        return response;
    }
}