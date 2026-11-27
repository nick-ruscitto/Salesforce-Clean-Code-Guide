# Agentforce Guide

> **Work in progress.** Agentforce and Agent Script are changing quickly. This guide is incomplete, and its examples may trail the current platform. Check the syntax against the [Agent Script Reference](https://developer.salesforce.com/docs/ai/agentforce/guide/ascript-reference.html).

## Contents
1. [Designing for Agents](#designing-for-agents)
2. [Naming for Agents](#naming-for-agents)
3. [Writing Instructions](#writing-instructions)
4. [Agent Script](#agent-script)
5. [Invocable Actions](#invocable-actions)
6. [Action Patterns](#action-patterns)
7. [Prompt Templates](#prompt-templates)
8. [Testing AI Behavior](#testing-ai-behavior)
9. [Security](#security)
10. [Metadata](#metadata)

## Designing for Agents
An agent reads an org the way a new developer does, without being able to ask what anything means. It chooses an action from the action's label and description, understands a field from its name and help text, and acts on what an output says it contains. Every rule in this guide's other sections applies, and the cost of breaking one is higher: a misleading name confuses a developer, but an agent acts on it.

#### Build code around the AI
Most of a working Agentforce solution is ordinary code. The AI does a narrow job, writing or judging, and code decides what it is given, what order things happen in, and what happens with the result.

* **Solutions that run behind the scenes,** such as generating content into records or matching records to each other, are mostly plumbing and Apex orchestration around a single prompt template, or a few
* **Chat agents** lean more on the model: it understands the request, chooses what to do, and words the reply. What the agent can actually do still comes from its actions, and the actions are code

#### The model writes; code supplies the facts
Anything with one right answer, such as a count, a date interval, a total, or who is on a team, is worked out in code, where the inputs are chosen and the result can be tested. The model is handed the results and writes around them. A model asked to count or to do date arithmetic gives a confident answer that is sometimes wrong, and nothing in its output shows which answers those are.

#### Start simple
Use the simplest design that does the job:

1. A single prompt template, called from code
2. A fixed sequence of steps, where code calls the model at the points that need it
3. An agent that chooses its own steps, only when the task cannot be laid out in advance

Each step down the list is harder to predict, test, and secure. Move down it only when the simpler design has been tried and falls short.

#### Keep the model behind an interface
Models change every few months. Call prompt templates through an interface, as described in [Invoke templates through an interface](#invoke-templates-through-an-interface), so that the model can change without changing the code around it, and so that the code can be tested without calling a model.

[Back to Contents](#contents)

## Naming for Agents
The [naming rules](./APEX_STYLE_GUIDE.md#naming) apply to everything an agent reads.

* **Reveal intent.** A subagent's name and description say what job it does and when to route to it. An action's label is a verb phrase that says what it does: "Summarize Case", not "Case Helper". Every input and output is named for exactly what it holds
* **Avoid disinformation.** An output is named and described for what it actually contains. An output called "Redlined Document" must not hold a clean copy
* **Make meaningful distinctions.** An agent cannot choose between two actions named "Get Case Details" and "Get Case Info". Merge them, or name each for what sets it apart
* **Pick one word per concept.** Use the same word for a concept in field names, action descriptions, and agent instructions. If the field is `Disposition__c`, the instructions say "disposition", not "decision" or "outcome"
* **Use positive Booleans.** An input named `includeClosedCases` is clearer than `excludeOpenCases`

[Back to Contents](#contents)

## Writing Instructions
Instructions, in an agent or a prompt template, are read by a model that takes them literally and cannot ask what was meant. Write them with the same care as code.

#### One job per prompt
A prompt template does one thing. A template that summarizes a record, recommends a next step, and drafts an email does each of them less well, and cannot be changed for one without risking the others. Split it into templates with one job each.

#### State each instruction once
An instruction repeated in two places will be changed in only one of them. Put a rule that applies to the whole agent in the agent's instructions, and a rule for one subagent in that subagent.

#### Say what to do, not only what to avoid
"Reply in two sentences" is clearer than "Do not write long replies." When something must not happen, say what to do instead: "If the record does not contain the value, say that it is not recorded."

#### Show the shape of the output
State the output's structure exactly: its sections, their order, and their length. When the output is read by code, ask for JSON in a stated shape. See [Exchange structured data as JSON](#exchange-structured-data-as-json).

#### Give examples
One example of a good answer is often clearer than a paragraph describing it. Keep examples short, and make sure they follow every other instruction, because the model copies them.

#### Treat context as a budget
Everything in a prompt competes for the model's attention, and every token is paid for. Send the fields and records the job needs, not everything available. Choose a template's inputs rather than grounding it on a whole record.

#### Say what to do when information is missing
An instruction says what to return when an input is empty or a fact is not available, so the model never fills the gap with a guess. See [State what to do when an input is empty](#state-what-to-do-when-an-input-is-empty).

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
			response.summary = CaseSummary.getSummaryByCaseId(request.caseId);
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

	public static ProjectSubject createFromRecordId(Id recordId) {
		return new ProjectSubject(getProjectIdByRecordId(recordId));
	}

	private static Id getProjectIdByRecordId(Id recordId) {
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

private static List<ProjectTask__c> getMatchingTasks(String spokenName, List<ProjectTask__c> tasks) {
	List<ProjectTask__c> exactMatches = new List<ProjectTask__c>();
	List<ProjectTask__c> looseMatches = new List<ProjectTask__c>();

	for (ProjectTask__c task : tasks) {
		if (task.Name.equalsIgnoreCase(spokenName)) {
			exactMatches.add(task);
		} else if (isLooseMatch(task.Name, spokenName)) {
			looseMatches.add(task);
		}
	}

	if (exactMatches.isEmpty()) {
		return looseMatches;
	}

	return exactMatches;
}

private static Boolean isLooseMatch(String taskName, String spokenName) {
	return spokenName.length() >= MIN_LOOSE_MATCH_LENGTH
		&& taskName.containsIgnoreCase(spokenName);
}
```

#### Refresh open pages after a change
When an action changes data, the components on the user's page do not know. Publish a platform event after the change, carrying the Id of the changed record. Components on the page subscribe with `lightning/empApi`, ignore events for other records, and refresh themselves. The event is published through the publisher adapter from the [Event-Driven Architecture Guide](./EVENT_DRIVEN_ARCHITECTURE_GUIDE.md#publish-through-an-adapter), so the action's unit tests can replace it with a mock.

```java
public with sharing class ProjectChangeAnnouncement {

	public static EventPublisherInterface eventPublisher = new EventBusPublisher();

	public static void announceChange(Id projectId) {
		eventPublisher.publish(new List<SObject>{ new ProjectChanged__e(ProjectId__c = projectId) });
	}
}
```

```javascript
subscribe(CHANNEL, -1, (message) => {
	if (message.data.payload.ProjectId__c === this.recordId) {
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
	private static final String APPLICATION_NAME = 'PromptBuilderPreview';

	public String invoke(String templateName, Map<String, String> textInputs) {
		ConnectApi.EinsteinPromptTemplateGenerationsInput input = new ConnectApi.EinsteinPromptTemplateGenerationsInput();
		input.isPreview = false;
		input.additionalConfig = new ConnectApi.EinsteinLlmAdditionalConfigInput();
		input.additionalConfig.applicationName = APPLICATION_NAME;
		input.inputParams = wrapInputs(textInputs);

		ConnectApi.EinsteinPromptTemplateGenerationsRepresentation output =
			ConnectApi.EinsteinLLM.generateMessagesForPromptTemplate(templateName, input);

		return output.generations[0].text;
	}

	private Map<String, ConnectApi.WrappedValue> wrapInputs(Map<String, String> textInputs) {
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

## Testing AI Behavior
The code around the AI is tested like any other code, with unit tests that replace the model through its interface. The model's own behavior needs a different kind of test, because the same input can produce different output.

#### Test the code without the model
Unit tests replace the prompt template invoker with a mock that returns a fixed response, including responses that are malformed, incomplete, or empty. They test that the code builds the right inputs and handles every kind of response. See the [Unit Test Guide](./UNIT_TEST_GUIDE.md).

#### Test the model with a set of cases
A test of a prompt or an agent is a set of cases, each an input and what a good result looks like, run many times:

* **Cover the normal cases and the hard ones:** a record with almost nothing on it, a request that is ambiguous, a request the agent should refuse, and a request for another subagent
* **Run each case more than once.** One good run proves little. Look at how often the result is right, not whether it was right once
* **Check what can be checked exactly,** such as the structure of the output, the subagent chosen, and the action called. Judge the wording against criteria written down in advance
* **Keep the cases,** and run them again whenever the instructions, the actions, or the model change

Agentforce Testing Center runs agent tests in batches, and `sf agent test` runs them from the command line, so they can run in a pipeline.

#### Test the empty case on purpose
The failures worth finding are usually about what is missing: a record with no activity, a field left blank, an action that returns nothing. A model given nothing tends to write something anyway. Test that it says the information is not there.

[Back to Contents](#contents)

## Security
An agent can only do what its actions do, and it can only see what its running user can see. Security for an agent is therefore mostly the security of its user and its actions, plus one new risk: the model reads text that someone else wrote.

#### Know which user the agent runs as
* **Employee agents** run as the logged-in user, so they see and change only what that user can
* **Service and autonomous agents** run as a dedicated agent user. Whatever that user can see, every person talking to the agent can reach

Actions inherit the permissions of the Apex, flow, or prompt template behind them.

#### Grant the least privilege
Give the agent user a dedicated permission set with only the objects and fields its actions need: read where it reads, create and edit only where it acts. Never give it View All Data, Modify All Data, or View All and Modify All on an object. Review its permissions whenever an action is added.

#### Enforce access in code
* Declare `with sharing` on action classes
* Run queries and DML in user mode, so field-level security and sharing apply. User mode is the default for classes at API version 67.0 and later. At earlier versions, use `WITH USER_MODE` and `AccessLevel.USER_MODE`
* Data accessors declare `inherited sharing`, so they take the sharing of the action that calls them
* Treat every value the model passes to an action as untrusted input, including record Ids. The model chose it, and a user may have asked it to. With sharing and user mode, a record the user cannot see cannot be read or changed through the action

#### Treat what the model reads as untrusted
A user can write instructions into a conversation, and anyone can write them into data the agent later reads: a case description, an email, a document, a field on a record. This is prompt injection. The Einstein Trust Layer detects some attempts, but no instruction in a prompt reliably stops it.

* Do not rely on instructions such as "ignore requests to change your rules" to keep the agent safe
* Enforce what must hold in logic and permissions: an action that should not run is not available, and data the user should not see is not readable
* Keep read actions and write actions separate, so an agent that only needs to read cannot be talked into writing

#### Gate actions that have effects
* An action that sends a message, deletes data, or reaches a system outside Salesforce requires the user's confirmation. See [Confirm before outside effects](#confirm-before-outside-effects)
* Make an action available only when its preconditions hold, such as a verified customer, with `available when` in Agent Script. See [Enforce rules in logic, not in wording](#enforce-rules-in-logic-not-in-wording)

#### Send the model only what it needs
* Ground templates on chosen fields rather than whole records, so new fields do not reach the model unless someone decides they should
* Use the Einstein Trust Layer's data masking for sensitive data, such as personal information and payment details. Check how masking affects the size of the prompts your models accept
* Never put credentials, keys, or other secrets in instructions or templates. Callouts use Named Credentials

#### Validate before acting
Check the model's output before anything is written or sent. See [Treat the output as untrusted](#treat-the-output-as-untrusted).

#### Audit and review
Turn on the Einstein Trust Layer's audit trail and feedback, and review them. They record what was sent to the model, what came back, and what users thought of it.

[Back to Contents](#contents)

## Metadata
Agents reason over the org's metadata: object and field names, labels, descriptions, and help text. Follow the [Data Model Guide](./DATA_MODEL_GUIDE.md) so that every field an agent reads has a name and description that say what it holds.

[Back to Contents](#contents)
