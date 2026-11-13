import { LightningElement, api, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import getContactsByAccountId from '@salesforce/apex/ContactController.getContactsByAccountId';

export default class AccountContactList extends LightningElement {
	@api accountId;
	contacts = [];
	errorMessage;
	showNewContactForm = false;
	wiredContactsResult;

	@wire(getContactsByAccountId, { accountId: '$accountId' })
	wiredContacts(result) {
		this.wiredContactsResult = result;
		const { error, data } = result;

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

	openNewContactForm() {
		this.showNewContactForm = true;
	}

	closeFormAndAnnounceNewContact() {
		this.showNewContactForm = false;
		this.refreshContacts();
		this.dispatchEvent(new CustomEvent('contactcreated'));
	}

	closeNewContactForm() {
		this.showNewContactForm = false;
	}

	@api
	refreshContacts() {
		return refreshApex(this.wiredContactsResult);
	}
}
