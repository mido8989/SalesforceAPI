/**
 * Tests for the Account interface: AccountTrigger and IF_AccountSender together.
 */
@IsTest
private class IF_AccountSender_Test {

    /** Pretends to be the site, and remembers what it was sent. */
    public class SiteMock implements HttpCalloutMock {
        public HttpRequest lastRequest;

        public HttpResponse respond(HttpRequest request) {
            lastRequest = request;
            HttpResponse response = new HttpResponse();
            response.setStatusCode(200);
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"saved":1}');
            return response;
        }
    }

    @IsTest
    static void aNewAccountIsSentToTheSite() {
        SiteMock mock = new SiteMock();
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        Account acc = new Account(Name = 'Interface Test Account', Industry = 'Technology');
        insert acc;
        Test.stopTest(); // Background jobs started above run here.

        Assert.isNotNull(mock.lastRequest, 'The interface should have called the site');
        Assert.areEqual('callout:Lead_Form_Web/api/salesforce/accounts', mock.lastRequest.getEndpoint());
        Assert.areEqual('POST', mock.lastRequest.getMethod());

        // Read the JSON that was sent and check its content.
        Map<String, Object> body =
            (Map<String, Object>) JSON.deserializeUntyped(mock.lastRequest.getBody());
        List<Object> sentAccounts = (List<Object>) body.get('accounts');
        Assert.areEqual(1, sentAccounts.size());

        Map<String, Object> sent = (Map<String, Object>) sentAccounts[0];
        Assert.areEqual(String.valueOf(acc.Id), (String) sent.get('salesforceId'));
        Assert.areEqual('Interface Test Account', (String) sent.get('name'));
        Assert.areEqual('Technology', (String) sent.get('industry'));
        Assert.isNotNull(sent.get('createdDate'));

        // The call should also have been recorded in the interface log.
        List<IF_Log__c> logs = [SELECT Interface__c, Status__c, RecordCount__c FROM IF_Log__c];
        Assert.areEqual(1, logs.size());
        Assert.areEqual('IF_AccountSender', logs[0].Interface__c);
        Assert.areEqual('Success', logs[0].Status__c);
        Assert.areEqual(1, logs[0].RecordCount__c.intValue());
    }
}