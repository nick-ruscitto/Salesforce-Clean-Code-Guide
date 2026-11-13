# Agentforce Guide

## Contents
1. [Invocable Actions](#invocable-actions)
2. [Prompt Templates](#prompt-templates)
3. [Metadata](#metadata)

## Invocable Actions
An agent works through actions. An Apex action is a class with an `@InvocableMethod`.

#### Structure
* A class has one `@InvocableMethod`
* Name the class for what the action does, ending in `Action`: `CaseSummaryAction`
* The method takes a `List<Request>` and returns a `List<Response>`, with one response for each request, in the same order
* `Request` and `Response` are inner classes, placed at the bottom of the class
* The action translates requests into calls on the class that holds the logic, and the results back into responses. It holds no business logic itself

#### Labels and descriptions
The agent decides when to use an action, and what to pass it, from its label and descriptions.

* The method description says what the action does, when to use it, and what it returns
* Each input description says what value to pass and where it comes from
* Each output description says what the value contains and how to use it
* Each description is 255 characters or fewer

#### Errors
At the action boundary, catch the exceptions the user can act on and return their message in the response, so the agent can relay it. This is the same translation a controller performs with `AuraHandledException`. Let unexpected exceptions propagate.

```java
public with sharing class CaseSummaryAction {

	@InvocableMethod(
		label='Summarize Case'
		description='Summarizes a case\'s history and current status. Use when the user asks what has happened on a case. Returns the summary, or a message explaining why none could be made.'
	)
	public static List<Response> summarizeCases(List<Request> requests) {
		List<Response> responses = new List<Response>();

		for (Request request : requests) {
			responses.add(buildResponse(request));
		}

		return responses;
	}

	private static Response buildResponse(Request request) {
		Response response = new Response();

		try {
			response.summary = CaseSummary.forCase(request.caseId);
		} catch (CaseSummary.CaseNotFoundException e) {
			response.errorMessage = e.getMessage();
		}

		return response;
	}

	public class Request {
		@InvocableVariable(
			label='Case Id'
			description='The Id of the case to summarize, from the record the user is viewing or a case the user named.'
			required=true
		)
		public Id caseId;
	}

	public class Response {
		@InvocableVariable(
			label='Summary'
			description='A plain-language summary of the case history and status. Show it to the user as written.'
		)
		public String summary;

		@InvocableVariable(
			label='Error Message'
			description='Set only when no summary could be made. Tell the user this message.'
		)
		public String errorMessage;
	}
}
```

[Back to Contents](#contents)

## Prompt Templates

#### Invoke templates through an interface
Call a prompt template from a class that implements an interface, so that tests can replace it. `ConnectApi` cannot be called from a unit test.

```java
public interface PromptTemplateInvokerInterface {
	String invoke(String templateName, Map<String, String> textInputs);
}
```

```java
public with sharing class PromptTemplateInvoker implements PromptTemplateInvokerInterface {

	private static final String INPUT_PREFIX = 'Input:';

	public String invoke(String templateName, Map<String, String> textInputs) {
		ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
		input.isPreview = false;
		input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
		input.additionalConfig.applicationName = 'PromptBuilderPreview';
		input.inputParams = wrap(textInputs);

		ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
			ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateName, input);

		return output.generations[0].text;
	}

	private Map<String, ConnectApi.WrappedValue> wrap(Map<String, String> textInputs) {
		Map<String, ConnectApi.WrappedValue> wrappedInputs = new Map<String, ConnectApi.WrappedValue>();

		for (String inputName : textInputs.keySet()) {
			ConnectApi.WrappedValue wrappedValue = new ConnectApi.WrappedValue();
			wrappedValue.value = textInputs.get(inputName);
			wrappedInputs.put(INPUT_PREFIX + inputName, wrappedValue);
		}

		return wrappedInputs;
	}
}
```

#### Exchange structured data as JSON
* Send structured inputs as JSON text, built from typed Apex classes
* Ask the template for JSON output in a stated shape, and parse it into typed Apex classes
* Keep the definitions the template reasons over, such as categories or criteria, in one Apex class. Send them to the template as an input and validate the output against the same class, so the prompt and the validation cannot disagree

#### Treat the output as untrusted
Validate everything in the response that can be checked before writing it.

| Check | If it fails |
|---|---|
| Every key in the response is one that was sent | Drop the entry |
| Every record Id in the response is one that was sent | Drop the entry, or record it as unconfirmed |
| Every value is one of the allowed values | Drop the entry |
| Every item that was sent is answered | Treat the response as incomplete |

When the response fails to parse or is incomplete, leave the existing data unchanged.

#### Call templates where callouts are allowed
A prompt template call is a callout. Make it before any DML in the transaction, and run it from asynchronous Apex, such as a Queueable that implements `Database.AllowsCallouts`, when it is not started by the user.

[Back to Contents](#contents)

## Metadata
Agents reason over the org's metadata: object and field names, labels, descriptions, and help text. Follow the [Data Model Guide](./DATA_MODEL_GUIDE.md) so that every field an agent reads has a name and description that say what it holds.

[Back to Contents](#contents)
