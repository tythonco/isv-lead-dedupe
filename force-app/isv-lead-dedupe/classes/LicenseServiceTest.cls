@IsTest
private class LicenseServiceTest {
    @TestSetup
    static void setupTestDate() {
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
    }

    @IsTest
    static void testAssignParentLicenses() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            sfLma__License__c license = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123456789ABC'
            );

            // Test
            Test.startTest();
            insert as user license;
            Test.stopTest();

            // Verify
            sfLma__License__c result = [
                SELECT Parent_License__c
                FROM sfLma__License__c
                WHERE Id = :license.Id
                WITH USER_MODE
            ];

            // Since we can't create PackageSubscriber records in tests,
            // the Parent_License__c field should be null
            System.assertEquals(
                null,
                result.Parent_License__c,
                'Parent license should not be set in test context'
            );
        }
    }

    @IsTest
    static void testGetSubscriberOrgIds() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            List<sfLma__License__c> licenses = new List<sfLma__License__c>{
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = '00D123'),
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = '00D456'),
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = null)
            };

            // Test
            Test.startTest();
            LicenseService service = new LicenseService();
            Set<String> result = service.getSubscriberOrgIds(licenses);
            Test.stopTest();

            // Verify
            System.assertEquals(2, result.size(), 'Should collect two org IDs');
            System.assert(
                result.contains('00D123'),
                'Should contain first org ID'
            );
            System.assert(
                result.contains('00D456'),
                'Should contain second org ID'
            );
        }
    }

    @IsTest
    static void testDoAllMatchingPackageSubscribersExist() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            List<sfLma__License__c> licenses = new List<sfLma__License__c>{
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = '00D123'),
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = '00D456'),
                new sfLma__License__c(sfLma__Subscriber_Org_ID__c = null)
            };

            // Test
            Test.startTest();
            LicenseService service = new LicenseService();
            Boolean result = service.doAllMatchingPackageSubscribersExist(
                licenses
            );
            Test.stopTest();

            // Verify
            System.assertEquals(
                false,
                result,
                'PackageSubscriber records should not exist in test context'
            );
        }
    }
}
