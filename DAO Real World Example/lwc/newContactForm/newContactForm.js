import { LightningElement, api } from 'lwc';
import createContact from '@salesforce/apex/ContactFormService.createContact';

export default class NewContactForm extends LightningElement {
	@api accountId;
	firstName = '';
	lastName = '';
	email = '';
	isSaving = false;
	successMessage = '';
	errorMessage = '';

	handleFirstNameChange(event) {
		this.firstName = event.target.value;
		this.clearMessages();
	}

	handleLastNameChange(event) {
		this.lastName = event.target.value;
		this.clearMessages();
	}

	handleEmailChange(event) {
		this.email = event.target.value;
		this.clearMessages();
	}

	clearMessages() {
		this.successMessage = '';
		this.errorMessage = '';
	}

	handleSave() {
		// Client-side validation
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
			firstName: this.firstName,
			lastName: this.lastName,
			email: this.email,
			accountId: this.accountId
		})
			.then((contactId) => {
				this.successMessage = `Contact created successfully! ID: ${contactId}`;
				this.resetForm();
				// Fire event to notify parent
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

	handleCancel() {
		this.resetForm();
		// Fire event to notify parent
		this.dispatchEvent(new CustomEvent('cancel'));
	}

	resetForm() {
		this.firstName = '';
		this.lastName = '';
		this.email = '';
	}
}
