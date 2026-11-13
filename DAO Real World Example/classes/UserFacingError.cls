public with sharing class UserFacingError {

	public static AuraHandledException withMessage(String message) {
		AuraHandledException error = new AuraHandledException(message);
		error.setMessage(message);
		return error;
	}
}