/**
 * Common helper for every outbound interface (IF) from Salesforce.
 * Sends the request, measures it, and writes one IF_Log__c record per call,
 * so each interface class only has to describe its own data.
 */
public with sharing class IF_Callout {

    /** What an interface gets back from a call. */
    public class Result {
        public Boolean success = false;
        public Integer statusCode;
        public String body;
        public String errorMessage;
    }

    /** Two minutes, the longest Salesforce allows. */
    private static final Integer TIMEOUT_MS = 120000;

    /**
     * Sends a JSON POST through a Named Credential, logs the outcome, and returns it.
     * A failed call does not raise an error: the caller checks result.success.
     *
     * @param interfaceName   name of the calling interface, written to the log
     * @param namedCredential API name of the Named Credential, for example 'Lead_Form_Web'
     * @param path            path on the target system, starting with '/'
     * @param payload         the data to send; it is converted to JSON
     * @param recordCount     how many records the payload contains, written to the log
     */
    public static Result postJson(String interfaceName, String namedCredential, String path,
            Object payload, Integer recordCount) {

        String endpoint = 'callout:' + namedCredential + path;
        String requestBody = JSON.serialize(payload);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setTimeout(TIMEOUT_MS);
        request.setBody(requestBody);

        Result result = new Result();
        Long startedAt = System.currentTimeMillis();
        try {
            HttpResponse response = new Http().send(request);
            result.statusCode = response.getStatusCode();
            result.body = response.getBody();
            result.success = result.statusCode >= 200 && result.statusCode < 300;
            if (!result.success) {
                result.errorMessage = 'HTTP ' + result.statusCode + ': ' + result.body;
            }
        } catch (CalloutException e) {
            // No answer at all: a timeout, an unreachable system, or a credential problem.
            result.errorMessage = e.getMessage();
        }
        Long durationMs = System.currentTimeMillis() - startedAt;

        writeLog(interfaceName, endpoint, requestBody, recordCount, durationMs, result);
        return result;
    }

    private static void writeLog(String interfaceName, String endpoint, String requestBody,
            Integer recordCount, Long durationMs, Result result) {
        try {
            String message = result.success ? result.body : result.errorMessage;
            insert new IF_Log__c(
                Interface__c = interfaceName.left(80),
                Endpoint__c = endpoint.left(255),
                Status__c = result.success ? 'Success' : 'Failed',
                StatusCode__c = result.statusCode,
                RecordCount__c = recordCount,
                DurationMs__c = durationMs,
                RequestBody__c = requestBody.left(131072),
                Message__c = message == null ? null : message.left(32768)
            );
        } catch (Exception e) {
            // A logging problem must never break the interface itself.
            System.debug(LoggingLevel.ERROR, 'Could not write IF_Log__c: ' + e.getMessage());
        }
    }
}