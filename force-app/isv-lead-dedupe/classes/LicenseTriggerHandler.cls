public with sharing class LicenseTriggerHandler {
    private static final LicenseService lService = new LicenseService();

    public static void handleAfterInsert(List<sfLma__License__c> newLicenses) {
        lService.enqueueAssignParentLicenses(newLicenses);
    }
}
