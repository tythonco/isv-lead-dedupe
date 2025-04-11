# ISV-Lead-Dedupe

This unlocked package is meant to solve an issue many Salesforce ISVs face: linking sandbox licenses with parent production org licenses to remove duplicate leads from their PBO.

The LMA still doesn't support this natively, but using the PackageSubscriber object, we can finally do this ourselves! 💪

An [11 year old post](https://ideas.salesforce.com/s/idea/a0B8W00000GdkD5UAJ/lma-licenses-for-sandboxes-need-lookup-field-to-the-production-org-license) (yes, you read that right!) on the IdeaExchange suggested a lookup field on the license record so you could associate sandbox license records with corresponding parent org licenses.

This unlocked package provides this lookup field and leverages the `PackageSubscriber` object to populate it.

## Why?

Starting in Summer '14 the LMA creates a license record for all sandbox installations/refreshes. This is nice when the sandbox install relates to a prospect running a trial of your app, but it also means ISVs deal with _a ton_ of sandbox license records and related leads that they don't need their sales team to focus on b/c they relate to existing customers.

## How it Works

1. An after insert trigger on the `sfLma__License__c` object launches a queueable job. The queueable job is necessary b/c `PackageSubscriber` records are created asynchronously by a backend Salesforce process.

2. Using the subscriber org id from the license record, the `PackageSubscriber` object is queried for a matching record with the same value in its OrgKey field.

3. If a matching `PackageSubscriber` record exists that also has a value in its ParentOrg field then the `sfLma__License__c` object is queried for a matching record with that ParentOrg value in its subscriber org id field -- this record is the parent production org license for the original sanbox license. 👍

4. The parent license lookup field on the child license is populated, and the parent account and contact lookup fields are copied from the parent down to the child license. Finally, any lead referenced by the child license is deleted as a duplicate.

## Installation

[Sandbox](https://test.salesforce.com/packaging/installPackage.apexp?p0=04tPH000000jwnpYAA)

[Production](https://login.salesforce.com/packaging/installPackage.apexp?p0=04tPH000000jwnpYAA)

Note: After installation, you'll need to add the parent license lookup field to your page layout(s) and assign the permission set appropriately.
