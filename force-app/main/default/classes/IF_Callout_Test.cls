/**
 * Tests for IF_Callout, the common helper used by every outbound interface.
 */
@IsTest
private class IF_Callout_Test {

    /** Pretends to be the other system and answers with a fixed status. */
    public class FixedStatusMock implements HttpCalloutMock {
        private final Integer status;
        public HttpRequest lastRequest;

        public FixedStatusMock(Integer status) {
            this.status = status;
        }

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(status);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"saved":1}');
            return response;
        }
    }

    /** Pretends the other system cannot be reached at all. */
    public class NoAnswerMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest request) {
            CalloutException e = new CalloutException();
            e.setMessage('Read timed out');
            throw e;
        }
    }

    /** Reads the log written by the call, and checks there is exactly one. */
    private static IF_Log__c onlyLog() {
        List<IF_Log__c> logs = [
            SELECT Interface__c, Status__c, StatusCode__c, RecordCount__c,
                   Endpoint__c, RequestBody__c, Message__c
            FROM IF_Log__c
        ];
        Assert.areEqual(1, logs.size(), 'Exactly one log record is expected');
        return logs[0];
    }

    @IsTest
    static void aSuccessfulCallIsSentAndLogged() {
        FixedStatusMock mock = new FixedStatusMock(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        IF_Callout.Result result = IF_Callout.postJson(
            'IF_Test', 'Lead_Form_Web', '/api/test',
            new Map<String, Object>{ 'hello' => 'world' }, 1);
        Test.stopTest();

        Assert.isTrue(result.success);
        Assert.areEqual(200, result.statusCode);
        Assert.areEqual('callout:Lead_Form_Web/api/test', mock.lastRequest.getEndpoint());
        Assert.areEqual('POST', mock.lastRequest.getMethod());

        IF_Log__c log = onlyLog();
        Assert.areEqual('IF_Test', log.Interface__c);
        Assert.areEqual('Success', log.Status__c);
        Assert.areEqual(200, log.StatusCode__c.intValue());
        Assert.areEqual(1, log.RecordCount__c.intValue());
        Assert.areEqual('callout:Lead_Form_Web/api/test', log.Endpoint__c);
        Assert.isTrue(log.RequestBody__c.contains('"hello":"world"'));
    }

    @IsTest
    static void anErrorAnswerIsLoggedAsFailed() {
        Test.setMock(HttpCalloutMock.class, new FixedStatusMock(500));

        Test.startTest();
        IF_Callout.Result result = IF_Callout.postJson(
            'IF_Test', 'Lead_Form_Web', '/api/test', new Map<String, Object>(), 0);
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.areEqual(500, result.statusCode);

        IF_Log__c log = onlyLog();
        Assert.areEqual('Failed', log.Status__c);
        Assert.areEqual(500, log.StatusCode__c.intValue());
        Assert.isTrue(log.Message__c.contains('500'));
    }

    @IsTest
    static void noAnswerAtAllIsLoggedAsFailed() {
        Test.setMock(HttpCalloutMock.class, new NoAnswerMock());

        Test.startTest();
        IF_Callout.Result result = IF_Callout.postJson(
            'IF_Test', 'Lead_Form_Web', '/api/test', new Map<String, Object>(), 0);
        Test.stopTest();

        Assert.isFalse(result.success);
        Assert.isNull(result.statusCode);

        IF_Log__c log = onlyLog();
        Assert.areEqual('Failed', log.Status__c);
        Assert.isNull(log.StatusCode__c);
        Assert.isTrue(log.Message__c.contains('timed out'));
    }
}