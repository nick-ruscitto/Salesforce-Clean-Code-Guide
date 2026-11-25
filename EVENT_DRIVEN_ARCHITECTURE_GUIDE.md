# Event-Driven Architecture Guide

## Contents
1. [What Event-Driven Architecture Is](#what-event-driven-architecture-is)
2. [When to Use Events](#when-to-use-events)
3. [Designing Events](#designing-events)
4. [Publishing Events](#publishing-events)
5. [Subscribing to Events](#subscribing-to-events)
6. [Change Data Capture](#change-data-capture)
7. [Subscribing in Lightning Web Components](#subscribing-in-lightning-web-components)
8. [Testing Events](#testing-events)

## What Event-Driven Architecture Is
A producer publishes an event, a record that something happened, without knowing who receives it. Consumers subscribe to the event and react to it on their own. The producer and its consumers never call each other, so each can change, fail, or be added without changing the others.

On Salesforce, events are platform events (custom events defined as `__e` objects) and change data capture events (changes to records, published by the platform). Subscribers can be Apex triggers, flows, Lightning Web Components, and systems outside Salesforce.

The same idea applies inside a Lightning Web Component page, where components announce what happened with custom events. See [Component-Driven Architecture](./LWC_STYLE_GUIDE.md#component-driven-architecture).

[Back to Contents](#contents)

## When to Use Events

#### Use when
* Work should happen after a transaction commits, in a separate transaction, without the producer waiting for it
* Several parts of the system react to the same fact, and the producer should not need to know about each of them
* Another system needs to know that something happened in Salesforce, or Salesforce needs to know that something happened in another system
* A record of what happened must survive a rollback, such as an error log

#### Avoid when
* The caller needs the result to continue. Call the class directly
* The work must happen in the same transaction, or must succeed or fail together with it
* The steps must run in a strict order across producers. Events from different transactions do not arrive in a guaranteed order
* There is one producer and one consumer in the same code base, and they always change together. An event only adds indirection

An event makes the flow of the code harder to follow, because a reader cannot see from the producer what happens next. Use one when decoupling is worth that cost.

[Back to Contents](#contents)

## Designing Events

#### Name events for what happened
An event is a fact, named in the past tense: `InvoicePaid__e`, `ShipmentDelayed__e`. A name like `ProcessInvoice__e` is a command. It tells one consumer what to do, and couples the producer to it.

#### Carry the facts consumers need
An event carries the Ids of the records involved and the facts as they were when it happened: `InvoiceId__c`, `PaidAmount__c`, `PaidDate__c`. Consumers that need more query for it. An event that carries only an Id forces every consumer to query, and the record may have changed by the time it does.

#### Publish one fact per event
An event that means different things depending on a status field is several events sharing a name. Each consumer then has to know every meaning.

#### Choose when the event is published
Each platform event's definition sets its publish behavior:

* **Publish After Commit:** the event is published only if the transaction succeeds. Use this for business facts, so consumers never react to something that was rolled back
* **Publish Immediately:** the event is published when the code publishes it, even if the transaction later fails. Use this for logging and monitoring, where the record of a failure must survive it

[Back to Contents](#contents)

## Publishing Events

#### Publish through an adapter
`EventBus.publish` is a platform API. Wrap it behind an interface the code owns, as described in [Adapter](./DESIGN_PATTERNS_GUIDE.md#adapter), so that services do not depend on the event bus and unit tests can replace it.

```java
public interface EventPublisherInterface {
	void publish(List<SObject> events);
}
```

```java
public with sharing class EventBusPublisher implements EventPublisherInterface {

	public void publish(List<SObject> events) {
		List<Database.SaveResult> results = EventBus.publish(events);

		for (Database.SaveResult result : results) {
			throwIfFailed(result);
		}
	}

	private void throwIfFailed(Database.SaveResult result) {
		if (!result.isSuccess()) {
			throw new EventPublishException(
				'Could not publish an event: ' + result.getErrors()[0].getMessage()
			);
		}
	}
}
```

```java
public class EventPublishException extends Exception {}
```

`EventBus.publish` returns results instead of throwing. The adapter turns a failure into an exception, so a failed publish is never silently ignored. See [Prefer exceptions to error codes](./APEX_STYLE_GUIDE.md#prefer-exceptions-to-error-codes).

#### Publish from the service that owns the fact
The class that makes something true announces it. Its publisher is a static field, so tests can replace it.

```java
public with sharing class InvoicePayment {

	public static EventPublisherInterface eventPublisher = new EventBusPublisher();

	public static void recordPayments(List<Invoice__c> invoices) {
		...
		eventPublisher.publish(buildPaidEvents(invoices));
	}

	private static List<InvoicePaid__e> buildPaidEvents(List<Invoice__c> invoices) {
		List<InvoicePaid__e> events = new List<InvoicePaid__e>();

		for (Invoice__c invoice : invoices) {
			events.add(new InvoicePaid__e(
				InvoiceId__c = invoice.Id,
				PaidAmount__c = invoice.PaidAmount__c,
				PaidDate__c = invoice.PaidDate__c
			));
		}

		return events;
	}
}
```

Publish events in bulk, one call for the whole list, as with DML.

[Back to Contents](#contents)

## Subscribing to Events

#### Keep logic out of event triggers
A platform event trigger follows the same rules as any other trigger. See [Triggers](./APEX_STYLE_GUIDE.md#triggers). Event triggers only support `after insert`, so the trigger calls one facade method, and the facade calls the classes that do the work.

```java
trigger InvoicePaidTrigger on InvoicePaid__e (after insert) {
	InvoicePaidTriggerFacade.onAfterInsert(Trigger.new);
}
```

```java
public with sharing class InvoicePaidTriggerFacade {

	public static void onAfterInsert(List<InvoicePaid__e> events) {
		ReceiptCreation.createReceiptsFor(events);
		AccountBalance.reduceBalancesFor(events);
	}
}
```

#### Make subscribers safe to run twice
Retries and replays can deliver the same event more than once. A subscriber checks whether its work is already done before doing it: a receipt is created only if the invoice has none, and a status is set rather than toggled.

#### Expect batches
An event trigger receives up to 2,000 events in one batch by default, more than an object trigger's 200. Bulkify queries and DML the same way.

#### Retry what can succeed later
When a subscriber fails for a reason that may pass, such as a system outside Salesforce being unavailable, throw `EventBus.RetryableException`. The platform runs the batch again later. Limit the number of retries, and record the failure once they run out.

```java
private static final Integer MAX_RETRIES = 4;

...

} catch (BillingSyncException e) {
	if (EventBus.TriggerContext.currentContext().retries < MAX_RETRIES) {
		throw new EventBus.RetryableException(e.getMessage());
	}
	ErrorLog.record(e);
}
```

#### Resume after the last event processed
When a batch fails partway through, events that were already processed should not be processed again. Set a checkpoint after each event, and the trigger resumes after it.

```java
for (InvoicePaid__e event : events) {
	...
	EventBus.TriggerContext.currentContext().setResumeCheckpoint(event.ReplayId);
}
```

#### Know which user runs the subscriber
Event triggers run as the Automated Process user, not as the user who published the event. To run them as a specific user, or with a different batch size, deploy a `PlatformEventSubscriberConfig` for the trigger. The running user needs the permissions the subscriber's work requires.

[Back to Contents](#contents)

## Change Data Capture

#### Use when
* The fact consumers care about is that a record was created, changed, deleted, or restored, with no more meaning than that
* A system outside Salesforce keeps a copy of records in step

#### Avoid when
* The event has business meaning. "The invoice was paid" is not the same fact as "the invoice's status changed." Publish a platform event named for it

Change events are named for the object: `AccountChangeEvent`, `Invoice__ChangeEvent`. Their `ChangeEventHeader` holds the change type, the Ids of the changed records, and the names of the changed fields. A subscriber checks the changed fields before doing work, so that unrelated changes are ignored.

[Back to Contents](#contents)

## Subscribing in Lightning Web Components
A component subscribes to an event channel with `lightning/empApi`, ignores events for other records, and unsubscribes in `disconnectedCallback`. The [Agentforce Guide](./AGENTFORCE_GUIDE.md#refresh-open-pages-after-a-change) shows a component refreshing itself after an agent action changes its record.

[Back to Contents](#contents)

## Testing Events

#### Unit tests replace the publisher
A unit test replaces the publisher with a mock and checks what was published, without the event bus.

```java
@IsTest
public class EventPublisherMock implements EventPublisherInterface {

	public List<SObject> publishedEvents = new List<SObject>();

	public void publish(List<SObject> events) {
		publishedEvents.addAll(events);
	}
}
```

```java
@isTest
static void recordPayments_givenPaidInvoice_shouldPublishInvoicePaid() {
	EventPublisherMock publisherMock = new EventPublisherMock();
	InvoicePayment.eventPublisher = publisherMock;

	InvoicePayment.recordPayments(new List<Invoice__c>{ buildPaidInvoice() });

	Assert.areEqual(1, publisherMock.publishedEvents.size(), 'One event should be published for one paid invoice');
}
```

#### Subscriber classes are tested directly
The subscriber's classes take a list of events, so a unit test builds the events in memory and calls the class directly.

#### Integration tests deliver real events
An integration test uses the real publisher and checks that the subscriber ran. Published events are delivered when `Test.stopTest()` is called, or immediately with `Test.getEventBus().deliver()`. See [Test boundaries with integration tests](./UNIT_TEST_GUIDE.md#test-boundaries-with-integration-tests).

[Back to Contents](#contents)
