public interface ContactDAO extends DmlInterface {
	Contact getContactFromId(Id contactId);
	List<Contact> getContactsFromIdSet(Set<Id> contactIds);
	List<Contact> getContactsFromAccountId(Id accountId);
}