@IsTest
private class LicenseTriggerTest {
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
            //Create test package
            sfLma__Package__c pkg = new sfLMa__Package__c(Name = 'Test');
            insert as user pkg;

            // Create parent and child licenses
            sfLma__License__c parentLicense = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123parent',
                sfLma__Seats__c = -1
            );
            insert as user parentLicense;

            sfLma__License__c childLicense = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123child',
                Parent_License__c = parentLicense.Id,
                sfLma__Seats__c = -1
            );
            insert as user childLicense;

            sfLma__License__c orphanLicense = new sfLma__License__c(
                sfLma__Subscriber_Org_ID__c = '00D123orphan',
                sfLma__Seats__c = -1
            );
            insert as user orphanLicense;
        }
    }

    @IsTest
    static void testAfterInsert_WithoutParentOrg() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Arrange
            sfLma__License__c testLicense = new sfLma__License__c(
                sfLma__License_Type__c = 'Parent License',
                sfLma__Subscriber_Org_ID__c = '00D000000000001' // Org without parent
            );

            // Act
            Test.startTest();
            insert as user testLicense;
            Test.stopTest();

            // Assert
            sfLma__License__c insertedLicense = [
                SELECT Id, Parent_License__c
                FROM sfLma__License__c
                WHERE Id = :testLicense.Id
                WITH USER_MODE
            ];

            Assert.isNull(
                insertedLicense.Parent_License__c,
                'Parent license should be null for org without parent'
            );
        }
    }

    @IsTest
    static void testAfterUpdate() {
        System.runAs(new User(Id = UserInfo.getUserId())) {
            // Arrange
            sfLma__License__c parentLicense = [
                SELECT Id, Parent_License__c, sfLma__Expiration__c
                FROM sfLma__License__c
                WHERE sfLma__Subscriber_Org_ID__c = '00D123parent'
                WITH USER_MODE
            ];

            sfLma__License__c childLicense = [
                SELECT Id, Parent_License__c, sfLma__Expiration__c
                FROM sfLma__License__c
                WHERE sfLma__Subscriber_Org_ID__c = '00D123child'
                WITH USER_MODE
            ];

            sfLma__License__c orphanLicense = [
                SELECT Id, Parent_License__c, sfLma__Expiration__c
                FROM sfLma__License__c
                WHERE sfLma__Subscriber_Org_ID__c = '00D123orphan'
                WITH USER_MODE
            ];

            // Act
            Test.startTest();
            ISV_Utils.accessMode = AccessLevel.SYSTEM_MODE;
            parentLicense.sfLma__Expiration__c = Date.today().addDays(1);
            update as user parentLicense;
            Test.stopTest();

            // Assert
        }
    }
}
