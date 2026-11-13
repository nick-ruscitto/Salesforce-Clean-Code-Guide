public with sharing class AccountController {

	public static AccountDAO accountAccessor = new AccountDataAccessor();

	@AuraEnabled(cacheable=true)
	public static Account getAccountById(Id accountId) {
		if (accountId == null) {
			throw UserFacingError.withMessage('Account ID is required');
		}

		List<Account> accounts = accountAccessor.getAccountsByIds(new Set<Id>{ accountId });

		if (accounts.isEmpty()) {
			throw UserFacingError.withMessage('Account not found');
		}

		return accounts[0];
	}
}