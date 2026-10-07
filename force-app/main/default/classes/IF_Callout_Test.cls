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

    @IsTest
    static void postJsonSendsTheRequestAndReturnsTheResponse() {
        FixedStatusMock mock = new FixedStatusMock(200);
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        HttpResponse response = IF_Callout.postJson(
            'Lead_Form_Web', '/api/test', new Map<String, Object>{ 'hello' => 'world' });
        Test.stopTest();

        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual('callout:Lead_Form_Web/api/test', mock.lastRequest.getEndpoint());
        Assert.areEqual('POST', mock.lastRequest.getMethod());
        Assert.areEqual('application/json', mock.lastRequest.getHeader('Content-Type'));
        Assert.isTrue(mock.lastRequest.getBody().contains('"hello":"world"'));
    }

    @IsTest
    static void postJsonRaisesAnErrorWhenTheOtherSystemFails() {
        Test.setMock(HttpCalloutMock.class, new FixedStatusMock(500));

        Test.startTest();
        try {
            IF_Callout.postJson('Lead_Form_Web', '/api/test', new Map<String, Object>());
            Assert.fail('An error was expected');
        } catch (IF_Callout.CalloutFailedException e) {
            Assert.isTrue(e.getMessage().contains('500'));
        }
        Test.stopTest();
    }
}