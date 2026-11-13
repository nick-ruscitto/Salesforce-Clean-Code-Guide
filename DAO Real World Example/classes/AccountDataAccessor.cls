public inherited sharing class AccountDataAccessor extends DmlBase implements AccountDAO {

	public Account getAccountById(Id accountId) {
		Account a = [
			SELECT Id
				, Name
			FROM Account
			WHERE Id = :accountId
			LIMIT 1
		];

		return a;
	}

	public List<Account> getAccountsByIds(Set<Id> accountIds) {
		return [
			SELECT Id
				, Name
			FROM Account
			WHERE Id IN :accountIds
		];
	}
}