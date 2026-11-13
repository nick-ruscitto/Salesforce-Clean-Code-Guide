import { LightningElement, api } from 'lwc';
import getAccountById from '@salesforce/apex/AccountController.getAccountById';
import { messageFrom } from 'c/apexErrors';

export default class AccountContainer extends LightningElement {
	@api recordId;
	account;
	errorMessage;

	connectedCallback() {
		this.loadAccount();
	}

	refreshContactList() {
		this.refs.contactList.refreshContacts();
	}

	async loadAccount() {
		try {
			this.account = await getAccountById({ accountId: this.recordId });
			this.errorMessage = undefined;
		} catch (error) {
			this.account = undefined;
			this.errorMessage = messageFrom(error);
		}
	}
}
