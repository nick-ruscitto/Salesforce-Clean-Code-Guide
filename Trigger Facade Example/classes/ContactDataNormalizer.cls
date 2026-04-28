public with sharing class ContactDataNormalizer {

	public static List<Contact> getContactsWithEmailChanges(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		List<Contact> contactsWithChanges = new List<Contact>();

		for (Contact newContact : newContacts) {
			Contact oldContact = oldContactsMap.get(newContact.Id);

			if (newContact.Email != oldContact.Email && String.isNotBlank(newContact.Email)) {
				contactsWithChanges.add(newContact);
			}
		}

		return contactsWithChanges;
	}
}