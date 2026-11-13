# DAO Framework - Real World Example

This example demonstrates the proper use of the Data Access Object (DAO) pattern with mock-based testing following SOLID principles. The example showcases both read and write operations through a realistic Account record page component.

## Architecture Overview

This example follows SOLID principles with separated concerns:

- **Single Responsibility**: Each controller handles one type of operation
- **Dependency Inversion**: All controllers depend on DAO interfaces, not concrete implementations
- **Open/Closed**: New functionality can be added without modifying existing code

## Files

### Data Access Layer

**AccountDAO.cls** (Interface)
- `Account getAccountFromId(Id accountId)` - Single record query
- `List<Account> getAccountsFromIdSet(Set<Id> accountIds)` - Bulk query

**AccountDataAccessor.cls** (Implementation)
- Queries `Id, Name` fields
- Extends `DmlBase` for DML operations

**AccountDataAccessorMock.cls** (Test Mock)
- In-memory implementation for testing
- Extends `DmlBaseMock`

**AccountDataAccessorTest.cls** (Integration Tests)
- Tests actual database queries
- Validates field selection and filtering

**ContactDAO.cls** (Interface)
- `Contact getContactFromId(Id contactId)` - Single record query
- `List<Contact> getContactsFromIdSet(Set<Id> contactIds)` - Bulk query by Ids
- `List<Contact> getContactsFromAccountId(Id accountId)` - Query by Account relationship

**ContactDataAccessor.cls** (Implementation)
- Queries `Id, FirstName, LastName, Email, AccountId` fields
- Extends `DmlBase` for DML operations

**ContactDataAccessorMock.cls** (Test Mock)
- In-memory implementation for testing
- Filters by AccountId in memory

**ContactDataAccessorTest.cls** (Integration Tests)
- Tests actual database queries
- Validates relationships and field selection

### Apex Controller Classes

**AccountController.cls** (Read operations for Account)
- Uses `AccountDAO`
- Method: `getAccountById(Id accountId)`
- Returns Account record for display

**ContactController.cls** (Read operations for Contact)
- Uses `ContactDAO`
- Method: `getContactsByAccountId(Id accountId)`
- Returns list of Contacts for an Account

**ContactFormController.cls** (Write operations for Contact)
- Uses `ContactDAO`
- Method: `createContact(Contact newContact)`
- Creates new Contact record

### Test Classes

**AccountControllerTest.cls**
- Tests: Valid ID, null ID, non-existent ID
- Demonstrates mocking with `AccountDataAccessorMock`

**ContactControllerTest.cls**
- Tests: Multiple contacts, no contacts, null ID
- Demonstrates `MockSObjectBuilder` to create test Contact records
- Shows how to mock query results

**ContactFormControllerTest.cls**
- Tests: Valid data, missing last name, missing account, minimal data
- Demonstrates mocking insert operations

### Lightning Web Components

**accountContainer** (Container/Orchestrator)
- Placed on Account record pages
- Uses `@wire` to load Account from `AccountController`
- Passes data down to child components
- Coordinates communication between children

**accountDetails** (Presentation)
- Displays Account information
- Receives Account data via `@api` from parent

**accountContactList** (Data Display + Action)
- Uses `@wire` to load Contacts from `ContactController`
- Displays contacts as cards
- "New Contact" button to toggle form
- Handles contact creation events

**newContactForm** (Data Entry)
- Form for creating new contacts
- Receives `accountId` via `@api` from parent
- Fires `contactsaved` and `cancel` events to parent
- Calls `ContactFormController.createContact()`

## DAO Pattern Architecture

The Data Access Object pattern separates database operations into dedicated classes:

**DAO Interface** - Defines methods for data access
- Extends `DmlInterface` for DML operations (insert, update, delete, upsert)
- Declares query methods specific to the object
- Provides abstraction between business logic and data layer

**Data Accessor** - Production implementation
- Extends `DmlBase` for real DML operations
- Implements actual SOQL queries
- Selects only fields needed by the application

**Data Accessor Mock** - Test implementation
- Extends `DmlBaseMock` for in-memory operations
- Implements same interface as production
- Filters data in memory instead of database
- Allows unit testing without database dependencies

