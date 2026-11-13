@isTest
private class DmlBaseTest {

	private class DmlStub extends DmlBase {}

	private static Account createTestAccount() {
		Account testAccount = new Account();
		testAccount.Name = 'Test Account';

		return testAccount;
	}

	@isTest
	static void insertRecords_givenAccount_shouldGetId() {
		Account testAccount = createTestAccount();

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.insertRecords(new List<Account> { testAccount });
		Test.stopTest();

		Assert.isNotNull(testAccount.Id);
	}

	@isTest
	static void updateRecords_givenAccount_shouldGetUpdatedAccount() {
		String oldAccountNumber = '123';
		String newAccountNumber = '456';

		Account testAccount = createTestAccount();
		insert testAccount;

		testAccount.AccountNumber = newAccountNumber;

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.updateRecords(new List<Account> { testAccount });
		Test.stopTest();

		Assert.isNotNull(testAccount.Id);
		Account updatedAccount = [SELECT AccountNumber FROM Account WHERE Id = :testAccount.Id];

		Assert.areNotEqual(oldAccountNumber, updatedAccount.AccountNumber);
		Assert.areEqual(newAccountNumber, updatedAccount.AccountNumber);
	}

	@isTest
	static void upsertRecords_givenNewAccount_shouldGetId() {
		Account testAccount = createTestAccount();

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.upsertRecords(new List<Account> { testAccount });
		Test.stopTest();

		Assert.isNotNull(testAccount.Id);
	}

	@isTest
	static void deleteRecords_givenOldAccount_shouldReturnEmptyList() {
		Account testAccount = createTestAccount();
		insert testAccount; 

		DmlStub stub = new DmlStub();
		Test.startTest();
			stub.deleteRecords(new List<Account> { testAccount });
		Test.stopTest();

		List<Account> accountList = [SELECT Id FROM Account];
		Assert.isTrue(accountList.isEmpty());
	}
}