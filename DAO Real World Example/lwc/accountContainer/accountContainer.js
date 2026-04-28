import { LightningElement, api, wire } from 'lwc';
import getAccountById from '@salesforce/apex/AccountService.getAccountById';

export default class AccountContainer extends LightningElement {
	@api recordId;
	account;
	errorMessage;

	@wire(getAccountById, { accountId: '$recordId' })
	wiredAccount({ error, data }) {
		if (data) {
			this.account = data;
			this.errorMessage = undefined;
		} else if (error) {
			this.errorMessage = error.body?.message || 'An error occurred while loading the account';
			this.account = undefined;
		}
	}

	handleContactCreated(event) {
		// Refresh contact list by dispatching event to child
		const contactList = this.template.querySelector('c-account-contact-list');
		if (contactList) {
			contactList.refreshContacts();
		}
	}
}