**Data Accessor Test** - Integration tests
- Tests production implementation against real database
- Validates SOQL syntax and field selection
- Not used in controller unit tests (those use mocks)

## Key Concepts Demonstrated

### 1. Static Controller Pattern with Public DAO Variable

```apex
public with sharing class ContactController {
    public static ContactDAO contactAccessor = new ContactDataAccessor();

    @AuraEnabled(cacheable=true)
    public static List<Contact> getContactsByAccountId(Id accountId) {
        return contactAccessor.getContactsFromAccountId(accountId);
    }
}
```

Controllers use a public static DAO variable that:
- Defaults to real implementation in production
- Can be overridden with mocks in tests
- No constructors or @TestVisible annotations needed

### 2. Mocking Query Results

```apex
private static Contact buildMockContact(String accountId, String firstName, String lastName) {
    MockSObjectBuilder mockBuilder = new MockSObjectBuilder(Contact.sObjectType);
    mockBuilder.setField('Id', MockIdGenerator.getMockId(Contact.sObjectType));
    mockBuilder.setField('AccountId', accountId);
    mockBuilder.setField('FirstName', firstName);
    mockBuilder.setField('LastName', lastName);
    return (Contact) mockBuilder.build();
}

@isTest
static void getContactsByAccountId_givenValidId_contactsShouldBeReturned() {
    String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
    Contact contact1 = buildMockContact(testAccountId, 'John', 'Doe');
    Contact contact2 = buildMockContact(testAccountId, 'Jane', 'Smith');

    ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
    contactMock.addExistingRecords(new List<Contact>{ contact1, contact2 });
    ContactController.contactAccessor = contactMock;

    List<Contact> results = ContactController.getContactsByAccountId(testAccountId);

    Assert.areEqual(2, results.size());
}
```

`MockSObjectBuilder` allows setting read-only fields (like Id) without database inserts.

### 3. Mocking Insert Operations

```apex
ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
ContactFormController.contactAccessor = contactMock;

Contact newContact = new Contact(LastName = 'Doe', AccountId = testAccountId);
Id resultId = ContactFormController.createContact(newContact);

List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
Assert.areEqual(1, insertedContacts.size());
Assert.areEqual('Doe', insertedContacts[0].LastName);
```

Verify insert operations by inspecting the mock's in-memory records.

### 4. MockIdGenerator

```apex
String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
String testContactId = MockIdGenerator.getMockId(Contact.sObjectType);
```

Generates fake Salesforce IDs for relationships without database queries.

### 5. Component Communication

**Parent to Child (Property Binding):**
```html
<c-account-details account={account}></c-account-details>
<c-account-contact-list account-id={recordId}></c-account-contact-list>
```

**Child to Parent (Custom Events):**
```javascript
// Child component fires event
this.dispatchEvent(new CustomEvent('contactsaved', {
    detail: { contactId }
}));

// Parent component handles event
<c-new-contact-form oncontactsaved={closeFormAndAnnounceNewContact}></c-new-contact-form>
```

## Benefits

**No database hits in tests** - Tests run faster and don't count against governor limits

**True unit tests** - Test business logic in isolation from database

**Easy to test edge cases** - Mock any scenario without complex data setup

**No test data pollution** - No leftover records in the database

**SOLID principles** - Single responsibility per controller, dependency inversion via interfaces

**Simple static controller pattern** - No constructors or @TestVisible needed

**Realistic example** - Demonstrates full read/write cycle in a real-world scenario

## Test Coverage

**AccountControllerTest:**
- Happy path: Get existing account
- Validation: Null account ID
- Error handling: Non-existent account

**ContactControllerTest:**
- Happy path: Get multiple contacts
- Empty result: Account with no contacts
- Validation: Null account ID

**ContactFormControllerTest:**
- Happy path: Create contact with all fields
- Minimal data: Create contact with only required fields
- Validation: Missing last name
- Validation: Missing account ID
- Verification: No records inserted when validation fails

**AccountDataAccessorTest:**
- Integration test: Query single account by ID
- Integration test: Query multiple accounts by ID set

**ContactDataAccessorTest:**
- Integration test: Query single contact by ID
- Integration test: Query multiple contacts by ID set
- Integration test: Query contacts by Account ID (relationship query)
