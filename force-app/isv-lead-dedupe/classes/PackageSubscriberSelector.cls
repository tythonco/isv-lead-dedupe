public with sharing class PackageSubscriberSelector {
    public static Map<String, List<PackageSubscriberDAO>> getPackageSubscribersByOrgId(
        Set<String> orgKeys
    ) {
        // Note: See comment from getParentOrgIdsByChildOrgId--tldr; there could be more than one PackageSubscriber record per org id
        Map<String, List<PackageSubscriberDAO>> subscribersByOrgId = new Map<String, List<PackageSubscriberDAO>>();

        String query =
            'SELECT Id, OrgKey, ParentOrg FROM PackageSubscriber WHERE OrgKey IN (\'' +
            String.join(orgKeys, '\',\'') +
            '\')';

        List<PackageSubscriberDAO> subscribers = ISV_Utils.isGhostUser
            ? (new PackageSubscriberSelector_EscalatedAccess()).runQuery(query)
            : runQuery(query);

        for (PackageSubscriberDAO s : subscribers) {
            List<PackageSubscriberDAO> sList = subscribersByOrgId.containsKey(
                    s.orgKey
                )
                ? subscribersByOrgId.get(s.orgKey)
                : new List<PackageSubscriberDAO>();
            sList.add(s);
            subscribersByOrgId.put(s.orgKey, sList);
        }

        return subscribersByOrgId;
    }

    public static Map<String, String> getParentOrgIdsByChildOrgId(
        Set<String> orgKeys
    ) {
        // Note: A new PackageSubscriber record is created each time a sandbox is refreshed, so there can be multiple PackageSubscriber records with the same org key and
        //       parent org pairing. The same subscriber org could also have installed several of our packages resulting in a similar scenario. However, this is
        //       moot for the use case of matching a sandbox license to its parent org license, where any of these PackageSubscriber records would work.
        Map<String, String> parentOrgIdByChildOrgId = new Map<String, String>();

        String query = 'SELECT Id, OrgKey, ParentOrg FROM PackageSubscriber WHERE InstalledStatus = \'i\' AND OrgStatus != \'Inactive\' AND OrgType = \'Sandbox\' AND ParentOrg != null';
        query += ' AND OrgKey IN (\'' + String.join(orgKeys, '\',\'') + '\')';

        List<PackageSubscriberDAO> childOrgSubscribers = ISV_Utils.isGhostUser
            ? (new PackageSubscriberSelector_EscalatedAccess()).runQuery(query)
            : runQuery(query);

        for (PackageSubscriberDAO s : childOrgSubscribers) {
            parentOrgIdByChildOrgId.put(s.orgKey, s.parentOrg);
        }

        return parentOrgIdByChildOrgId;
    }

    public static List<PackageSubscriberDAO> parseQueryResults(
        String jsonResults
    ) {
        List<PackageSubscriberDAO> res = new List<PackageSubscriberDAO>();
        for (Object o : (List<Object>) JSON.deserializeUntyped(jsonResults)) {
            Map<String, Object> so = (Map<String, Object>) o;
            String psId;
            String psOrgKey;
            String psParentOrg;
            if (so.get('Id') != null) {
                psId = String.valueOf(so.get('Id'));
            }
            if (so.get('OrgKey') != null) {
                psOrgKey = String.valueOf(so.get('OrgKey'));
            }
            if (so.get('ParentOrg') != null) {
                psParentOrg = String.valueOf(so.get('ParentOrg'));
            }
            res.add(new PackageSubscriberDAO(psId, psOrgKey, psParentOrg));
        }
        return res;
    }

    public static List<PackageSubscriberDAO> runQuery(String query) {
        try {
            return parseQueryResults(
                JSON.serialize(Database.query(query, AccessLevel.USER_MODE))
            );
        } catch (System.QueryException e) {
            return new List<PackageSubscriberDAO>();
        }
    }

    public without sharing class PackageSubscriberSelector_EscalatedAccess {
        public List<PackageSubscriberDAO> runQuery(String query) {
            // Note: Testing has shown that queries against PackageSubscriber by the 'LicenseManager' user (aka ghost user)
            //       will drop all fields from SOQL results, even when run in system mode, once the results are passed outside
            //       of the scope of the method where the query was run. To work around this limitation, we serialize the results
            //       and then pass them to a parser to construct a list of PackageSubscriberDAO elements.
            try {
                return PackageSubscriberSelector.parseQueryResults(
                    JSON.serialize(
                        Database.query(query, AccessLevel.SYSTEM_MODE)
                    )
                );
            } catch (System.QueryException e) {
                return new List<PackageSubscriberDAO>();
            }
        }
    }
}
