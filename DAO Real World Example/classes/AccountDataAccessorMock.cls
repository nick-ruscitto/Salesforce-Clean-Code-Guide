@isTest
public inherited sharing class AccountDataAccessorMock extends DmlBaseMock implements AccountDAO {

	List<Account> mockDatabaseAccounts;

	public AccountDataAccessorMock() {
		super(new List<Account>());
		this.mockDatabaseAccounts = (List<Account>)super.records;
	}

	public Account getAccountFromId(Id accountId) {
		for (Account a : mockDatabaseAccounts) {
			if (a.Id == accountId) {
				return a;
			}
		}

		throw new QueryException('Account not found');
	}

	public List<Account> getAccountsFromIdSet(Set<Id> accountIds) {
		List<Account> accountsToReturn = new List<Account>();

		for (Account a : mockDatabaseAccounts) {
			if (accountIds.contains(a.Id)) {
				accountsToReturn.add(a);
			}
		}

		return accountsToReturn;
	}
}