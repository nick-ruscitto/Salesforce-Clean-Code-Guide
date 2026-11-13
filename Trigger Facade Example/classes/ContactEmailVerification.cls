public with sharing class ContactEmailVerification {

	public static void resetVerificationForChangedEmails(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		List<Contact> contactsWithEmailChanges = ContactEmailChangeFilter.getContactsWithEmailChanges(newContacts, oldContactsMap);

		for (Contact changedContact : contactsWithEmailChanges) {
			changedContact.Email_Verified__c = false;
		}
	}
}