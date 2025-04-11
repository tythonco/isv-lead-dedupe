trigger LicenseTrigger on sfLma__License__c(after insert, after update) {
    if (Trigger.isAfter && Trigger.isInsert) {
        LicenseTriggerHandler.handleAfterInsert(Trigger.new);
    }
}
