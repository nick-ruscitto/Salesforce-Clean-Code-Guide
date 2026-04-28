@isTest
private class AccountDataAccessorTest {

	@TestSetup
	static void setup() {
		List<Account> testAccounts = new List<Account>();

		Account acc1 = new Account(Name = 'Acme Corporation');
		testAccounts.add(acc1);

		Account acc2 = new Account(Name = 'Wayne Enterprises');
		testAccounts.add(acc2);

		insert testAccounts;
	}

	@isTest
	static void getAccountFromId_givenValidId_shouldReturnAccount() {
		Account testAccount = [SELECT Id FROM Account WHERE Name = 'Acme Corporation' LIMIT 1];
		AccountDataAccessor dao = new AccountDataAccessor();

		Test.startTest();
			Account result = dao.getAccountFromId(testAccount.Id);
		Test.stopTest();

		System.assertEquals(testAccount.Id, result.Id, 'Should return account with matching Id');
		System.assertEquals('Acme Corporation', result.Name, 'Should return account with correct Name');
	}

	@isTest
	static void getAccountsFromIdSet_givenMultipleIds_shouldReturnAccounts() {
		List<Account> testAccounts = [SELECT Id, Name FROM Account];

		Set<Id> accountIds = new Set<Id>();
		for (Account a : testAccounts) {
			accountIds.add(a.Id);
		}

		AccountDataAccessor dao = new AccountDataAccessor();

		Test.startTest();
			List<Account> results = dao.getAccountsFromIdSet(accountIds);
		Test.stopTest();

		System.assertEquals(2, results.size(), 'Should return 2 accounts');
		System.assertNotEquals(null, results[0].Name, 'Should include Name field');
	}
}
