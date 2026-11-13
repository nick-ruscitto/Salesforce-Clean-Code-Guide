@isTest
private class AccountControllerTest {

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
		accountMock.addExistingRecords(new List<Account>{ testAccount });
		AccountController.accountAccessor = accountMock;

		Test.startTest();
			Account result = AccountController.getAccountById(testAccountId);
		Test.stopTest();

		Assert.areEqual(testAccountId, result.Id, 'Account ID should match');
		Assert.areEqual('Acme Corporation', result.Name, 'Account name should match');
	}

	@isTest
	static void getAccountById_givenNullId_exceptionShouldBeThrown() {
		AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
		AccountController.accountAccessor = accountMock;

		Boolean exceptionThrown = false;
		String exceptionMessage = '';

		Test.startTest();
			try {
				AccountController.getAccountById(null);
			} catch (AuraHandledException e) {
				exceptionThrown = true;
				exceptionMessage = e.getMessage();
			}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException');
		Assert.areEqual('Account ID is required', exceptionMessage, 'Should have correct error message');
	}

	@isTest
	static void getAccountById_givenInvalidId_exceptionShouldBeThrown() {
		String testAccountId = MockIdGenerator.getMockId(Account.sObjectType);

		AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
		AccountController.accountAccessor = accountMock;

		Boolean exceptionThrown = false;

		Test.startTest();
			try {
				AccountController.getAccountById(testAccountId);
			} catch (AuraHandledException e) {
				exceptionThrown = true;
			}
		Test.stopTest();

		Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException for non-existent account');
	}
}