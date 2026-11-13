import { LightningElement, api } from 'lwc';
import createContact from '@salesforce/apex/ContactFormController.createContact';

export default class NewContactForm extends LightningElement {
	@api accountId;
	firstName = '';
	lastName = '';
	email = '';
	isSaving = false;
	successMessage = '';
	errorMessage = '';

	updateFirstName(event) {
		this.firstName = event.target.value;
		this.clearMessages();
	}

	updateLastName(event) {
		this.lastName = event.target.value;
		this.clearMessages();
	}

	updateEmail(event) {
		this.email = event.target.value;
		this.clearMessages();
	}

	clearMessages() {
		this.successMessage = '';
		this.errorMessage = '';
	}

	saveContact() {
		if (!this.lastName) {
			this.errorMessage = 'Last Name is required';
			return;
		}
		if (!this.accountId) {
			this.errorMessage = 'Account ID is required';
			return;
		}

		this.isSaving = true;
		this.clearMessages();

		createContact({
			newContact: {
				sobjectType: 'Contact',
				FirstName: this.firstName,
				LastName: this.lastName,
				Email: this.email,
				AccountId: this.accountId
			}
		})
			.then((contactId) => {
				this.successMessage = `Contact created successfully! ID: ${contactId}`;
				this.resetForm();
				this.dispatchEvent(new CustomEvent('contactsaved', {
					detail: { contactId }
				}));
			})
			.catch((error) => {
				this.errorMessage = error.body?.message || 'An error occurred while creating the contact';
			})
			.finally(() => {
				this.isSaving = false;
			});
	}

	cancelNewContact() {
		this.resetForm();
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	resetForm() {
		this.firstName = '';
		this.lastName = '';
		this.email = '';
	}
}
