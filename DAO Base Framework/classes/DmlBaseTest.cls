@isTest
private class DmlBaseTest {

	private class DmlStub extends DmlBase {}

	private static Account createTestAccount() {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';

		return testAccount;
	}

	static TestMethod void insertRecords_givenAccount_shouldGetId() {
		Account testAccount = createTestAccount();

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.insertRecords(new List<Account> { testAccount });
		Test.stopTest();

		System.assertNotEquals(null, testAccount.Id);
	}

	static TestMethod void updateRecords_givenAccount_shouldGetUpdatedAccount() {
		String oldAccountNumber = '123';
		String newAccountNumber = '456';

		Account testAccount = createTestAccount();
		insert testAccount;

		testAccount.AccountNumber = newAccountNumber;

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.updateRecords(new List<Account> { testAccount });
		Test.stopTest();

		System.assertNotEquals(null, testAccount.Id);
		Account updatedAccount = [SELECT AccountNumber FROM Account WHERE Id = :testAccount.Id];

		System.assertNotEquals(oldAccountNumber, updatedAccount.AccountNumber);
		System.assertEquals(newAccountNumber, updatedAccount.AccountNumber);
	}

	static TestMethod void upsertRecords_givenNewAccount_shouldGetId() {
		Account testAccount = createTestAccount();

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.upsertRecords(new List<Account> { testAccount });
		Test.stopTest();

		System.assertNotEquals(null, testAccount.Id);
	}

	static TestMethod void deleteRecords_givenOldAccount_shouldReturnEmptyList() {
		Account testAccount = createTestAccount();
		insert testAccount; 

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.deleteRecords(new List<Account> { testAccount });
		Test.stopTest();

		List<Account> accountList = [SELECT Id FROM Account];
		System.assert(accountList.isEmpty());
	}
}