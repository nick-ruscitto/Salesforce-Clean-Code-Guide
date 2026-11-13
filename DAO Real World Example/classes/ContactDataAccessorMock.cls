@isTest
public inherited sharing class ContactDataAccessorMock extends DmlBaseMock implements ContactDAO {

	List<Contact> mockDatabaseContacts;

	public ContactDataAccessorMock() {
		super(new List<Contact>());
		this.mockDatabaseContacts = (List<Contact>)super.records;
	}

	public Contact getContactById(Id contactId) {
		for (Contact c : mockDatabaseContacts) {
			if (c.Id == contactId) {
				return c;
			}
		}

		throw new QueryException('Contact not found');
	}

	public List<Contact> getContactsByIds(Set<Id> contactIds) {
		List<Contact> contactsToReturn = new List<Contact>();

		for (Contact c : mockDatabaseContacts) {
			if (contactIds.contains(c.Id)) {
				contactsToReturn.add(c);
			}
		}

		return contactsToReturn;
	}

	public List<Contact> getContactsByAccountId(Id accountId) {
		List<Contact> contactsToReturn = new List<Contact>();

		for (Contact c : mockDatabaseContacts) {
			if (c.AccountId == accountId) {
				contactsToReturn.add(c);
			}
		}

		return contactsToReturn;
	}
}