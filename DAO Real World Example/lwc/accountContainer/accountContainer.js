import { LightningElement, api, wire } from 'lwc';
import getAccountById from '@salesforce/apex/AccountController.getAccountById';

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

	refreshContactList() {
		const contactList = this.template.querySelector('c-account-contact-list');
		if (contactList) {
			contactList.refreshContacts();
		}
	}
}
