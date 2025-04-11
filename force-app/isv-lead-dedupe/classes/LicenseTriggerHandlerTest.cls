@IsTest
private class LicenseTriggerHandlerTest {
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
    }

    @IsTest
    static void testHandleAfterInsert() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Create test data
            sfLma__License__c license = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123'
            );

            // Test
            Test.startTest();
            LicenseTriggerHandler.handleAfterInsert(
                new List<sfLma__License__c>{ license }
            );
            Test.stopTest();

            // Since we can't create PackageSubscriber records in tests,
            // verify the handler was called but Parent_License__c remains null
            System.assertEquals(
                null,
                license.Parent_License__c,
                'Parent license should not be set in test context'
            );
        }
    }
}
