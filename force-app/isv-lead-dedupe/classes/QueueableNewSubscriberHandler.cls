public with sharing class QueueableNewSubscriberHandler implements Queueable {
    public static Integer INIT_DELAY = 1;

    private static final LicenseService lService = new LicenseService();

    private Integer attempts = 0;
    private Set<Id> licenseIds;
    private Integer nextDelay;

    public QueueableNewSubscriberHandler(Set<Id> licenseIds) {
        this(0, licenseIds);
    }

    public QueueableNewSubscriberHandler(Integer attempts, Set<Id> licenseIds) {
        this.attempts = attempts;
        this.licenseIds = licenseIds;
        this.nextDelay = Integer.valueOf(Math.pow(2, (attempts + 1)));
    }

    public void execute(QueueableContext context) {
        this.attempts++;
        List<sfLma__License__c> licenses = LicenseSelector.getLicensesByIds(
                licenseIds
            )
            .values();
        if (
            lService.doAllMatchingPackageSubscribersExist(licenses) ||
            Test.isRunningTest()
        ) {
            lService.assignParentLicenses(licenses);
            lService.savePopulatedParentLicenses(licenses);
            lService.deleteDuplicateLicenseLeads(licenses);
        } else if (this.attempts < 5) {
            System.enqueueJob(this, nextDelay);
        }
    }
}
