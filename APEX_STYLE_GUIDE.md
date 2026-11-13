# Apex Style Guide

## Contents
1. [Naming Conventions](#naming)
	* General Naming Rules
	* Classes
	* Interfaces
	* Variables
	* Properties
	* Methods
	* Visualforce Pages & Components
	* Files
2. [Formatting](#formatting)
	* Braces
	* Indentation
	* Line Wrapping
	* Methods
	* Code Blocks
	* Queries
	* Vertical Formatting
3. [Comments](#comments)
4. [Code Style](#code-style)
	* Class Layout
	* Methods
	* Triggers
	* Apex Classes
	* Asynchronous Apex
	* SOQL Queries
5. [Objects and Data Structures](#objects-and-data-structures)
6. [Exceptions](#exceptions)
7. [Security](#security)

## Naming
Names are the primary way code communicates intent.  If a name requires a comment to explain what it does, it is not a clean name.

Appropriate naming helps us glean useful information quickly.  Conventions facilitate self-documenting code that improves readability and consistency.

Look at the example below and try to determine the purpose of the method.
```java
public List<List<Integer>> getThem() {
	List<List<Integer>> list1 = new List<List<Integer>>();
	for (List<Integer> x : theList) {
		if (x.get(0) == 4) {
			list1.add(x);
		}
	}
	return list1;
}
```

What were you able to infer about the purpose of the code above?  Now look at the same example that follows naming conventions
```java
public List<List<Integer>> getFlaggedCells() {
	List<List<Integer>> flaggedCells = new List<List<Integer>>();
	for (List<Integer> cell : gameBoard) {
		if (cell[STATUS_VALUE] == FLAGGED) {
			flaggedCells.add(cell);
		}
	}
	return flaggedCells;
}
```

The method name of the second example not only allows us to quickly determine the purpose of the method, but we can also guess what kind of application it belongs to (looks like minesweeper to me).

[Back to Contents](#contents)

#### General Naming Rules
###### Use Intention-Revealing Names

* A name answers why it exists, what it does, and how it is used: `elapsedTimeInDays`, not `d` or `theList`
* Naming is hard, but taking the time to choose a name that describes exactly what you are naming saves time for you and all others to come in the future
* The name should speak for itself. If the name requires a comment to further explain the intent, the name needs to be revised
* Do not be afraid of renaming if you think of a better, more descriptive one in the future (modern editors make this renaming a trivial task)

###### Avoid Disinformation
A name must not suggest something the code does not do.

* Do not call a collection `accountList` unless it is a `List`. `accounts` says enough.
* A method named `sendVerificationEmail` must send an email. If it only marks a field, name it for that.
* Avoid names that differ only slightly, such as `ContactEmailValidator` and `ContactEmailValidation`.

###### Make Meaningful Distinctions

Distinguish names so that the reader knows what the differences are.  For example, the class names `PersonInfo` and `PersonData` have different names, but the names don't _mean_ anything different.  Do not create noisy variations just to get code to compile, such as `Customer` and `CustomerObject`.

###### Use Pronounceable Names
We write code for humans to read, so make sure humans can discuss it with our spoken language.
```java
// BAD
private DateTime genymdhms;
// GOOD
private DateTime generationTimestamp;
```

###### Use Searchable Names
* Names should be easy to locate across a body of text.
* Replace magic numbers with named constants: `MAX_RETRY_COUNT`, not `3`.
* The length of a variable's name should correspond to the size of its scope. Single letters such as `i` are acceptable only for counters in tiny loops; a variable used across a class needs a long, descriptive name.
* The rule is inverted for methods. A widely used, high-level method has a short name because it is called everywhere, such as `save`. A small private helper can have a longer, more descriptive name, such as `removeContactsWithoutEmail`.

###### Avoid Encodings
Encoding type or scope information into names only adds to the burden of deciphering intent.  They are a mental burden, rarely pronounceable, and easy to mistype.  Do not use type prefixes or Hungarian notation: `name`, not `nameString` or `strName`.

###### Avoid Mental Mapping
Readers should not have to translate a name into the concept it stands for.  A variable named `r` that holds the URL without the host forces every reader to remember that mapping; `urlPath` does not.

###### Don't Be Cute
Don't try to be clever or funny with your names.  The humor will disappear very quickly when somebody is trying to quickly decipher your code in order to fix an issue.

###### Pick One Word per Concept
Pick and use one word for an abstract concept and stick with it.  For example, what is the difference between _fetch_, _retrieve_, and _get_?

###### Don't Pun
Do not use the same word for two different ideas.  If `add` inserts a record in one class, a method that joins two strings should be named `append` or `concatenate`, not `add`.

###### Use Solution Domain Names
The people who read code are programmers, so use computer science terms, algorithm names, and pattern names when a class is that thing: `PricingPolicyFactory`, `AccountRatingQueueable`, `ContactTriggerFacade`.  The [Design Patterns Guide](./DESIGN_PATTERNS_GUIDE.md) describes the common patterns.

###### Use Problem Domain Names
When there is no technical term for what the code does, use the name the business uses, such as `RenewalOpportunity` or `ServiceTerritory`.  A maintainer can then ask a domain expert what it means.

###### Add Meaningful Context
A name that is unclear on its own gets its context from the class or method around it.  `state` is clear inside an `Address` class; as a loose variable in a long method, `addressState` says what it is.

###### Don't Add Gratuitous Context
* Shorter names are generally better than longer ones, as long as they are clear
* Add no more to the name than is necessary

[Back to Contents](#contents)

#### Naming Classes
* Class names should be in pascal case
	* They should start with a capitalized letter
	* The first letter of all subsequent words should be capitalized
* Should have noun or noun phrase names like User, Customer, AddressParser
* DO NOT use words like Manager, Processor, Data or Info, they do not add anything to describing the purpose of the class, and often hint that the class is doing too many things
* Avoid words that hide what a class does, such as Wrapper, Helper, or Util. A class that pairs an Account with a checkbox could be called SelectableAccount instead of AccountWrapper
* Use a pattern name when the class is that pattern, as described in [Use Solution Domain Names](#use-solution-domain-names)
* Only use alpha characters

**Classes with `@AuraEnabled` methods should end with the word _Controller_**

**Classes that expose REST or SOAP web services should end with the word _Service_**

**Classes that hold business logic are named for what they do, such as `AccountRating` or `CaseSummary`**

Some teams instead end business logic classes with _Service_ and give web service classes another suffix, such as _RestResource_.  Either convention works when it is applied consistently.

**Trigger classes should be named the object they are triggers for, and should end with _Trigger_**

**Test classes should be named the same as the class they are testing, with _Test_ at the end**

#### Naming Interfaces
* Follow the same rules as classes, except put _Interface_ at the end
* Data access interfaces in the [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md) end with _DAO_ instead, such as `AccountDAO`

#### Naming Variables
> You should name a variable using the same care with which you name a first-born child - _Robert C. Martin_

* Variables are named using camel case
* Avoid abbreviations (other than common ones like Id, app, org, etc...)
* Common acronyms can be used (ssn, dob, DB)
* Variable types in the name are not necessary (don't do `stringAlertMessage`, or `intErrorCount`)
* Booleans should be named to let you know that it is a boolean (`hasErrors`, `isFull`, etc...)
* Booleans use positive phrasing: `isEnabled`, not `isDisabled`
* The name should be long enough to describe its intent
	* The only exception to this is a variable in a very small scope, so in a small for loop for example
* Distinguish between single objects and collections (`selectedAccount` vs `selectedAccounts`)
* Constants get named in all uppercase with an _ between each word `SOME_CONSTANT`

#### Naming Properties
* Properties are named using pascal case
	* They should start with a capitalized letter
	* The first letter of all subsequent words should be capitalized
* Follow the guidelines in naming variables for the other rules

```java
public String AccountName {get; set;}
```

#### Naming Methods
* Method names should be in camel case
	* They should start with a lower-case letter
	* The first letter of all subsequent words should be capitalized
* Method names are verbs or verb phrases, such as `postPayment`, `deletePage`, or `save`, and follow one of the patterns below
	* verb-Noun or verb-Noun-How (getUsers, getAccountsByOwnerId)
	* Verb-adj-noun (getSelectedUsers, hasSelectedItems)
	* Verb-adj (isDeleted) Boolean returns always use present tense states of being: is, has, are, etc
* Accessors, mutators, and predicates should be named for their value and prefixed with _get_, _set_, and _is_ 
* Test methods should follow this syntax: `methodUnderTest_testCondition_expectedResult`
```java
// Method under test, in the Greeter class
public static String createIndividualizedGreeting(String name) {
	return 'Hello, ' + name;
}

// Test method
@isTest
static void createIndividualizedGreeting_givenName_shouldAppendNameToTheEndOfGreeting() {
	String greeting = Greeter.createIndividualizedGreeting('Gob');
	Assert.areEqual('Hello, Gob', greeting);
}
```

#### Naming Visualforce Pages & Components (Visualforce era)
* Follow the same rules as classes, so `CustomerAccountDetails`, or `SearchAccounts`
* Follow the rules for variables above when naming apex tags and their attributes

#### Naming Files
* for the most part, the file name should reflect the name of your class
* in a Salesforce DX project, group related files into folders under the package directory, such as `force-app/main/default/classes/accounts/`
* prefix related names consistently, such as `AccountController`, `AccountDAO`, and `AccountDataAccessor`, so they also sort together in Setup, which has no folders

[Back to Contents](#contents)

## Formatting

#### Braces

##### Opening Braces
* The opening brace "{" for the classes/interfaces, methods or any other code blocks (if/else, while, for, try/catch, etc) should begin at the end of the same line as the construct
* Leave a space before the opening brace
* Closing braces should start on a new line indented to match the corresponding opening statement
```java
public void showWhereBracesGo() {
	// some stuff
}
```

##### Braces for Property getter and setter methods
* Property declarations with default get and set methods should include opening and closing braces on the same line as the declaration
```java
public String Name { get; set; }
```
* Properties with more complicated getters and setters should follow the braces rules above
```java
private String privateName;
public String Name {
	get {
		if (someCondition) {
			return privateName;
		} else {
			return 'Gob';
		}
	}
	set {
		if (someOtherCondition) {
			privateName = value;
		} else {
			privateName = 'Michael';
		}
	}
}
```

##### Braces for single line blocks
if, while, and for statements should always use braces, even if they have a single statement
```java
// GOOD
if (someCondition) {
	return 'Gob';
}

// BAD
if (someCondition)
	return 'Gob';
```

##### Indentation
Indentation should use tabs, not spaces and tab size should equal 4 spaces

##### Line Wrapping
When an expression is hard to read on a single line, break it according to these general principles:
* Break before an operator
* Break after a comma
* Prefer higher-level breaks to lower-level breaks
* Indent at least once after the break
```java
// GOOD
someReallyReallyLongName = someOtherLongVariableName
	* (someLongName + someOtherVariable - thirdLongVariable)
	+ 4 * someBigMultiplier;

// BAD
// Hard to read on one line
someReallyReallyLongName = someOtherLongVariableName * (someLongName + someOtherVariable - thirdLongVariable) + 4 * someBigMultiplier;

// No Indent
someReallyReallyLongName = someOtherLongVariableName * (someLongName + 
someOtherVariable - thirdLongVariable) + 4 * someBigMultiplier;

// Breaks inside the parens, too low level
// Also broke after the + operator
someReallyReallyLongName = someOtherLongVariableName * (someLongName + 
		someOtherVariable - thirdLongVariable) + 4 * someBigMultiplier;
```

#### Formatting Methods
Methods should have no space between the method name and the params `(` and then one space between the ending `)` and the beginning `{`
```java
public void updateContact(Contact contactToUpdate) {
	...
}
```

One thing to note about methods is that they should be kept as small as they need to be.  Methods should have only 1 responsibility, so if you 
start to see your method going over around 5 lines of logic start to prepare for some refactoring. Methods should also accept no more than 3 arguments. Using more than 3 arguments is an indication that your method is doing too much. Methods should avoid using Booleans as arguments. It is much better to evaluate the boolean and call two different methods based on the boolean value. This enforces single responsibility principles.

#### Formatting Code Blocks
The only real rule for formatting code blocks is to try to keep them short, and only 1 level of indentation.  Having deep nesting in your code blocks makes it difficult to read, it also screams that your code block/method is doing a little too much. 
Split that deeper nested logic out into some well-named private methods.

```java
// GOOD
for (Integer i = 0; i < 20; i++) {
	if (i > 10) {
		handleLargerThanTen();
	} else {
		handleLessThanTen();
	}
}

// AVOID
for (Integer i = 0; i < 20; i++) {
	if (i > 10) {
		if (i % 2 == 0) {
			// do something w/ even #s
		} else {
			// do something else
		}
	} else {
		if (i % 3 == 0) {
			// do some stuff
		} else {
			// do some other stuff
		}
	}
}
```

#### Formatting Queries
##### SOQL
Your SOQL queries should adhere to the following rules:
* Keywords are all capital letters, `SELECT`, `FROM`, `WHERE`
* The opening bracket ends the line, the query starts on the next line indented once, and the closing bracket goes on its own line
* One field per line, with the comma before each field after the first. The first field goes after `SELECT`, and each following field goes on a new line indented one level past `SELECT`
* `FROM`, `WHERE`, `ORDER BY`, and `LIMIT` line up with `SELECT`
* Any `AND` or `OR` keywords get an indent
* Sub-selects get indented one level
```sql
// Good, easy to read, easy to modify
List<Person__c> peopleNamedGob = [
	SELECT Id
		, FirstName__c
		, LastName__c
		, FavoriteColor__c
	FROM Person__c
	WHERE FirstName__c = 'Gob'
		AND LastName__c = 'Bluth'
];

// This is very hard to read, and too long, nobody wants to have to scroll to read the entire query
List<Person__c> peopleNamedGob = [SELECT Id, FirstName__c, LastName__c, FavoriteColor__c FROM Person__c WHERE FirstName__c = 'Gob' AND LastName__c = 'Bluth'];
```

A short list of fields may stay on the `SELECT` line as long as it is easy to read. When the line gets too long, continue the list on a new line indented one level past `SELECT`.
```sql
List<Person__c> peopleNamedGob = [
	SELECT Id, FirstName__c, LastName__c
	FROM Person__c
	WHERE FirstName__c = 'Gob'
];
```

#### Vertical Formatting
* Separate concepts with a blank line: between methods, and between groups of statements in a method that do different things
* Keep lines that belong to one thought together, with no blank lines between them
* Declare a local variable close to where it is first used
* Place a method that calls another above the method it calls, as described in [Class Layout](#class-layout)

[Back to Contents](#contents)

## Comments
> Every time you write a comment, you should grimace and feel the failure of your ability of expression - _Robert C. Martin_

Comments should be used to explain things the code cannot explain on its own, such as the reasoning behind complex business logic.  Comments should not describe what your code is doing, if you need to leave a comment explaining what your code is doing, you need to refactor your code to make it more readable.  

Code does not lie, comments do.  When code changes, but the comments do not, the comment is now a lie. This happens all the time. Don't be a purveyor of lies.

Methods should be named well enough to not need comments.  If you need a comment saying what your method is doing, you either have a name that isn't descriptive enough, or your method is doing too much.

The comments that do belong in code are:
* Legal and copyright notices
* Documentation of public interfaces that other code depends on, such as ApexDoc on a shared business logic class or the descriptions of an invocable action
* Warnings of consequences, such as why a class runs `without sharing`
* `TODO` notes that reference a work item

The comments that do not belong in code are:

| Comment | Instead |
|---|---|
| Change logs at the top of a class: dates, ticket numbers, and a description of each change | Commit messages. Source control holds the history |
| Attributions, such as `// Added by J. Smith 2019` | Source control records who changed each line |
| Commented-out code | Delete it. Source control remembers it |
| Header blocks required on every class or method that restate its name, parameters, and return type | A clear name. Document only the public interfaces other code depends on |
| Comments that repeat the code, such as `// update the account` above `update account;` | Nothing |
| Banners, such as `// ***** HELPERS *****`, and comments after closing braces, such as `} // end for` | Classes and methods small enough not to need landmarks |

[Back to Contents](#contents)

## Code Style

#### Class Layout
Order the members of a class from top to bottom:
1. Constants
2. Static variables
3. Instance variables and properties
4. Constructors
5. Public methods
6. Private methods, each placed below the method that first calls it
7. Inner classes

A class then reads from top to bottom like a newspaper article: the high-level methods first, and the details below the methods that use them.

Keep related methods together within each group.  A set of methods that only call each other and share no data with the rest of the class is often a new class hiding in the existing one.

[Back to Contents](#contents)

#### Methods
##### Do one thing, with no side effects
A method does what its name says and nothing else. A method named `isEligible` does not change a field, send an email, or write to the database.

##### One level of abstraction per method
Every statement in a method is at the same level of abstraction.  A method that mixes high-level steps with low-level detail makes the reader switch between them.  Move the detail into a method named for what it does, one level down.
```java
// AVOID - one high-level step, then string parsing, then DML
public void submitOrder(Order submittedOrder) {
	validate(submittedOrder);
	String postalPrefix = submittedOrder.ShippingPostalCode.left(2);
	submittedOrder.Region__c = WEST_POSTAL_PREFIXES.contains(postalPrefix) ? 'West' : 'East';
	orderAccessor.updateRecords(new List<Order>{ submittedOrder });
}

// GOOD - each line is one step at the same level
public void submitOrder(Order submittedOrder) {
	validate(submittedOrder);
	assignRegion(submittedOrder);
	save(submittedOrder);
}
```

The methods then follow the stepdown rule: each method is followed by the methods at the next level down, so the class reads from top to bottom.

##### Separate commands from queries
A method either changes something (a command) or answers something (a query), never both.
```java
// AVOID - answers a question and changes state
public Boolean reserveSeat(Seat requestedSeat) {
	...
}

// GOOD
public Boolean isSeatAvailable(Seat requestedSeat) {
	...
}

public void reserveSeat(Seat requestedSeat) {
	...
}
```

##### Do not return null
Return an empty collection instead of `null`. When a single record must exist and does not, throw an exception. Do not pass `null` to mean "no value"; write a separate method instead.
```java
// AVOID
public List<Contact> getContactsByAccountId(Id accountId) {
	if (accountId == null) {
		return null;
	}
	...
}

// GOOD
public List<Contact> getContactsByAccountId(Id accountId) {
	if (accountId == null) {
		return new List<Contact>();
	}
	...
}
```

##### Replace repeated switch statements with polymorphism
A `switch` on a type, such as a record type or an account type, tends to appear wherever that type matters.  Every new type then means editing every `switch`.  Put each variation in a class that implements a shared interface, and choose the class in one place.
```java
// AVOID - repeated wherever the account type changes the behavior
switch on customerAccount.Type {
	when 'Partner' {
		discount = calculateVolumeDiscount(orderAmount);
	}
	when else {
		discount = orderAmount * STANDARD_DISCOUNT_RATE;
	}
}
```

```java
// GOOD
public interface PricingPolicyInterface {
	Decimal calculateDiscount(Decimal orderAmount);
}
```

```java
public class PartnerPricingPolicy implements PricingPolicyInterface {
	private static final Decimal VOLUME_THRESHOLD = 100000;
	private static final Decimal BASE_RATE = 0.10;
	private static final Decimal VOLUME_RATE = 0.20;

	public Decimal calculateDiscount(Decimal orderAmount) {
		return orderAmount * rateFor(orderAmount);
	}

	private Decimal rateFor(Decimal orderAmount) {
		return orderAmount >= VOLUME_THRESHOLD ? VOLUME_RATE : BASE_RATE;
	}
}
```

```java
public class PricingPolicyFactory {
	public static PricingPolicyInterface forAccountType(String accountType) {
		PricingPolicyInterface pricingPolicy;

		switch on accountType {
			when 'Partner' {
				pricingPolicy = new PartnerPricingPolicy();
			}
			when else {
				pricingPolicy = new StandardPricingPolicy();
			}
		}

		return pricingPolicy;
	}
}
```

The one remaining `switch` lives in the factory, and a new account type is a new class plus one line there.  The [Design Patterns Guide](./DESIGN_PATTERNS_GUIDE.md) describes these as the Strategy and Factory patterns.

##### Error handling is one thing
A method that handles an error does nothing else.  The `try` block calls one method that does the work, and the method that catches the error only handles it.
```java
private HttpResponse send(HttpRequest request) {
	try {
		return new Http().send(request);
	} catch (CalloutException e) {
		throw new BillingSyncException('Could not reach the billing system.', e);
	}
}
```

##### Do not compare Booleans to true or false
```java
// AVOID
if (isActive == true) {

// GOOD
if (isActive) {
```

Initialize a Boolean where it is declared or built, so it is never `null`.

[Back to Contents](#contents)

#### Triggers
##### Bulkify queries
Always bulkify queries in triggers to avoid hitting governor limits and improve performance.

##### Keep logic out of triggers
A trigger contains no logic.  It hands each event to classes that each do one thing.  The [facade pattern](https://en.wikipedia.org/wiki/Facade_pattern "Description of the Facade Pattern") organizes this: the trigger calls one facade method for each event, and the facade calls the classes that hold the logic.

##### Prevent recursion
Take appropriate measures to prevent unwanted recursive execution of triggers.  For example, updating a record in the `after update` trigger of the same object or a related object could invoke the trigger recursively.  Use `before update` if possible.  When you use `after update` to make changes on the same record, you need to use `update` statement to persist the changes, and that results in firing before/after triggers again.  You can avoid that by using `before update` triggers as you wouldn't then need to use the update statement.

When `after update` is required, track the Ids of the records already processed in a static set rather than a static Boolean flag.  A trigger runs once per batch of 200 records, so a flag set by the first batch skips every batch after it.
```java
public with sharing class AccountRollupRecalculation {

	private static Set<Id> processedAccountIds = new Set<Id>();

	public static void recalculate(List<Account> changedAccounts) {
		List<Account> unprocessedAccounts = new List<Account>();

		for (Account changedAccount : changedAccounts) {
			if (!processedAccountIds.contains(changedAccount.Id)) {
				unprocessedAccounts.add(changedAccount);
			}
		}

		processedAccountIds.addAll(new Map<Id, Account>(unprocessedAccounts).keySet());
		// recalculate unprocessedAccounts
	}
}
```

##### Single trigger for one object
Only create 1 trigger per object.

[Back to Contents](#contents)

#### Apex Classes
##### Do not use asserts in main code
Asserts are for tests, not main code.

##### If statements
Complicated if conditions should go in their own well-named method.

Below is a distracting, difficult to understand if condition.
```java
if (userAccount.IsActive__c && !userAccount.IsInArrears__c && userAccount.Contact.IsCurrent__c) {
	// do some stuff
}
```

Instead, abstract that condition out into a method whose name says what that condition is checking
```java
private Boolean isAccountCurrent(Account userAccount) {
	return userAccount.IsActive__c && !userAccount.IsInArrears__c && userAccount.Contact.IsCurrent__c;
}

public void doSomeStuff(Account userAccount) {
	if (isAccountCurrent(userAccount)) {
		// do some stuff
	}
}
```

Nested if statements should go into their own method.

[Back to Contents](#contents)

#### Asynchronous Apex
##### Prefer Queueable to future methods
Use a `Queueable` class for asynchronous work.  Unlike future methods, a Queueable accepts objects as well as primitives, can chain to another job, returns a job Id that can be monitored, and can attach a `Finalizer` that runs whether the job succeeds or fails.

##### Keep logic out of the asynchronous entry point
Avoid writing logic directly in the `execute` method of a Queueable or in a future method.  Instead, write the logic in a separate class so that it can be used both asynchronously and immediately, and tested without the asynchronous wrapper.
```java
public with sharing class AccountRatingQueueable implements Queueable {

	private Set<Id> accountIds;

	public AccountRatingQueueable(Set<Id> accountIds) {
		this.accountIds = accountIds;
	}

	public void execute(QueueableContext context) {
		System.attachFinalizer(new AccountRatingFinalizer(accountIds));
		AccountRating.recalculate(accountIds);
	}
}
```
```java
public with sharing class AccountRatingFinalizer implements Finalizer {

	private Set<Id> accountIds;

	public AccountRatingFinalizer(Set<Id> accountIds) {
		this.accountIds = accountIds;
	}

	public void execute(FinalizerContext context) {
		if (context.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
			// record the failure for accountIds
		}
	}
}
```

##### Future methods (legacy)
Existing future methods follow the same rule: the future method only calls the method that holds the logic.
```java
@future
public static void updateAccountFuture(Id accountId) {
	updateAccount(accountId);
}

public static void updateAccount(Id accountId) {
	...
}
```

[Back to Contents](#contents)

#### SOQL Queries
* Avoid putting SOQL queries in any sort of loop (for, forEach, while, etc)
* The database access is a responsibility, so it belongs in its own class.  Your method should only have 1 responsibility, database access is not one of them
```java
// Avoid
public void manipulateAccount(Id accountId) {
	Account userAccount = [
		SELECT Id
			, Name
		FROM Account
		WHERE Id = :accountId
	];

	// some if statements and a little object manipulation stuff

	update userAccount;
}
```

So, what happens if we have to select account by its Id multiple times?  We are going to end up with that same SOQL query scattered throughout our code.  

What happens when we add a new field to that object?  We will have to find all of those SOQL queries and update them to return the new field.

If we just centralized that query into its own data accessor class and method, it would be reused throughout our code, and we would only have to make that field update in one place.

Put each query in the data accessor for its object, as described in the [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md).

[Back to Contents](#contents)

## Objects and Data Structures

#### Know which one you are writing
* A **data structure** exposes its data and has no meaningful behavior. SObjects are data structures, and so are the `Request` and `Response` classes of an invocable action and a class that carries data to a Lightning Web Component
* An **object** hides its data and exposes behavior through methods. Business logic classes, controllers, and data accessors are objects

Keep the two apart.  A data structure with business logic, or an object that exposes its internal state as public fields, gets the disadvantages of both: new behavior is hard to add, and so is new data.
```java
// A data structure: fields only
public class ContactSummary {
	@AuraEnabled public Id contactId;
	@AuraEnabled public String name;
	@AuraEnabled public Integer openCaseCount;
}
```

#### The Law of Demeter
A method talks only to its immediate collaborators: its own class, objects it creates, objects passed to it as arguments, and its own fields.  It does not reach through one object to get another and call methods on that.
```java
// AVOID - reaches through three collaborators
PaymentTerms terms = orderBilling.getCustomer(orderId).getBillingProfile().getPaymentTerms();

// GOOD - asks the collaborator for what it needs
PaymentTerms terms = orderBilling.getPaymentTermsByOrderId(orderId);
```

The law applies to objects, not data structures.  Reading SOQL relationship fields, such as `opportunity.Account.Owner.Email`, navigates a data structure and is fine.  Query every field the code reads, and use the safe navigation operator, `opportunity.Account?.Owner?.Email`, where a relationship may be empty.  When the same long relationship path appears in several places, query the field once in the data accessor and name it for what the code needs.

[Back to Contents](#contents)



## Exceptions
Exceptions should always be handled.  You need to catch exceptions at minimum at the highest level of your code before the user gets to it (so usually the controller level).

You should not throw standard exceptions up to the user. Create a custom exception with a user-friendly error message in there.

Exceptions for Visualforce controllers (Visualforce era) should be caught, then added to the PageMessages.

Exceptions thrown from `@AuraEnabled` methods should be an `AuraHandledException` with a friendly error message. Set the message with `setMessage` as well as the constructor, so that `getMessage()` returns it in unit tests. Build these exceptions in one place:
```java
public with sharing class UserFacingError {

	public static AuraHandledException withMessage(String message) {
		AuraHandledException error = new AuraHandledException(message);
		error.setMessage(message);
		return error;
	}
}
```
```java
throw UserFacingError.withMessage('Account ID is required');
```

#### Prefer exceptions to error codes
Do not return a value such as `-1`, `false`, or a status string to signal that something failed. Throw an exception, and catch it in the code that can handle it.
```java
// AVOID
public Integer reserveSeat(Seat requestedSeat) {
	if (!isSeatAvailable(requestedSeat)) {
		return -1;
	}
	...
}

// GOOD
public void reserveSeat(Seat requestedSeat) {
	if (!isSeatAvailable(requestedSeat)) {
		throw new SeatUnavailableException('Seat ' + requestedSeat.Name + ' is already reserved. Choose another seat.');
	}
	...
}
```

#### Never swallow an exception
A caught exception is handled: recovered from, rethrown with context, or recorded where someone will see it, such as a log record or a status field.  Catch the specific exceptions you can handle, not `Exception`.
```java
// AVOID - the failure disappears
try {
	sendInvoices(invoices);
} catch (Exception e) {
	System.debug(e);
}
```

#### Provide context
An exception message says what operation failed and for what.  When rethrowing, pass the original exception as the cause.
```java
throw new BillingSyncException('Could not send ' + invoices.size() + ' invoices to the billing system.', e);
```

#### Define exceptions for the caller's needs
Define exception classes by how the caller responds, not by where the error came from.  When a callout can fail with a `CalloutException`, a `JSONException`, or an error status code, and the caller responds the same way to each, wrap them all in one exception the caller catches.

#### Wrap what you do not own
Callouts, managed package classes, and platform APIs sit behind a class you own.  The rest of the code depends on that class, which turns their errors into your exceptions and can be replaced with a mock in tests.  See [Unit Tests and Integration Tests](./UNIT_TEST_GUIDE.md#unit-tests-and-integration-tests).
```java
public with sharing class BillingSystemClient {

	private static final Integer HTTP_OK = 200;

	public void sendInvoices(List<Invoice__c> invoices) {
		HttpResponse response = send(buildRequest(invoices));

		if (response.getStatusCode() != HTTP_OK) {
			throw new BillingSyncException(
				'The billing system rejected ' + invoices.size() + ' invoices with status ' + response.getStatusCode() + '.'
			);
		}
	}

	private HttpResponse send(HttpRequest request) {
		try {
			return new Http().send(request);
		} catch (CalloutException e) {
			throw new BillingSyncException('Could not reach the billing system.', e);
		}
	}

	private HttpRequest buildRequest(List<Invoice__c> invoices) {
		...
	}
}
```
```java
public class BillingSyncException extends Exception {}
```

#### Write messages for the person reading them
A message shown to a user says what happened and what to do next.

| Avoid | Prefer |
|---|---|
| Invalid date range. | End Date cannot be before Start Date. Choose a later End Date. |
| Required field missing. | Enter a Last Name to save this contact. |

Validation rule messages show next to the field they concern whenever there is one.

[Back to Contents](#contents)

## Security

#### Declare sharing on every class
* Use `with sharing` by default
* Use `inherited sharing` for classes that run in the caller's context, such as data accessors and utilities
* Use `without sharing` only when the class must see records the user cannot, and state the reason in a comment

#### Respect the user's permissions
When an operation must respect the running user's object and field permissions, run it in user mode.
```java
List<Account> accounts = [
	SELECT Id
		, Name
	FROM Account
	WHERE Id IN :accountIds
	WITH USER_MODE
];

Database.insert(newContacts, AccessLevel.USER_MODE);
```

#### Do not hard-code Ids or names
Record Ids, profile names, and usernames differ between orgs. Query by `DeveloperName`, or store the value in custom metadata or a custom label.

#### Do not build queries from input
Never concatenate user input into dynamic SOQL. Use bind variables.
```java
Map<String, Object> bindings = new Map<String, Object>{ 'searchName' => '%' + searchTerm + '%' };
List<Account> accounts = Database.queryWithBinds(
	'SELECT Id, Name FROM Account WHERE Name LIKE :searchName',
	bindings,
	AccessLevel.USER_MODE
);
```

[Back to Contents](#contents)
