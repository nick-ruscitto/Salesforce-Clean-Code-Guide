public interface AccountDAO extends DmlInterface {
	Account getAccountById(Id accountId);
	List<Account> getAccountsByIds(Set<Id> accountIds);
}