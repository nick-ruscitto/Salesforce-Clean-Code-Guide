import { LightningElement, api, wire } from 'lwc';
import getContactsByAccountId from '@salesforce/apex/ContactService.getContactsByAccountId';

export default class AccountContactList extends LightningElement {
	@api accountId;
	contacts = [];
	errorMessage;
	showNewContactForm = false;

	@wire(getContactsByAccountId, { accountId: '$accountId' })
	wiredContacts({ error, data }) {
		if (data) {
			this.contacts = data;
			this.errorMessage = undefined;
		} else if (error) {
			this.errorMessage = error.body?.message || 'An error occurred while loading contacts';
			this.contacts = [];
		}
	}

	get hasContacts() {
		return this.contacts && this.contacts.length > 0;
	}

	get contactCount() {
		return this.contacts ? this.contacts.length : 0;
	}

	handleNewContact() {
		this.showNewContactForm = true;
	}

	handleContactSaved() {
		this.showNewContactForm = false;
		this.refreshContacts();

		// Notify parent that contact was created
		this.dispatchEvent(new CustomEvent('contactcreated'));
	}

	handleCancelNewContact() {
		this.showNewContactForm = false;
	}

	@api
	refreshContacts() {
		// Force wire adapter to refresh
		return eval("$A").get('e.force:refreshView').fire();
	}
}
