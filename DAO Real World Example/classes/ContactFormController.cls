public with sharing class ContactFormController {

	public static ContactDAO contactAccessor = new ContactDataAccessor();

	@AuraEnabled
	public static Id createContact(Contact newContact) {
		if (String.isBlank(newContact.LastName)) {
			throw UserFacingError.withMessage('Last Name is required');
		}

		if (newContact.AccountId == null) {
			throw UserFacingError.withMessage('Account is required');
		}

		contactAccessor.insertRecords(new List<Contact>{ newContact });
		return newContact.Id;
	}
}