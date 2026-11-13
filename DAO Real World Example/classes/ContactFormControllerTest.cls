@isTest
private class ContactFormControllerTest {

	@isTest
	static void createContact_givenValidData_contactShouldBeCreated() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormController.contactAccessor = contactMock;

		Contact newContact = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			Email = 'john.doe@example.com',
			AccountId = testAccountId
		);

		Test.startTest();
			Id resultId = ContactFormController.createContact(newContact);
		Test.stopTest();

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		Assert.areEqual(1, insertedContacts.size(), 'Should insert exactly one contact');

		Contact insertedContact = insertedContacts[0];
		Assert.areEqual('John', insertedContact.FirstName, 'First name should match');
		Assert.areEqual('Doe', insertedContact.LastName, 'Last name should match');
		Assert.areEqual('john.doe@example.com', insertedContact.Email, 'Email should match');
		Assert.areEqual(testAccountId, insertedContact.AccountId, 'AccountId should match');
		Assert.isNotNull(resultId, 'Should return a Contact Id');
	}

	@isTest
	static void createContact_givenMissingLastName_exceptionShouldBeThrown() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormController.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactFormController.createContact(new Contact(LastName = '', AccountId = testAccountId));
			} catch (AuraHandledException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException');
		Assert.areEqual('Last Name is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		Assert.areEqual(0, insertedContacts.size(), 'Should not insert any contacts');
	}

	@isTest
	static void createContact_givenMissingAccount_exceptionShouldBeThrown() {
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormController.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactFormController.createContact(new Contact(LastName = 'Doe'));
			} catch (AuraHandledException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException');
		Assert.areEqual('Account is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		Assert.areEqual(0, insertedContacts.size(), 'Should not insert any contacts');
	}

	@isTest
	static void createContact_givenMinimalData_contactShouldBeCreatedWithoutFirstName() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormController.contactAccessor = contactMock;

		Contact newContact = new Contact(LastName = 'Doe', AccountId = testAccountId);

		Test.startTest();
			Id resultId = ContactFormController.createContact(newContact);
		Test.stopTest();

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		Assert.areEqual(1, insertedContacts.size(), 'Should insert exactly one contact');

		Contact insertedContact = insertedContacts[0];
		Assert.areEqual(null, insertedContact.FirstName, 'First name should be null');
		Assert.areEqual('Doe', insertedContact.LastName, 'Last name should match');
		Assert.areEqual(null, insertedContact.Email, 'Email should be null');
		Assert.areEqual(testAccountId, insertedContact.AccountId, 'AccountId should match');
	}
}