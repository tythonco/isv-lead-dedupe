@IsTest
private class LicenseSelectorTest {
    @TestSetup
    static void setupTestData() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            List<PermissionSetAssignment> psaList = [
                SELECT Id
                FROM PermissionSetAssignment
                WHERE
                    AssigneeId = :UserInfo.getUserId()
                    AND PermissionSet.Name = 'ISV_Lead_Dedupe_Access'
                WITH USER_MODE
            ];

            PermissionSet permSet = [
                SELECT Id
                FROM PermissionSet
                WHERE Name = 'ISV_Lead_Dedupe_Access'
                WITH USER_MODE
                LIMIT 1
            ];

            if (psaList.isEmpty()) {
                // Assign permission set in order to provide FLS
                PermissionSetAssignment psa = new PermissionSetAssignment( //NOPMD - Avoiding False Positive
                    AssigneeId = UserInfo.getUserId(),
                    PermissionSetId = permSet.Id
                );
                Database.insert(psa, true, AccessLevel.USER_MODE); // False Positive from Checkmarx - Not yet updated for USER_MODE
            }
        }

        System.runAs(new User(Id = UserInfo.getUserId())) {
            sfLma__License__c license = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123'
            );
            insert as user license;
        }
    }

    @IsTest
    static void testGetLicensesByIds() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Get test data
            sfLma__License__c license = [
                SELECT Id
                FROM sfLma__License__c
                WITH USER_MODE
                LIMIT 1
            ];

            // Test
            Test.startTest();
            Map<Id, sfLma__License__c> results = LicenseSelector.getLicensesByIds(
                new Set<Id>{ license.Id }
            );
            Test.stopTest();

            // Verify
            System.assertEquals(1, results.size(), 'Should return one license');
            System.assert(
                results.containsKey(license.Id),
                'Should contain the test license'
            );
        }
    }

    @IsTest
    static void testGetLicensesByOrgId() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Get test data
            sfLma__License__c license = [
                SELECT Id, sfLma__Subscriber_Org_ID__c
                FROM sfLma__License__c
                WITH USER_MODE
                LIMIT 1
            ];

            // Test
            Test.startTest();
            Map<String, List<sfLma__License__c>> results = LicenseSelector.getLicensesByOrgId(
                new Set<String>{ license.sfLma__Subscriber_Org_ID__c }
            );
            Test.stopTest();

            // Verify
            System.assertEquals(1, results.size(), 'Should return one license');
            System.assert(
                results.containsKey(license.sfLma__Subscriber_Org_ID__c),
                'Should contain the test license'
            );
        }
    }
}
