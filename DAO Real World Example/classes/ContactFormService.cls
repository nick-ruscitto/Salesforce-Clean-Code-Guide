public with sharing class ContactFormService {

	public static ContactDAO contactAccessor = new ContactDataAccessor();

	@AuraEnabled
	public static Id createContact(String firstName, String lastName, String email, Id accountId) {
		if (String.isBlank(lastName)) {
			throw new IllegalArgumentException('Last Name is required');
		}

		if (accountId == null) {
			throw new IllegalArgumentException('Account is required');
		}

		Contact newContact = new Contact(
			FirstName = firstName,
			LastName = lastName,
			Email = email,
			AccountId = accountId
		);

		contactAccessor.insertRecords(new List<Contact>{ newContact });
		return newContact.Id;
	}
}