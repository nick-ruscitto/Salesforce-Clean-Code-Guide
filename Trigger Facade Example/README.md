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

**ContactDataNormalizer.cls**
- Responsibility: Data filtering and identification
- Method: `getContactsWithEmailChanges(newContacts, oldContactsMap)`
- Returns filtered list of contacts based on criteria

**ContactEmailVerification.cls**
- Responsibility: Email verification process
- Method: `sendVerificationEmail(newContacts, oldContactsMap)`
- Uses ContactDataNormalizer internally to get filtered data
- Processes email verification (stub implementation)

## SOLID Principles Demonstrated

**Single Responsibility Principle**
- ContactDataNormalizer: Only filters/identifies data
- ContactEmailVerification: Only handles email verification
- ContactTriggerFacade: Only orchestrates, no implementation details
- ContactTrigger: Only delegates to facade

**Open/Closed Principle**
- New business logic can be added by creating new classes and calling them from facade
- Existing classes don't need modification

**Dependency Inversion Principle**
- Facade depends on abstractions (business logic classes)
- Business logic classes can be swapped or modified independently

## Example: Email Verification on Contact Update

When a Contact's email address changes:

1. **ContactTrigger** fires on `BEFORE_UPDATE`
2. **ContactTriggerFacade.onBeforeUpdate()** calls `ContactEmailVerification.sendVerificationEmail()`
3. **ContactEmailVerification** calls `ContactDataNormalizer.getContactsWithEmailChanges()`
4. **ContactDataNormalizer** filters to only contacts with email changes
5. **ContactEmailVerification** processes verification for filtered contacts (stub sets `Email_Verified__c = false`)

## File Structure

```
Trigger-Example/
├── triggers/
│   ├── ContactTrigger.trigger
│   └── ContactTrigger.trigger-meta.xml
└── classes/
    ├── ContactTriggerFacade.cls
    ├── ContactTriggerFacade.cls-meta.xml
    ├── ContactDataNormalizer.cls
    ├── ContactDataNormalizer.cls-meta.xml
    ├── ContactEmailVerification.cls
    └── ContactEmailVerification.cls-meta.xml
```

## Benefits

**Maintainability** - Business logic separated into focused classes

**Testability** - Each class can be unit tested independently

**Scalability** - Easy to add new logic without modifying existing code

**Readability** - Clear separation of concerns makes code easier to understand

**SOLID compliance** - Follows all SOLID principles for clean architecture
