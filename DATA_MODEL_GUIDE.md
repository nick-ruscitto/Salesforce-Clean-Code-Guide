# Data Model Guide

## Contents
1. [Objects](#objects)
2. [Fields](#fields)
3. [Relationships](#relationships)
4. [Picklists](#picklists)
5. [Validation Rules](#validation-rules)
6. [Descriptions and Help Text](#descriptions-and-help-text)

The naming rules in the [Apex Style Guide](./APEX_STYLE_GUIDE.md) apply to the data model as well: names reveal intent, avoid noise words and encodings, and use one word per concept.

## Objects
* Name an object with a singular noun or noun phrase: `Project__c`, not `Projects__c`
* Name the thing the record represents, not a process or a screen: `ProjectMember__c`, not `ProjectMemberTracking__c` or `ManageProjectMembers__c`
* Do not use noise words such as Data, Info, Record, Detail, or Object
* Qualify a name that would match a standard object. A custom object named `Task__c` appears next to the standard Task in search, list views, and menus; name it for what sets it apart, such as `ProjectTask__c`
* Use a record type for a variation of one thing, not for a different thing

[Back to Contents](#contents)

## Fields

#### Naming
* API names are PascalCase with no underscores other than the suffix: `StartDate__c`, not `Start_Date__c`
* Labels match API names, with spaces between the words: `StartDate__c` is labeled "Start Date"
* Do not encode the field type in the name: `Billable__c`, not `chkBillable__c` or `BillableCheckbox__c`
* Name a Boolean field as a positive statement that is either true or false: `Billable__c`, `ReceivesNewsletter__c`. Avoid negatives such as `NotBillable__c`
* A field that marks when something starts or ends ends in `Date`, whether it is a Date or a Date/Time: `StartDate__c`, `EndDate__c`
* A field that records when something last or first happened is named for that event: `LastContacted__c`, `FirstAssigned__c`. Do not use suffixes such as `At`, `On`, `Timestamp`, or `DateTime`
* Name a count for what it counts, ending in `Count`: `OpenTaskCount__c`
* Name a lookup for the related object, or for the role the related record plays when there is more than one: `Contact__c`, or `PrimaryContact__c` and `BillingContact__c`

#### Content
* Store one value per field. Do not store delimited lists such as `'001A;001B;001C'`; use a related object
* A formula shows the current value of another field. A stamped field records a value at a moment. Stamp the value when it must agree with something else recorded at that moment, such as an assessment written about it
* Salesforce has no unique constraint across two fields. When a combination must be unique, add a unique, external Id text field holding the combined values, set by a trigger before insert and before update, and named for the object: `ProjectMemberKey__c`

[Back to Contents](#contents)

## Relationships
* Use master-detail when the child cannot exist without the parent and should share its sharing, deletion, and roll-up summaries. Use a lookup otherwise
* Name a junction object for the parent first and then what the record is: `ProjectMember__c` joins `Project__c` and `Contact`
* Use roll-up summary fields on a master-detail relationship before writing code to count or sum children

[Back to Contents](#contents)

## Picklists
* Each value names a state, and the values do not overlap
* Include a starting value, set as the default, so a new record is never blank: `Not Started`, `In Progress`, `Complete`
* Avoid values whose meaning is unclear, such as `Inactive` when it could mean paused or closed
* API names match labels

[Back to Contents](#contents)

## Validation Rules
* Name a validation rule for the condition that must hold: `CloseDateNotInPast`
* Write the message for the user, as described in [Write messages for the person reading them](./APEX_STYLE_GUIDE.md#write-messages-for-the-person-reading-them)
* Show the message next to the field it concerns whenever there is one

[Back to Contents](#contents)

## Descriptions and Help Text
* Every custom object and field has a description: what it holds and where its value comes from, written for administrators and developers
* Every field a user sees has help text: what the value means to the user, in the user's words, not how it is calculated
* Descriptions are read by people and by AI agents that reason over the org's metadata. A field without a description is a field neither can use correctly

```
Field:       LastContacted__c
Label:       Last Contacted
Description: Date/Time of the most recent completed call or meeting with this contact, set when an activity with this contact is completed.
Help Text:   When someone on the team last spoke with this contact.
```

[Back to Contents](#contents)
