# Agentforce Guide

> **Work in progress.** Agentforce and Agent Script are changing quickly. This guide is incomplete, and its examples may trail the current platform. Check the syntax against the [Agent Script Reference](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-reference.html).

## Contents
1. [Designing for Agents](#designing-for-agents)
2. [Naming for Agents](#naming-for-agents)
3. [Agent Script](#agent-script)
4. [Invocable Actions](#invocable-actions)
5. [Action Patterns](#action-patterns)
6. [Prompt Templates](#prompt-templates)
7. [Metadata](#metadata)

## Designing for Agents
An agent reads an org the way a new developer does, without being able to ask what anything means. It chooses an action from the action's label and description, understands a field from its name and help text, and acts on what an output says it contains. Every rule in this guide's other sections applies, and the cost of breaking one is higher: a misleading name confuses a developer, but an agent acts on it.

[Back to Contents](#contents)

## Naming for Agents
The [naming rules](./APEX_STYLE_GUIDE.md#naming) apply to everything an agent reads.

* **Reveal intent.** A subagent's name and description say what job it does and when to route to it. An action's label is a verb phrase that says what it does: "Summarize Case", not "Case Helper". Every input and output is named for exactly what it holds
* **Avoid disinformation.** An output is named and described for what it actually contains. An output called "Redlined Document" must not hold a clean copy
* **Make meaningful distinctions.** An agent cannot choose between two actions named "Get Case Details" and "Get Case Info". Merge them, or name each for what sets it apart
* **Pick one word per concept.** Use the same word for a concept in field names, action descriptions, and agent instructions. If the field is `Disposition__c`, the instructions say "disposition", not "decision" or "outcome"
* **Use positive Booleans.** An input named `includeClosedCases` is clearer than `excludeOpenCases`

[Back to Contents](#contents)

## Agent Script
Agent Script is the language that defines an agent in Agentforce Builder: its subagents, variables, actions, and instructions. A script has two kinds of instruction. **Logic instructions** run the same way every time: conditions, running an action, setting a variable. **Prompt instructions**, written after a pipe (`|`), are natural language that the model interprets.

#### Decide what is deterministic
Anything that must happen the same way every time is a logic instruction: business rules, security checks, required steps, and the order of actions. Leave to the model only what needs judgment: understanding the request and wording the reply.

#### Enforce rules in logic, not in wording
A rule written as a sentence in a prompt is a request. A rule written as a condition is enforced. Make an action available only when its precondition holds, rather than telling the model not to use it.

#### One job per subagent
A subagent has a single responsibility, a name that states it, and a description that says when to route to it. A subagent that needs "and" to describe is two subagents.

#### Keep state in variables
Store what the agent has learned in variables rather than relying on the model to remember it. Name variables by the [naming rules](./APEX_STYLE_GUIDE.md#naming): `is_verified`, not `flag` or `not_unverified`.

#### Chain actions deterministically
When one action's output feeds another, run the first action in a logic instruction and store its output in a variable. Do not ask the model to carry the value across.

#### Treat the script as code
* Keep scripts in source control and review changes to them
* State each instruction once. An instruction repeated across subagents will be changed in only one of them
* Delete instructions that no longer apply; do not comment them out

```
variables:
    is_verified: mutable boolean = False
        description: "True once the user's identity has been confirmed."
    case_id: mutable string = ""
        description: "The Id of the case the user is asking about."
    case_summary: mutable string = ""
        description: "A plain-language summary of the case."

subagent case_help:
    label: "Case Help"
    description: "Answers questions about one support case and closes it on request."
    reasoning:
        instructions: ->
            if @variables.case_id != "":
                run @actions.summarize_case
                    with case_id = @variables.case_id
                    set @variables.case_summary = @outputs.summary
            | Answer the user's question from {!@variables.case_summary}.
            | If the summary does not answer it, say so.
        actions:
            close_case: @actions.close_case
                with case_id = @variables.case_id
                available when @variables.is_verified == True
```

The summary always runs when a case is known, and the case can be closed only for a verified user. Neither depends on the model following an instruction.

[Back to Contents](#contents)

## Invocable Actions
An agent works through actions. An Apex action is a class with an `@InvocableMethod`.

#### Structure
* A class has one `@InvocableMethod`
* Name the class for what the action does, ending in `Action`: `CaseSummaryAction`
* The method takes a `List<Request>` and returns a `List<Response>`, with one response for each request, in the same order
* `Request` and `Response` are inner classes, placed at the bottom of the class

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

## Action Patterns

#### Keep actions thin
An action translates requests into calls on the classes that already hold the logic, and turns the results into text the agent can read. It holds no business logic itself, so a screen and an agent share one implementation.

#### Resolve context from the record Id
An agent passes the Id of the record the user is viewing, which may be the record the action needs or one related to it. Resolve it in one value object, named for what it identifies, so every action does not repeat the same lookups. Store the resolved Id in a script variable so later actions receive it directly.

```java
public with sharing class ProjectSubject {

	public static ProjectTaskDAO taskAccessor = new ProjectTaskDataAccessor();

	public final Id projectId;

	private ProjectSubject(Id projectId) {
		this.projectId = projectId;
	}

	public static ProjectSubject forRecordId(Id recordId) {
		return new ProjectSubject(projectIdFrom(recordId));
	}

	private static Id projectIdFrom(Id recordId) {
		if (recordId.getSObjectType() == Project__c.SObjectType) {
			return recordId;
		}

		return taskAccessor.getTaskById(recordId).Project__c;
	}
}
```

#### Resolve the records the user names
When a user names a record in words, match the name to records in steps, and report what was found rather than guessing:

1. Look for exact matches, ignoring case
2. With no exact match, look for records whose name contains the words, only when the words are long enough to be meaningful
3. One match: act on it. No match: say so and list the names that exist. Several matches: list them and ask which one

```java
private static final Integer MIN_LOOSE_MATCH_LENGTH = 3;

private static List<ProjectTask__c> matchesFor(String spokenName, List<ProjectTask__c> tasks) {
	List<ProjectTask__c> exactMatches = new List<ProjectTask__c>();
	List<ProjectTask__c> looseMatches = new List<ProjectTask__c>();

	for (ProjectTask__c task : tasks) {
		if (task.Name.equalsIgnoreCase(spokenName)) {
			exactMatches.add(task);
		} else if (isLooseMatch(task.Name, spokenName)) {
			looseMatches.add(task);
		}
	}

	return exactMatches.isEmpty() ? looseMatches : exactMatches;
}

private static Boolean isLooseMatch(String taskName, String spokenName) {
	return spokenName.length() >= MIN_LOOSE_MATCH_LENGTH
		&& taskName.containsIgnoreCase(spokenName);
}
```

#### Refresh open pages after a change
When an action changes data, the components on the user's page do not know. Publish a platform event after the change, carrying the Id of the changed record. Components on the page subscribe with `lightning/empApi`, ignore events for other records, and refresh themselves.

```java
public with sharing class ProjectChangeEventPublisher {

	public static void publishChange(Id projectId) {
		EventBus.publish(new ProjectChangeEvent__e(EntityId__c = projectId));
	}
}
```

```javascript
subscribe(CHANNEL, -1, (message) => {
	if (message.data.payload.EntityId__c === this.recordId) {
		this.loadProject();
	}
});
```

#### Confirm before outside effects
An action that sends a message, deletes data, or reaches a system outside Salesforce requires the user's confirmation before it runs. Set `require_user_confirmation: True` on the action's definition in the script, and have the agent show what will be sent or changed.

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

#### Use text inputs for templates an agent calls
Give a template that an agent calls text inputs, filled from the outputs of earlier actions: one action gathers the facts, and the template writes from them. Chain the two in a logic instruction, as described in [Chain actions deterministically](#chain-actions-deterministically).

#### State what to do when an input is empty
A template's instructions say what to return when a required input is empty, so it never writes something from nothing.

```
If {!$Input:Findings} is empty, reply only with: "There are no findings to write about."
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
