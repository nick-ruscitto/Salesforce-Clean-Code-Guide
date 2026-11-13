import { LightningElement, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createContact from '@salesforce/apex/ContactFormController.createContact';
import { messageFrom } from 'c/apexErrors';

export default class NewContactForm extends LightningElement {
	@api accountId;
	firstName = '';
	lastName = '';
	email = '';
	isSaving = false;
	errorMessage = '';

	updateFirstName(event) {
		this.firstName = event.target.value;
		this.errorMessage = '';
	}

	updateLastName(event) {
		this.lastName = event.target.value;
		this.errorMessage = '';
	}

	updateEmail(event) {
		this.email = event.target.value;
		this.errorMessage = '';
	}

	async saveContact() {
		if (!this.lastName) {
			this.errorMessage = 'Enter a Last Name to save this contact.';
			return;
		}

		this.isSaving = true;
		this.errorMessage = '';

		try {
			const contactId = await createContact({ newContact: this.buildContact() });
			this.resetForm();
			this.dispatchEvent(new ShowToastEvent({ title: 'Contact created', variant: 'success' }));
			this.dispatchEvent(new CustomEvent('contactsaved', { detail: { contactId } }));
		} catch (error) {
			this.errorMessage = messageFrom(error);
		} finally {
			this.isSaving = false;
		}
	}

	cancelNewContact() {
		this.resetForm();
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	buildContact() {
		return {
			sobjectType: 'Contact',
			FirstName: this.firstName,
			LastName: this.lastName,
			Email: this.email,
			AccountId: this.accountId
		};
	}

	resetForm() {
		this.firstName = '';
		this.lastName = '';
		this.email = '';
	}
}
