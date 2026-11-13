@isTest
private class ContactControllerTest {

	private static Contact buildMockContact(String accountId, String firstName, String lastName) {
		MockSObjectBuilder mockBuilder = new MockSObjectBuilder(Contact.sObjectType);
		mockBuilder.setField('Id', MockIdGenerator.getMockId(Contact.sObjectType));
		mockBuilder.setField('AccountId', accountId);
		mockBuilder.setField('FirstName', firstName);
		mockBuilder.setField('LastName', lastName);
		Contact testContact = (Contact) mockBuilder.build();

		return testContact;
	}

	@isTest
	static void getContactsByAccountId_givenValidId_contactsShouldBeReturned() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		Contact contact1 = buildMockContact(testAccountId, 'John', 'Doe');
		Contact contact2 = buildMockContact(testAccountId, 'Jane', 'Smith');

		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		contactMock.addExistingRecords(new List<Contact>{ contact1, contact2 });
		ContactController.contactAccessor = contactMock;

		Test.startTest();
			List<Contact> results = ContactController.getContactsByAccountId(testAccountId);
		Test.stopTest();

		Assert.areEqual(2, results.size(), 'Should return 2 contacts');
		Assert.areEqual('John', results[0].FirstName, 'First contact first name should match');
		Assert.areEqual('Doe', results[0].LastName, 'First contact last name should match');
		Assert.areEqual('Jane', results[1].FirstName, 'Second contact first name should match');
		Assert.areEqual('Smith', results[1].LastName, 'Second contact last name should match');
	}

	@isTest
	static void getContactsByAccountId_givenAccountWithNoContacts_emptyListShouldBeReturned() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);

		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactController.contactAccessor = contactMock;

		Test.startTest();
			List<Contact> results = ContactController.getContactsByAccountId(testAccountId);
		Test.stopTest();

		Assert.areEqual(0, results.size(), 'Should return empty list');
	}

	@isTest
	static void getContactsByAccountId_givenNullId_exceptionShouldBeThrown() {
		ContactDataAccessorMock contactMock = new ContactDataAccessorMock();
		ContactController.contactAccessor = contactMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				ContactController.getContactsByAccountId(null);
			} catch (AuraHandledException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException');
		Assert.areEqual('Account ID is required', exceptionMessage, 'Should have correct error message');
	}
}