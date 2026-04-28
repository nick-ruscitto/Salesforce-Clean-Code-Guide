@isTest
private class ContactDataAccessorTest {

	@TestSetup
	static void setup() {
		Account acc1 = new Account(Name = 'Acme Corporation');
		insert acc1;

		List<Contact> testContacts = new List<Contact>();

		Contact con1 = new Contact(
			FirstName = 'John',
			LastName = 'Doe',
			AccountId = acc1.Id,
			Email = 'john.doe@example.com'
		);
		testContacts.add(con1);

		Contact con2 = new Contact(
			FirstName = 'Jane',
			LastName = 'Smith',
			AccountId = acc1.Id,
			Email = 'jane.smith@example.com'
		);
		testContacts.add(con2);

		insert testContacts;
	}

	@isTest
	static void getContactFromId_givenValidId_shouldReturnContact() {
		Contact testContact = [SELECT Id FROM Contact WHERE FirstName = 'John' AND LastName = 'Doe' LIMIT 1];
		ContactDataAccessor dao = new ContactDataAccessor();

		Test.startTest();
			Contact result = dao.getContactFromId(testContact.Id);
		Test.stopTest();

		System.assertEquals(testContact.Id, result.Id, 'Should return contact with matching Id');
		System.assertEquals('John', result.FirstName, 'Should return contact with correct FirstName');
		System.assertEquals('Doe', result.LastName, 'Should return contact with correct LastName');
		System.assertNotEquals(null, result.Email, 'Should include Email field');
	}

	@isTest
	static void getContactsFromIdSet_givenMultipleIds_shouldReturnContacts() {
		List<Contact> testContacts = [SELECT Id FROM Contact];

		Set<Id> contactIds = new Set<Id>();
		for (Contact c : testContacts) {
			contactIds.add(c.Id);
		}

		ContactDataAccessor dao = new ContactDataAccessor();

		Test.startTest();
			List<Contact> results = dao.getContactsFromIdSet(contactIds);
		Test.stopTest();

		System.assertEquals(2, results.size(), 'Should return 2 contacts');
		System.assertNotEquals(null, results[0].FirstName, 'Should include FirstName field');
		System.assertNotEquals(null, results[0].LastName, 'Should include LastName field');
	}

	@isTest
	static void getContactsFromAccountId_givenAccountId_shouldReturnContacts() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Acme Corporation' LIMIT 1];
		ContactDataAccessor dao = new ContactDataAccessor();

		Test.startTest();
			List<Contact> results = dao.getContactsFromAccountId(testAccount.Id);
		Test.stopTest();

		System.assertEquals(2, results.size(), 'Should return 2 contacts for the account');

		for (Contact c : results) {
			System.assertEquals(testAccount.Id, c.AccountId, 'All returned contacts should belong to the account');
			System.assertNotEquals(null, c.FirstName, 'Should include FirstName field');
			System.assertNotEquals(null, c.LastName, 'Should include LastName field');
			System.assertNotEquals(null, c.Email, 'Should include Email field');
		}
	}
}