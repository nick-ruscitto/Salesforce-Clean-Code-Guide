public with sharing class ContactEmailVerification {

	public static void sendVerificationEmail(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		// Get contacts with email changes using normalizer
		List<Contact> contactsWithEmailChanges = ContactDataNormalizer.getContactsWithEmailChanges(newContacts, oldContactsMap);

		if (!contactsWithEmailChanges.isEmpty()) {
			processEmailVerification(contactsWithEmailChanges);
		}
	}

	private static void processEmailVerification(List<Contact> contacts) {
		// Stub: In production, this would send actual verification emails
		for (Contact c : contacts) {
			// Placeholder: Mark that verification is needed
			c.Email_Verified__c = false;
		}
	}
}