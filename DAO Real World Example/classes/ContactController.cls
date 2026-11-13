public with sharing class ContactController {

	public static ContactDAO contactAccessor = new ContactDataAccessor();

	@AuraEnabled(cacheable=true)
	public static List<Contact> getContactsByAccountId(Id accountId) {
		if (accountId == null) {
			throw UserFacingError.withMessage('Account ID is required');
		}

		return contactAccessor.getContactsFromAccountId(accountId);
	}
}