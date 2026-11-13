const DEFAULT_MESSAGE = 'Something went wrong. Try again, and contact support if it keeps happening.';

export function messageFrom(error) {
	if (Array.isArray(error?.body)) {
		return error.body.map((entry) => entry.message).join(', ');
	}

	return error?.body?.message || error?.message || DEFAULT_MESSAGE;
}
