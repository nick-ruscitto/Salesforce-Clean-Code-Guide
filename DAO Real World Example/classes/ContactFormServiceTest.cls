@isTest
private class ContactFormServiceTest {

	@isTest
	static void createContact_givenValidData_contactShouldBeCreated() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormService.contactAccessor = contactMock;

		Test.startTest();
			Id resultId = ContactFormService.createContact('John', 'Doe', 'john.doe@example.com', testAccountId);
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
		ContactFormService.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactFormService.createContact('John', '', 'john.doe@example.com', testAccountId);
			} catch (IllegalArgumentException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		System.assertEquals(true, exceptionThrown, 'Should throw IllegalArgumentException');
		System.assertEquals('Last Name is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		System.assertEquals(0, insertedContacts.size(), 'Should not insert any contacts');
	}

	@isTest
	static void createContact_givenMissingAccount_exceptionShouldBeThrown() {
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormService.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactFormService.createContact('John', 'Doe', 'john.doe@example.com', null);
			} catch (IllegalArgumentException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		System.assertEquals(true, exceptionThrown, 'Should throw IllegalArgumentException');
		System.assertEquals('Account is required', exceptionMessage, 'Should have correct error message');

		List<Contact> insertedContacts = (List<Contact>) contactMock.getRecords();
		System.assertEquals(0, insertedContacts.size(), 'Should not insert any contacts');
	}

	@isTest
	static void createContact_givenMinimalData_contactShouldBeCreatedWithoutFirstName() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactFormService.contactAccessor = contactMock;

		Test.startTest();
			Id resultId = ContactFormService.createContact(null, 'Doe', null, testAccountId);
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