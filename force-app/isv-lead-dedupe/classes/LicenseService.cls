public with sharing class LicenseService {
    public void assignParentLicenses(List<sfLma__License__c> licenses) {
        Set<String> orgIds = getSubscriberOrgIds(licenses);

        // Query PackageSubscriber records for parent orgs of the subscriber orgs represented by the licenses
        Map<String, String> parentOrgIdByChildOrgId = PackageSubscriberSelector.getParentOrgIdsByChildOrgId(
            orgIds
        );

        Set<String> parentOrgIds = new Set<String>(
            parentOrgIdByChildOrgId.values()
        );

        // Query for license records associated with parent org IDs
        Map<String, List<sfLma__License__c>> parentLicensesByOrgId = LicenseSelector.getLicensesByOrgId(
            parentOrgIds
        );

        matchFieldsFromParentLicense(
            licenses,
            parentOrgIdByChildOrgId,
            parentLicensesByOrgId
        );
    }

    public void deleteDuplicateLicenseLeads(List<sfLma__License__c> licenses) {
        List<Id> leadIdsToDelete = new List<Id>();
        for (sfLma__License__c l : licenses) {
            if (l.Parent_License__c != null && l.sfLma__Lead__c != null) {
                leadIdsToDelete.add(l.sfLma__Lead__c);
            }
        }
        if (!leadIdsToDelete.isEmpty()) {
            Database.delete(leadIdsToDelete, true, ISV_Utils.accessMode); // False Positive from Checkmarx - Not yet updated for AccessLevel option
        }
    }

    public Boolean doAllMatchingPackageSubscribersExist(
        List<sfLma__License__c> licenses
    ) {
        // Note: It seems some async process managed by Salesforce creates the PackageSubscriber records
        //       after the creation of the corresponding sfLma__License__c records.
        Boolean allMatchingPackageSubscribersExist;

        Set<String> orgIds = getSubscriberOrgIds(licenses);

        // Query for matching PackageSubscriber records
        Map<String, List<PackageSubscriberDAO>> subscribersByOrgId = PackageSubscriberSelector.getPackageSubscribersByOrgId(
            orgIds
        );

        if (
            subscribersByOrgId.isEmpty() ||
            subscribersByOrgId.keySet().size() != orgIds.size()
        ) {
            allMatchingPackageSubscribersExist = false;
        } else {
            allMatchingPackageSubscribersExist = true;
        }

        return allMatchingPackageSubscribersExist;
    }

    public void enqueueAssignParentLicenses(List<sfLma__License__c> licenses) {
        Set<Id> licenseIds = ISV_Utils.collectIds(licenses, 'Id');
        if (!Test.isRunningTest())
            System.enqueueJob(
                new QueueableNewSubscriberHandler(licenseIds),
                QueueableNewSubscriberHandler.INIT_DELAY
            );
    }

    public void savePopulatedParentLicenses(List<sfLma__License__c> licenses) {
        List<SObject> licensesToUpdate = new List<SObject>();
        for (sfLma__License__c l : licenses) {
            if (l.Parent_License__c != null) {
                licensesToUpdate.add(l);
            }
        }
        if (!licensesToUpdate.isEmpty()) {
            Database.update(licensesToUpdate, true, ISV_Utils.accessMode); // False Positive from Checkmarx - Not yet updated for AccessLevel option
        }
    }

    @TestVisible
    private Set<String> getSubscriberOrgIds(List<sfLma__License__c> licenses) {
        Set<String> orgIds = new Set<String>();
        for (sfLma__License__c license : licenses) {
            if (license.sfLma__Subscriber_Org_ID__c != null) {
                orgIds.add(license.sfLma__Subscriber_Org_ID__c);
            }
        }
        return orgIds;
    }

    private void matchFieldsFromParentLicense(
        List<sfLma__License__c> licenses,
        Map<String, String> parentOrgIdByChildOrgId,
        Map<String, List<sfLma__License__c>> parentLicensesByOrgId
    ) {
        for (sfLma__License__c license : licenses) {
            String orgId = license.sfLma__Subscriber_Org_ID__c;
            if (parentOrgIdByChildOrgId.containsKey(orgId)) {
                String parentOrgId = parentOrgIdByChildOrgId.get(orgId);
                if (parentLicensesByOrgId.containsKey(parentOrgId)) {
                    String packageId = license.sfLma__Package__c;
                    for (
                        sfLma__License__c pl : parentLicensesByOrgId.get(
                            parentOrgId
                        )
                    ) {
                        if (pl.sfLma__Package__c == packageId) {
                            license.Parent_License__c = pl.Id;
                            license.sfLma__Account__c = pl.sfLma__Account__c;
                            license.sfLma__Contact__c = pl.sfLma__Contact__c;
                            break;
                        }
                    }
                }
            }
        }
    }
}
