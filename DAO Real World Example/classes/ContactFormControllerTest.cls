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
		System.assertEquals(1, insertedContacts.size(), 'Should insert exactly one contact');

		Contact insertedContact = insertedContacts[0];
		System.assertEquals('John', insertedContact.FirstName, 'First name should match');
		System.assertEquals('Doe', insertedContact.LastName, 'Last name should match');
		System.assertEquals('john.doe@example.com', insertedContact.Email, 'Email should match');
		System.assertEquals(testAccountId, insertedContact.AccountId, 'AccountId should match');
		System.assertNotEquals(null, resultId, 'Should return a Contact Id');
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

		System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException');
		System.assertEquals('Last Name is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		System.assertEquals(0, insertedContacts.size(), 'Should not insert any contacts');
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

		System.assertEquals(true, exceptionThrown, 'Should throw AuraHandledException');
		System.assertEquals('Account is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		System.assertEquals(0, insertedContacts.size(), 'Should not insert any contacts');
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
		System.assertEquals(1, insertedContacts.size(), 'Should insert exactly one contact');

		Contact insertedContact = insertedContacts[0];
		System.assertEquals(null, insertedContact.FirstName, 'First name should be null');
		System.assertEquals('Doe', insertedContact.LastName, 'Last name should match');
		System.assertEquals(null, insertedContact.Email, 'Email should be null');
		System.assertEquals(testAccountId, insertedContact.AccountId, 'AccountId should match');
	}
}