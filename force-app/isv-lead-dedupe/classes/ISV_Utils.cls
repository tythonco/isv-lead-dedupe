public with sharing class ISV_Utils {
    public static Boolean isGhostUser =
        UserInfo.getUserType() == 'AutomatedProcess' ||
        UserInfo.getUserType() == 'LicenseManager';
    public static AccessLevel accessMode = isGhostUser
        ? AccessLevel.SYSTEM_MODE
        : AccessLevel.USER_MODE;

    public static Set<Id> collectIds(List<SObject> records, String idField) {
        Set<Id> ids = new Set<Id>();

        for (SObject record : records) {
            Id i = (Id) record.get(idField);
            if (i != null) {
                ids.add(i);
            }
        }

        return ids;
    }

    public static List<SObject> runQuery(String query) {
        return isGhostUser
            ? (new ISV_Utils_EscalatedAccess()).runQuery(query)
            : Database.query(query, AccessLevel.USER_MODE);
    }

    public without sharing class ISV_Utils_EscalatedAccess {
        public List<SObject> runQuery(String query) {
            return Database.query(query, AccessLevel.SYSTEM_MODE);
        }
    }
}
