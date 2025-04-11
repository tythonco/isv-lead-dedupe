@IsTest
private class PackageSubscriberSelectorTest {
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
    static void testGetParentOrgIdsByChildOrgId() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Test
            Test.startTest();
            Map<String, String> results = PackageSubscriberSelector.getParentOrgIdsByChildOrgId(
                new Set<String>{ '00D123' }
            );
            Test.stopTest();

            // Since we can't create PackageSubscriber records in tests, verify empty result
            System.assertEquals(
                0,
                results.size(),
                'Should return empty map in test context'
            );
        }
    }

    @IsTest
    static void testParseQueryResults() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Test
            Test.startTest();
            List<PackageSubscriberDAO> results = PackageSubscriberSelector.parseQueryResults(
                '[{"OrgKey":"00D1a000000AaAA","ParentOrg":"00D1a000000AaAB","Id":"0Hb1a00000000aaAAA"}]'
            );
            Test.stopTest();

            // Verify single results representing simulated PackageSubscriber record
            System.assertEquals(
                1,
                results.size(),
                'Should return single-entry map in test context'
            );
        }
    }
}
