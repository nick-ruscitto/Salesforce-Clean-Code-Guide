public with sharing class AccountService {

	public static AccountDAO accountAccessor = new AccountDataAccessor();

	@AuraEnabled(cacheable=true)
	public static Account getAccountById(Id accountId) {
		if (accountId == null) {
			throw new IllegalArgumentException('Account ID is required');
		}

		List<Account> accounts = accountAccessor.getAccountsFromIdSet(new Set<Id>{ accountId });

		if (accounts.isEmpty()) {
			throw new QueryException('Account not found');
		}

		return accounts[0];
	}
}