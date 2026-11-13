# Trigger Framework - Facade Pattern Example

This example demonstrates the proper use of the Facade design pattern for Salesforce triggers following SOLID principles.

## Architecture Overview

The trigger framework uses a facade to orchestrate business logic classes, ensuring clean separation of concerns and adherence to Single Responsibility Principle.

## Pattern Structure

**Trigger** → **Facade** → **Business Logic Classes**

### 1. Trigger (ContactTrigger.trigger)
- Uses switch statement on `Trigger.operationType`
- Delegates to facade methods: `onBeforeInsert`, `onBeforeUpdate`, `onAfterInsert`, `onAfterUpdate`
- Contains no business logic
- Single point of entry for all Contact DML operations

### 2. Facade (ContactTriggerFacade.cls)
- Orchestrates high-level business operations
- Calls appropriate business logic classes
- Does not contain implementation details
- Keeps trigger logic organized and maintainable

### 3. Business Logic Classes

**ContactEmailChangeFilter.cls**
- Responsibility: Finding contacts whose email changed
- Method: `getContactsWithEmailChanges(newContacts, oldContactsMap)`
- Returns the contacts whose email changed to a non-blank value

**ContactEmailVerification.cls**
- Responsibility: Email verification status
- Method: `resetVerificationForChangedEmails(newContacts, oldContactsMap)`
- Uses ContactEmailChangeFilter to find the changed contacts
- Marks each changed contact's email as unverified

## SOLID Principles Demonstrated

**Single Responsibility Principle**
- ContactEmailChangeFilter: Only finds contacts whose email changed
- ContactEmailVerification: Only manages email verification status
- ContactTriggerFacade: Only orchestrates, no implementation details
- ContactTrigger: Only delegates to facade

**Open/Closed Principle**
- New business logic can be added by creating new classes and calling them from facade
- Existing classes don't need modification

## Example: Email Verification on Contact Update

When a Contact's email address changes:

1. **ContactTrigger** fires on `BEFORE_UPDATE`
2. **ContactTriggerFacade.onBeforeUpdate()** calls `ContactEmailVerification.resetVerificationForChangedEmails()`
3. **ContactEmailVerification** calls `ContactEmailChangeFilter.getContactsWithEmailChanges()`
4. **ContactEmailChangeFilter** returns only the contacts whose email changed
5. **ContactEmailVerification** sets `Email_Verified__c = false` on each of them

## File Structure

```
Trigger-Example/
├── triggers/
│   ├── ContactTrigger.trigger
│   └── ContactTrigger.trigger-meta.xml
└── classes/
    ├── ContactTriggerFacade.cls
    ├── ContactTriggerFacade.cls-meta.xml
    ├── ContactEmailChangeFilter.cls
    ├── ContactEmailChangeFilter.cls-meta.xml
    ├── ContactEmailVerification.cls
    └── ContactEmailVerification.cls-meta.xml
```

## Benefits

**Maintainability** - Business logic separated into focused classes

**Testability** - Each class can be unit tested independently

**Scalability** - Easy to add new logic without modifying existing code

**Readability** - Clear separation of concerns makes code easier to understand

**SOLID compliance** - Follows the Single Responsibility and Open/Closed principles
