@isTest
private class AccountServiceTest {

	private static Account buildMockAccount(String accountId, String accountName) {
		MockSObjectBuilder mockBuilder = new MockSObjectBuilder(Account.sObjectType);
		mockBuilder.setField('Id', accountId);
		mockBuilder.setField('Name', accountName);
		Account testAccount = (Account) mockBuilder.build();

		return testAccount;
	}

	@isTest
	static void getAccountById_givenValidId_accountShouldBeReturned() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);
		Account testAccount = buildMockAccount(testAccountId, 'Acme Corporation');

		AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
		accountMock.insertRecords(new List<Account>{ testAccount });
		AccountService.accountAccessor = accountMock;

		Test.startTest();
			Account result = AccountService.getAccountById(testAccountId);
		Test.stopTest();

		System.assertEquals(testAccountId, result.Id, 'Account ID should match');
		System.assertEquals('Acme Corporation', result.Name, 'Account name should match');
	}

	@isTest
	static void getAccountById_givenNullId_exceptionShouldBeThrown() {
		AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
		AccountService.accountAccessor = accountMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				AccountService.getAccountById(null);
			} catch (IllegalArgumentException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		System.assertEquals(true, exceptionThrown, 'Should throw IllegalArgumentException');
		System.assertEquals('Account ID is required', exceptionMessage, 'Should have correct error message');
	}

	@isTest
	static void getAccountById_givenInvalidId_exceptionShouldBeThrown() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);

		AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
		AccountService.accountAccessor = accountMock;

		Boolean exceptionThrown = false;

		Test.startTest();
			try {
				AccountService.getAccountById(testAccountId);
			} catch (QueryException e) {
				exceptionThrown = true;
			}
		Test.stopTest();

		System.assertEquals(true, exceptionThrown, 'Should throw QueryException for non-existent account');
	}
}