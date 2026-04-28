public inherited sharing class ContactDataAccessor extends DmlBase implements ContactDAO {

	public Contact getContactFromId(Id contactId) {
		Contact c = [
			SELECT Id, FirstName, LastName, Email, AccountId
			FROM Contact
			WHERE Id = :contactId
			LIMIT 1
		];

		return c;
	}

	public List<Contact> getContactsFromIdSet(Set<Id> contactIds) {
		return [
			SELECT Id, FirstName, LastName, Email, AccountId
			FROM Contact
			WHERE Id IN :contactIds
		];
	}

	public List<Contact> getContactsFromAccountId(Id accountId) {
		return [
			SELECT Id, FirstName, LastName, Email, AccountId
			FROM Contact
			WHERE AccountId = :accountId
		];
	}
}