@isTest
private class ContactServiceTest {

	private static Contact buildMockContact(String contactId, String accountId, String firstName, String lastName, String email) {
		MockSObjectBuilder mockBuilder = new MockSObjectBuilder(Contact.sObjectType);
		mockBuilder.setField('Id', contactId);
		mockBuilder.setField('AccountId', accountId);
		mockBuilder.setField('FirstName', firstName);
		mockBuilder.setField('LastName', lastName);
		mockBuilder.setField('Email', email);
		Contact testContact = (Contact) mockBuilder.build();

		return testContact;
	}

	@isTest
	static void getContactsByAccountId_givenValidId_contactsShouldBeReturned() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		String testContactId1 = MockIdGenerator.getMockId(Contact.sObjectType);
		String testContactId2 = MockIdGenerator.getMockId(Contact.sObjectType);

		Contact contact1 = buildMockContact(testContactId1, testAccountId, 'John', 'Doe', 'john.doe@example.com');
		Contact contact2 = buildMockContact(testContactId2, testAccountId, 'Jane', 'Smith', 'jane.smith@example.com');

		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		contactMock.insertRecords(new List<Contact>{ contact1, contact2 });
		ContactService.contactAccessor = contactMock;

		Test.startTest();
			List<Contact> results = ContactService.getContactsByAccountId(testAccountId);
		Test.stopTest();

		System.assertEquals(2, results.size(), 'Should return 2 contacts');
		System.assertEquals('John', results[0].FirstName, 'First contact first name should match');
		System.assertEquals('Doe', results[0].LastName, 'First contact last name should match');
		System.assertEquals('Jane', results[1].FirstName, 'Second contact first name should match');
		System.assertEquals('Smith', results[1].LastName, 'Second contact last name should match');
	}

	@isTest
	static void getContactsByAccountId_givenAccountWithNoContacts_emptyListShouldBeReturned() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);

		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactService.contactAccessor = contactMock;

		Test.startTest();
			List<Contact> results = ContactService.getContactsByAccountId(testAccountId);
		Test.stopTest();

		System.assertEquals(0, results.size(), 'Should return empty list');
	}

	@isTest
	static void getContactsByAccountId_givenNullId_exceptionShouldBeThrown() {
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactService.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactService.getContactsByAccountId(null);
			} catch (IllegalArgumentException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		System.assertEquals(true, exceptionThrown, 'Should throw IllegalArgumentException');
		System.assertEquals('Account ID is required', exceptionMessage, 'Should have correct error message');
	}
}