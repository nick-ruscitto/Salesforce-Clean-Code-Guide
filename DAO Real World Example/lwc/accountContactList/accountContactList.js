import { LightningElement, api } from 'lwc';
import getContactsByAccountId from '@salesforce/apex/ContactController.getContactsByAccountId';
import { messageFrom } from 'c/apexErrors';

export default class AccountContactList extends LightningElement {
	@api accountId;
	contacts = [];
	errorMessage;
	showNewContactForm = false;

	connectedCallback() {
		this.loadContacts();
	}

	@api
	refreshContacts() {
		return this.loadContacts();
	}

	get hasContacts() {
		return this.contacts.length > 0;
	}

	get contactCount() {
		return this.contacts.length;
	}

	openNewContactForm() {
		this.showNewContactForm = true;
	}

	closeFormAndAnnounceNewContact() {
		this.showNewContactForm = false;
		this.dispatchEvent(new CustomEvent('contactcreated'));
	}

	closeNewContactForm() {
		this.showNewContactForm = false;
	}

	async loadContacts() {
		try {
			this.contacts = await getContactsByAccountId({ accountId: this.accountId });
			this.errorMessage = undefined;
		} catch (error) {
			this.contacts = [];
			this.errorMessage = messageFrom(error);
		}
	}
}
