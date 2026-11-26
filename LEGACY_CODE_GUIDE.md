# Legacy Code Guide

This guide applies the ideas of *Working Effectively with Legacy Code* by Michael C. Feathers to Salesforce development. The rest of this repository describes what clean code looks like. This guide describes how to change code that does not look like that yet, safely and a little at a time. The book explains each technique in full, and is worth reading alongside this guide.

## Contents
1. [What Legacy Code Is](#what-legacy-code-is)
2. [Cover, Then Modify](#cover-then-modify)
3. [Characterization Tests](#characterization-tests)
4. [Seams in Apex](#seams-in-apex)
5. [Breaking Dependencies](#breaking-dependencies)
6. [Sprout Method and Sprout Class](#sprout-method-and-sprout-class)
7. [Wrap Method and Wrap Class](#wrap-method-and-wrap-class)
8. [Moving a Trigger to a Facade](#moving-a-trigger-to-a-facade)
9. [When to Leave Code Alone](#when-to-leave-code-alone)

## What Legacy Code Is
Legacy code is code without tests. Age has nothing to do with it: a class written last week with no tests is legacy code, and a ten-year-old class with good tests is not.

Without tests, nobody can tell whether a change broke something until a user finds out. That is what makes legacy code hard to change, not how it is written.

#### Coverage is not testing
Salesforce requires 75% code coverage to deploy, so most orgs have tests for every class. Many of them only run the code: they call a method and assert nothing, or assert something that is always true. Code covered only by tests like these is legacy code. A test protects behavior only if it fails when the behavior changes.

```java
// AVOID - runs the code, protects nothing
@isTest
static void testApplyDiscounts() {
	List<Opportunity> opportunities = TestDataFactory.createOpportunities(5);
	OpportunityDiscountService.applyDiscounts(opportunities);
	System.assert(true);
}
```

[Back to Contents](#contents)

## Cover, Then Modify
Changing untested code and checking the result by hand is editing and hoping. Changing it safely follows these steps:

1. **Find the change points:** the places in the code that the change affects
2. **Find the test points:** where a test can observe the behavior around those places
3. **Break dependencies** that stop a test from running the code. See [Breaking Dependencies](#breaking-dependencies)
4. **Write characterization tests** for the current behavior. See [Characterization Tests](#characterization-tests)
5. **Make the change,** test first, then refactor with the tests protecting it

Steps 3 and 4 are done only for the code being changed. Covering an entire class before changing one method is a project, not a change.

[Back to Contents](#contents)

## Characterization Tests
A characterization test records what the code does today, whether or not that is correct. It does not describe what the code should do. Its job is to fail if a change alters existing behavior without meaning to.

#### Writing one
1. Call the code with a realistic input
2. Write an assertion that you expect to fail, such as an empty value
3. Run the test, and read the actual value from the failure
4. Put the actual value in the assertion, and run it again to see it pass

```java
@isTest
static void applyDiscounts_givenPartnerOpportunityOverThreshold_currentlySetsFifteenPercent() {
	Opportunity partnerOpportunity = new Opportunity(
		Name = 'Partner Renewal',
		StageName = 'Prospecting',
		CloseDate = Date.today().addDays(30),
		Amount = 150000,
		CustomerType__c = 'Partner'
	);

	OpportunityDiscountService.applyDiscounts(new List<Opportunity>{ partnerOpportunity });

	Assert.areEqual(15, partnerOpportunity.DiscountPercent__c, 'Records current behavior for partner opportunities over the threshold');
}
```

#### When the current behavior is wrong
A characterization test can reveal a bug. Do not fix it in the same change. Leave the test recording the current behavior, and raise the bug. Other code, reports, or users may depend on the behavior, and fixing it is its own decision.

#### Naming
The name says the test records current behavior, so a reader does not mistake it for a requirement. Use `currently` in place of `should`: `methodUnderTest_testCondition_currentlyExpectedResult`. Rename it to `should` once the behavior is confirmed as correct.

[Back to Contents](#contents)

## Seams in Apex
A seam is a place where a test can change what the code does without editing the code there. A class is testable when its dependencies sit behind seams.

The seams available in Apex:

* **An interface held in a static field:** the test assigns a mock. This is how the [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md) and the [Adapter](./DESIGN_PATTERNS_GUIDE.md#adapter) pattern work
* **A parameter:** the test passes the records or values the method would otherwise query or build
* **`Test.setMock`:** for HTTP callouts
* **`@TestVisible`:** for a private static field that holds a dependency, so a test can replace it. Not for private methods. See [Test behavior, not implementation](./UNIT_TEST_GUIDE.md#test-behavior-not-implementation)

#### `Test.isRunningTest()` is not a seam
Code that checks `Test.isRunningTest()` behaves differently in tests than in production, so the tests prove nothing about production. Replace the check with one of the seams above.

```java
// AVOID - the test runs different code from production
if (!Test.isRunningTest()) {
	BillingSystemClient.sendInvoices(invoices);
}
```

[Back to Contents](#contents)

## Breaking Dependencies
A dependency stops a test when the code reaches something the test cannot control: a query, DML, a callout, or another class's static method. Break only the dependencies that stand between the test and the code being changed.

Each step below is a small, mechanical edit. Make it before writing new behavior, and check that existing tests still pass.

#### Move the query into a data accessor
```java
// BEFORE
public static void applyDiscounts(Set<Id> opportunityIds) {
	List<Opportunity> opportunities = [
		SELECT Id
			, Amount
			, CustomerType__c
		FROM Opportunity
		WHERE Id IN :opportunityIds
	];
	...
}

// AFTER
public static OpportunityDAO opportunityAccessor = new OpportunityDataAccessor();

public static void applyDiscounts(Set<Id> opportunityIds) {
	List<Opportunity> opportunities = opportunityAccessor.getOpportunitiesByIds(opportunityIds);
	...
}
```

The query moves unchanged, so the behavior does not change. A test can now assign a mock to `opportunityAccessor`. See [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md).

#### Pass in what the method needs
When a method queries records only to work on them, have the caller pass the records instead. The method then works on any records a test builds in memory.

```java
// BEFORE
public static void applyDiscounts(Set<Id> opportunityIds) { ... }

// AFTER
public static void applyDiscounts(List<Opportunity> opportunities) { ... }
```

#### Extract an interface
When the code calls another class directly, extract an interface from that class, hold it in a static field, and call it through the field. A test assigns a mock. See [Adapter](./DESIGN_PATTERNS_GUIDE.md#adapter).

[Back to Contents](#contents)

## Sprout Method and Sprout Class
When new behavior must be added to code that has no tests, write the new behavior as new code, with tests, and call it from the old code with one line. The old code is not covered, but the new code is, and the change to the old code is small enough to check by reading.

#### Sprout method
Use when the new behavior fits in the existing class, and the existing public method can be tested. Test the new behavior through the public method.

```java
public static void applyDiscounts(List<Opportunity> opportunities) {
	// existing, untested logic
	...
	assignApprovalRequirements(opportunities);
}

private static void assignApprovalRequirements(List<Opportunity> opportunities) {
	for (Opportunity opportunity : opportunities) {
		opportunity.RequiresApproval__c = opportunity.DiscountPercent__c > MAX_UNAPPROVED_DISCOUNT;
	}
}
```

#### Sprout class
Use when the existing public method cannot be tested without breaking too many dependencies, or when the new behavior is its own responsibility. Do not make a sprouted private method `@TestVisible` to test it directly. Sprout a class instead. The new class follows every standard in this repository, whatever the old class looks like.

```java
public static void applyDiscounts(List<Opportunity> opportunities) {
	// existing, untested logic
	...
	DiscountApproval.assignApprovalRequirements(opportunities);
}
```

`DiscountApproval` is a new class with its own unit tests.

[Back to Contents](#contents)

## Wrap Method and Wrap Class
When new behavior must happen before or after existing behavior, rather than inside it, wrap the existing code instead of editing it.

#### Wrap method
Rename the existing method for what it actually does, and create a method with the original name that calls it along with the new behavior. Callers do not change.

```java
// BEFORE
public static void sendInvoices(List<Invoice__c> invoices) {
	// existing, untested logic
}

// AFTER
public static void sendInvoices(List<Invoice__c> invoices) {
	transmitInvoices(invoices);
	markInvoicesAsSent(invoices);
}

private static void transmitInvoices(List<Invoice__c> invoices) {
	// existing, untested logic, unchanged
}

private static void markInvoicesAsSent(List<Invoice__c> invoices) {
	...
}
```

#### Wrap class
When the existing class sits behind an interface, write a new class that implements the same interface, holds the existing class, and adds the new behavior around its calls. Assign the new class where the old one was used. See [Adapter](./DESIGN_PATTERNS_GUIDE.md#adapter).

[Back to Contents](#contents)

## Moving a Trigger to a Facade
A trigger with logic written inside it can be moved to the [trigger standard](./APEX_STYLE_GUIDE.md#triggers) one event at a time, with each step deployable on its own.

#### Before
```java
trigger OpportunityTrigger on Opportunity (before update, after insert) {
	if (Trigger.isBefore && Trigger.isUpdate) {
		for (Opportunity opportunity : Trigger.new) {
			// discount logic
		}
	}
	if (Trigger.isAfter && Trigger.isInsert) {
		// task creation logic
	}
}
```

#### Steps
1. **Characterize the trigger.** Write integration tests that insert and update records and assert the results. A trigger is a boundary, so these are integration tests. See [Unit Tests and Integration Tests](./UNIT_TEST_GUIDE.md#unit-tests-and-integration-tests)
2. **Add the switch and the facade, and move one event.** Move the logic for one event into a facade method unchanged. Leave the other events where they are
3. **Run the characterization tests.** They pass, because the behavior did not change
4. **Repeat** for each remaining event
5. **Refactor inside the facade,** one method at a time, into services with unit tests. The characterization tests protect each step

#### After the first event is moved
```java
trigger OpportunityTrigger on Opportunity (before update, after insert) {
	switch on Trigger.operationType {
		when BEFORE_UPDATE {
			OpportunityTriggerFacade.onBeforeUpdate(Trigger.new, Trigger.oldMap);
		}
		when AFTER_INSERT {
			// task creation logic, not yet moved
		}
	}
}
```

[Back to Contents](#contents)

## When to Leave Code Alone
* **Code that is not changing** stays as it is, however it looks. It is not covered or refactored until a change needs it
* **Refactor only the code the change touches,** and leave that code cleaner than it was. A change that also rewrites unrelated code is harder to review and riskier to deploy
* **Keep an existing class's API version** unless the change is to move it. A class's API version controls how the platform runs it, so changing it can change behavior with no change to the code
* **Match the existing code's conventions** when extending it, such as the naming of fields on an existing object. New classes and objects follow this repository's standards

[Back to Contents](#contents)
