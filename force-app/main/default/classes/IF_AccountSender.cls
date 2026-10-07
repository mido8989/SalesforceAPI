/**
 * Interface: Salesforce -> lead-form-web site
 * Data:      newly created Accounts
 * Target:    POST /api/salesforce/accounts (Named Credential: Lead_Form_Web)
 *
 * Runs in the background, after the user's save has finished.
 */
public with sharing class IF_AccountSender implements Queueable, Database.AllowsCallouts {

    private static final String NAMED_CREDENTIAL = 'Lead_Form_Web';
    private static final String PATH = '/api/salesforce/accounts';

    private final List<Id> accountIds;

    public IF_AccountSender(List<Id> accountIds) {
        this.accountIds = accountIds;
    }

    public void execute(QueueableContext context) {
        List<Account> accounts = [
            SELECT Id, Name, Industry, CreatedDate
            FROM Account
            WHERE Id IN :accountIds
        ];
        if (accounts.isEmpty()) {
            return;
        }

        // Build the list in the shape the site expects.
        List<Map<String, Object>> items = new List<Map<String, Object>>();
        for (Account acc : accounts) {
            items.add(new Map<String, Object>{
                'salesforceId' => acc.Id,
                'name' => acc.Name,
                'industry' => acc.Industry,
                'createdDate' => acc.CreatedDate.formatGmt('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
            });
        }

        IF_Callout.postJson(NAMED_CREDENTIAL, PATH, new Map<String, Object>{ 'accounts' => items });
    }
}