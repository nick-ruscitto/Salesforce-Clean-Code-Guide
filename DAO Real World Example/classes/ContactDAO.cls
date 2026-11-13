public interface ContactDAO extends DmlInterface {
	Contact getContactById(Id contactId);
	List<Contact> getContactsByIds(Set<Id> contactIds);
	List<Contact> getContactsByAccountId(Id accountId);
}