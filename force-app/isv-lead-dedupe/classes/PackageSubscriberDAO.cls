public with sharing class PackageSubscriberDAO {
    public String psId;
    public String orgKey;
    public String parentOrg;

    public PackageSubscriberDAO(String psId, String orgKey, String parentOrg) {
        this.psId = psId;
        this.orgKey = orgKey;
        this.parentOrg = parentOrg;
    }
}
