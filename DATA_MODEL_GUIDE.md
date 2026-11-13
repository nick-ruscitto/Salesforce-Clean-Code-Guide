# Data Model Guide

## Contents
1. [Object Design](#object-design)
2. [Normalization](#normalization)
3. [Fields](#fields)
4. [Field Types](#field-types)
5. [Relationships](#relationships)
6. [Picklists](#picklists)
7. [Validation Rules](#validation-rules)
8. [Descriptions and Help Text](#descriptions-and-help-text)
9. [Scale](#scale)

The naming rules in the [Apex Style Guide](./APEX_STYLE_GUIDE.md#naming) apply to the data model as well: names reveal intent, avoid noise words and encodings, and use one word per concept.

## Object Design

#### Use a standard object when one fits
Check the standard objects before building a custom one. A standard object brings its own features, such as Contact's email and activity history or Campaign's member statuses. Use it when its meaning matches the thing being modeled, not merely when its fields happen to fit.

#### One object per thing
* An object represents one kind of real-world thing. Do not build a catch-all object whose fields serve several unrelated purposes
* Do not build a separate object for each variation of one thing. Use one object with a record type or a picklist for the variation

#### Naming
* Name an object with a singular noun or noun phrase: `Project__c`, not `Projects__c`
* Name the thing the record represents, not a process or a screen: `ProjectMember__c`, not `ProjectMemberTracking__c` or `ManageProjectMembers__c`
* Do not use noise words such as Data, Info, Record, Detail, or Object
* Qualify a name that would match a standard object. A custom object named `Task__c` appears next to the standard Task in search, list views, and menus; name it for what sets it apart, such as `ProjectTask__c`
* Use a record type for a variation of one thing, not for a different thing

#### The Name field
* Make the Name field a value people recognize the record by, such as a project's name
* When no natural name exists, make it an auto-number with a readable format, such as `PRJ-{00000}`

[Back to Contents](#contents)

## Normalization
Store each fact in one place. A fact stored twice can disagree with itself.

#### First normal form: one value per field
* Store one value per field. Do not store delimited lists such as `'001A;001B;001C'`
* Do not repeat a group of fields, such as `Contact1__c`, `Contact2__c`, and `Contact3__c`. Use a related object, which has no fixed limit and can be queried

#### Second normal form: fields describe the whole record
On a junction object, a field describes the relationship, not one of the two parents.

* On `ProjectMember__c`, `Role__c` belongs: it is the contact's role on that project
* The contact's email does not belong: it describes the contact, and lives on Contact

#### Third normal form: fields depend on the record itself
A field does not depend on another field of the same record.

* On `Project__c`, a stored `ClientIndustry__c` depends on the client account, not on the project. Read it through the relationship instead: `Client__r.Industry`
* When the value is needed on the record, use a formula field. It always shows the current value

#### When to store a copy
Storing a value that also lives elsewhere is correct when the platform requires it or the moment matters:

* **A roll-up summary field.** The platform keeps the copy current
* **A value used in criteria-based sharing rules.** Sharing rules cannot use formula fields
* **A value as it was at a moment.** A stamped value records what was true when something happened, such as a product's price when an order was placed
* **A filter on a large object.** Formula fields are generally not indexed, so a selective filter may need a stored value

A copy must be kept in step by automation, or described as a value recorded at a moment. Its description says which.

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

#### Requiring values
* Make a field required in its definition when every record needs a value, however the record is created. A field required only on a page layout can still be left blank by imports, integrations, and Apex
* Do not make a field required when a value may genuinely be unknown

#### Unique combinations
Salesforce has no unique constraint across two fields. When a combination must be unique, add a unique, external Id text field holding the combined values, set by a trigger before insert and before update, and named for the object: `ProjectMemberKey__c`.

[Back to Contents](#contents)

## Field Types
Choose the type that matches the value. The type decides how the value is validated, displayed, filtered, and reported.

| Value | Use | Not |
|---|---|---|
| One choice from a known set | Picklist | Text |
| An amount of money | Currency | Number or Text |
| A ratio | Percent | Number |
| A count or measurement | Number | Text |
| A calendar date | Date | Date/Time |
| A moment in time | Date/Time | Date, or Text |
| True or false, with no third state | Checkbox | Picklist |
| True, false, or unknown | Picklist | Checkbox |
| Several choices from a known set | Junction object | Multi-select picklist |
| An email address, phone number, or web address | Email, Phone, URL | Text |
| A reference to another record | Lookup or Master-Detail | Text holding an Id |
| A key from another system | Text, marked External Id and Unique | Text |
| A value calculated from the record and its parents | Formula | Field set by automation |
| A total or count of child records | Roll-Up Summary | Field set by automation |

* A Date/Time shows in each user's time zone, so a value saved at midnight in one zone shows as the previous evening in another. Use Date when the time does not matter
* Long text areas cannot be filtered, sorted, or grouped in list views and reports. Keep any value people filter on in its own field
* Multi-select picklists are hard to filter, report on, and automate. A junction object holds the same choices as records

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

## Scale

#### Avoid data skew
* Keep the number of child records under any one parent record below about 10,000. A parent with more causes record locking and slow sharing recalculation when its children change
* Keep the number of records owned by any one user or queue below about 10,000, for the same reason. Spread ownership, or assign records to a user outside the role hierarchy

#### Filter on indexed fields
On objects with many records, queries, list views, and reports perform well only when they filter on indexed fields:

* Id, Name, OwnerId, CreatedDate, SystemModstamp, and RecordTypeId
* Lookup and master-detail fields
* Fields marked External Id or Unique

Formula fields are generally not indexed.

[Back to Contents](#contents)
