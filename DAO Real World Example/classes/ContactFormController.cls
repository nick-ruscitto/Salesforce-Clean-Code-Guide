public with sharing class ContactFormController {

	public static ContactDAO contactAccessor = new ContactDataAccessor();

	@AuraEnabled
	public static Id createContact(Contact newContact) {
		if (String.isBlank(newContact.LastName)) {
			throw UserFacingError.withMessage('Enter a Last Name to save this contact.');
		}

		if (newContact.AccountId == null) {
			throw UserFacingError.withMessage('Choose an account for this contact.');
		}

		contactAccessor.insertRecords(new List<Contact>{ newContact });
		return newContact.Id;
	}
}