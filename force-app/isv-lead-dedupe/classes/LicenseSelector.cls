public with sharing class LicenseSelector {
    public static Map<Id, sfLma__License__c> findAllRelatedLicensesById(
        Set<Id> licenseIds
    ) {
        String query = 'SELECT Id, Parent_License__c, sfLma__Package__c, sfLma__Subscriber_Org_ID__c, sfLma__Expiration__c, sfLma__Account__c, sfLma__Contact__c, sfLma__Lead__c FROM sfLma__License__c WHERE Id IN (\'';
        query += String.join(licenseIds, '\',\'') + '\')';
        query += ' OR Parent_License__c IN (\'';
        query += String.join(licenseIds, '\',\'') + '\')';
        return new Map<Id, sfLma__License__c>(
            (List<sfLma__License__c>) ISV_Utils.runQuery(query)
        );
    }

    public static Map<Id, sfLma__License__c> getLicensesByIds(
        Set<Id> licenseIds
    ) {
        String query = 'SELECT Id, Parent_License__c, sfLma__Package__c, sfLma__Subscriber_Org_ID__c, sfLma__Expiration__c, sfLma__Account__c, sfLma__Contact__c, sfLma__Lead__c FROM sfLma__License__c WHERE Id IN (\'';
        query += String.join(licenseIds, '\',\'') + '\')';
        return new Map<Id, sfLma__License__c>(
            (List<sfLma__License__c>) ISV_Utils.runQuery(query)
        );
    }

    public static Map<String, List<sfLma__License__c>> getLicensesByOrgId(
        Set<String> orgIds
    ) {
        // It's possible two or more license records could be associated with the same org id
        // while representing different package ids, thus the mapping to a list of strings.
        String query = 'SELECT Id, Parent_License__c, sfLma__Package__c, sfLma__Subscriber_Org_ID__c, sfLma__Expiration__c, sfLma__Account__c, sfLma__Contact__c, sfLma__Lead__c FROM sfLma__License__c WHERE sfLma__Subscriber_Org_ID__c IN (\'';
        query += String.join(orgIds, '\',\'') + '\')';
        List<sfLma__License__c> licenses = (List<sfLma__License__c>) ISV_Utils.runQuery(
            query
        );
        Map<String, List<sfLma__License__c>> licensesByOrgId = new Map<String, List<sfLma__License__c>>();
        for (sfLma__License__c l : licenses) {
            String orgId = l.sfLma__Subscriber_Org_ID__c;
            List<sfLma__License__c> ls = licensesByOrgId.containsKey(orgId)
                ? licensesByOrgId.get(orgId)
                : new List<sfLma__License__c>();
            ls.add(l);
            licensesByOrgId.put(orgId, ls);
        }
        return licensesByOrgId;
    }
}
