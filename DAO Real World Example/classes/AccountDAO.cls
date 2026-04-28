public interface AccountDAO extends DmlInterface {
	Account getAccountFromId(Id accountId);
	List<Account> getAccountsFromIdSet(Set<Id> accountIds);
}