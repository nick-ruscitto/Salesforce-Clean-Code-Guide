public with sharing class ContactTriggerFacade {

	public static void onBeforeInsert(List<Contact> newContacts) {
		// Add logic here
	}

	public static void onBeforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		ContactEmailVerification.sendVerificationEmail(newContacts, oldContactsMap);
	}

	public static void onAfterInsert(List<Contact> newContacts) {
		// Add logic here
	}

	public static void onAfterUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		// Add logic here
	}
}