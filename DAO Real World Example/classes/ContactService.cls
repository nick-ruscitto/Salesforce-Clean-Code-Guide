public with sharing class ContactService {

	public static ContactDAO contactAccessor = new ContactDataAccessor();

	@AuraEnabled(cacheable=true)
	public static List<Contact> getContactsByAccountId(Id accountId) {
		if (accountId == null) {
			throw new IllegalArgumentException('Account ID is required');
		}

		List<Contact> contacts = contactAccessor.getContactsFromAccountId(accountId);
		return contacts;
	}
}