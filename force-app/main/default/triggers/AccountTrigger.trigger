/**
 * Runs after Accounts are created.
 * Hands the new Accounts to the IF_AccountSender interface, which sends them to the site.
 */
trigger AccountTrigger on Account (after insert) {

    // Start one background job for all Accounts in this save,
    // as long as Salesforce still allows another job in this transaction.
    if (Limits.getQueueableJobs() < Limits.getLimitQueueableJobs()) {
        System.enqueueJob(new IF_AccountSender(new List<Id>(Trigger.newMap.keySet())));
    }
}