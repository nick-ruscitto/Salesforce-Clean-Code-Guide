
# Unit Testing

**Preface:**

Every Salesforce developer should know what a unit test is since they are required for production deployments, however, unit tests are not specific to Salesforce or Apex, they are an industry standard for just about every programming language and should be treated as such. Salesforce requires that 75% of code is covered in unit tests and that those unit tests pass in order
to move code to production. This is good in theory since it forces developers to actually write
the tests, however it has a pretty big side-effect in that many developers treat unit tests as an
afterthought often writing them at the last minute, and writing bad tests just to get the required coverage.

The main purpose of unit tests is to make sure your code works and it’s just as important as
Production code. If there is a bug in production code, the very first step in debugging should
be to run the associated unit tests to ensure they are still passing. A poorly written unit test is
as bad if not worse than no test at all since it could result in false positive or false negative
cases leading a developer to spend unnecessary time digging through the code to solve the
issue.

Unit tests are specific to code so they can not and should not account for every single scenario
that can happen with the application or system. Manual or functional tests are still required to
account for other scenarios outside of the domain of the code itself.

There are a few different strategies for writing unit tests. One popular strategy being Test Driven Development (TDD) where the developer writes the test before they write the production code. This can further be broken down following 3 rules for TDD:

1. Write no production code except to pass a failing test
2. Write only enough of a test to demonstrate a failure
3. Write only enough production code to pass the test

#### TDD in Salesforce
Apex compiles and runs on the server, so every test run is a deploy followed by a run in the org. Apply TDD in units rather than single lines:

1. Write the test for a unit together with the unit it tests
2. Deploy them together and run the test
3. Make the test pass before moving on to the next unit

Mock the database with the [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md) so that each run stays fast.

## F.I.R.S.T

Clean tests follow five rules that form the above acronym:

**Fast:** Tests should be fast. They should run quickly. When tests run slow, you won't want to run them frequently. If you don't run them frequently, you won't find problems early enough to fix them easily. You won't feel as free to clean up the code. Eventually the code will begin to rot.

**Independent:** Tests should not depend on each other. One test should not set up the conditions for the next test. You should be able to run each test independently and run the tests in any order you like. When tests depend on each other, then the first one to fail causes a cascade of downstream failures, making diagnosis difficult and hiding downstream defects.

**Repeatable:** Tests should be repeatable in any environment. You should be able to run the
tests in the production environment, in the QA environment, and on your laptop while riding home on the train without a network. If your tests aren't repeatable in any environment, then you'll always have an excuse for why they fail. You'll also find yourself unable to run the tests when the environment isn't available.


**Self-Validating:** The tests should have a boolean output. Either they pass or fail. You should not have to read through a log file to tell whether the tests pass. You should not have to manually compare two different text files to see whether the tests pass. If the tests aren't self-validating, then failure can become subjective and running the tests can require a long manual evaluation.

**Timely:** The tests need to be written in a timely fashion. Write each unit test together with the production code it tests, and deploy them together. If you write tests after the production code, then you may find the production code to be hard to test. You may decide that some production code is too hard to test. You may not design the production code to be testable.

**What a test should do:**

Remember that the primary reason for unit tests is to make sure the code works and provide
an outlet for easy debugging, NOT to reach a certain coverage % so that you can deploy. Unit
tests should follow the S.O.L.I.D. principles just like production code. And following the Single
Responsibility Principle, a unit test should test one and only one unit of code. Writing clean
production code will usually result in a clean test. If following TDD, writing clean tests will even
more frequently result in clean production code. Take the following code example:

```java
public void changeAccountOwnership(String accountId) {
	Account a = [
		SELECT Id
			, OwnerId
		FROM Account
		WHERE Id = :accountId
	];
	a.OwnerId = UserInfo.getUserId();
	update a;
}
```

Many tests for this would look something like:

```java
@isTest static void testAccount() {
	User u = new User();
	u.FirstName = 'Test';
	//setting required fields
	insert u;

	User u2 = new User();
	u2.FirstName = 'Test2';
	//setting required fields
	insert u2;

	Account a = new Account();
	a.Name = 'Test';
	a.OwnerId = u2.Id;
	//setting required fields
	insert a;

	System.runAs(u) {
		Test.startTest();
			AccountController.changeAccountOwnership(a.Id);
		Test.stopTest();

		Account queriedAccount = [
			SELECT Id
				, OwnerId
			FROM Account
			WHERE Id = :a.Id
		];
		Assert.areEqual(u.Id, queriedAccount.OwnerId);
	}
}
```

There are a few issues with this code; the method `changeAccountOwnership()` is breaking the
Single Responsibility Principle as it is not just responsible for changing the Account owner. It is
also responsible for querying the Account and updating it. Because of this the unit test also
has to worry about setting up data and interacting with the database. What this can result in is
a false negative test run. Let’s assume this code makes its way to production and then a validation rule is added on the User record. This unit test will now fail if not updated properly, but
the failure has nothing to do with the unit under test. Also, every other unit test that creates test Users will also fail. Having possibly hundreds of unit tests failing just because of a simple validation rule can cause a lot of overhead and unnecessary time fixing and deploying unit tests. The unit test also spends a lot of resources just setting up data that could cause these issues. Unless the responsibility of the unit under test specifically interacts with the database, the unit test should not do so. This can cause the test to take longer to run since it needs to create then destroy data, and this problem is exponential as more tests are created this way. Instead, mock objects should be created. This will ensure that the unit test won’t fail unless there is a direct issue with the production code. This will also cause the unit test to run faster since no creation and cleanup is necessary from the backend. The unit test name `testAccount()` is also not descriptive so when a user runs the test and views the output log, it would be difficult to tell what the test is supposed to do.

Let’s take a look at how to write better production code and a better test:

Production Code:
```java
public with sharing class AccountController {

	public static AccountDAO accountAccessor = new AccountDataAccessor();

	public static void changeAccountOwnership(Id accountId) {
		Account account = accountAccessor.getAccountFromId(accountId);
		account.OwnerId = UserInfo.getUserId();
		accountAccessor.updateRecords(new List<Account>{ account });
	}
}
```

Unit Test:

```java
private static Account buildMockAccount(Id ownerId) {
	//MockSObjectBuilder is a class that can generate an SObject using JSON without inserting anything into the database while still allowing the developer to set fields that otherwise are not writable
	MockSObjectBuilder mockBuilder = new MockSObjectBuilder(Account.sObjectType);
	mockBuilder.setField('Id', MockIdGenerator.getMockId(Account.sObjectType));
	mockBuilder.setField('OwnerId', ownerId);

	return (Account) mockBuilder.build();
}

@isTest static void changeAccountOwnership_givenAccount_currentUserShouldBecomeOwner() {
	Id previousOwnerId = MockIdGenerator.getMockId(User.sObjectType);
	Account testAccount = buildMockAccount(previousOwnerId);

	AccountDataAccessorMock accountMock = new AccountDataAccessorMock();
	accountMock.addExistingRecords(new List<Account>{ testAccount });
	AccountController.accountAccessor = accountMock;

	Test.startTest();
		AccountController.changeAccountOwnership(testAccount.Id);
	Test.stopTest();

	Account changedAccount = (Account) accountMock.getRecords()[0];

	Assert.areEqual(UserInfo.getUserId(), changedAccount.OwnerId);
}

@isTest static void changeAccountOwnership_givenUnknownAccount_exceptionShouldBeThrown() {
	AccountController.accountAccessor = new AccountDataAccessorMock();
	Id unknownAccountId = MockIdGenerator.getMockId(Account.sObjectType);

	Boolean exceptionThrown = false;

	Test.startTest();
		try {
			AccountController.changeAccountOwnership(unknownAccountId);
		} catch (QueryException e) {
			exceptionThrown = true;
		}
	Test.stopTest();

	Assert.isTrue(exceptionThrown);
}
```

Much like `@testSetup` methods, the `buildMockAccount()` method creates the mock record so that a database interaction is not needed. This test method now only checks to make sure the method it is testing changes the owner of the Account record. The test methods for the methods in Data Accessor classes should actually run DML and queries across the associated objects to account for backend interactions. This example also shows both a positive and negative test case. Unit tests should cover the full spectrum of possible outcomes of the code, not just what ideally should happen.

**Testing platform features:**

**Asynchronous Apex:** Enqueue the job between `Test.startTest()` and `Test.stopTest()`. Queued jobs, future methods, and their finalizers run when `Test.stopTest()` is called, so assert after it.

```java
Test.startTest();
	System.enqueueJob(new AccountRatingQueueable(accountIds));
Test.stopTest();

Account ratedAccount = [
	SELECT Id
		, Rating
	FROM Account
	WHERE Id IN :accountIds
	LIMIT 1
];
Assert.areEqual('Hot', ratedAccount.Rating);
```

**Callouts:** Unit tests cannot make callouts. Register a mock that returns a fixed response.

```java
Test.setMock(HttpCalloutMock.class, new WeatherServiceCalloutMock());
```

**Platform events:** Published events are delivered when `Test.stopTest()` is called, or immediately with `Test.getEventBus().deliver()`.

**Invocable actions:** Call the invocable method directly with a list of requests, and assert on the list of responses.

```java
CaseSummaryAction.Request request = new CaseSummaryAction.Request();
request.caseId = testCaseId;

List<CaseSummaryAction.Response> responses = CaseSummaryAction.summarizeCases(
	new List<CaseSummaryAction.Request>{ request }
);

Assert.areEqual(1, responses.size());
```

**Prompt templates:** `ConnectApi` cannot be called from a unit test. Replace the class that invokes the template with a mock that returns a fixed response, as described in the [Agentforce Guide](./AGENTFORCE_GUIDE.md#invoke-templates-through-an-interface).

```java
@isTest
public class PromptTemplateInvokerMock implements PromptTemplateInvokerInterface {
	public String response;

	public String invoke(String templateName, Map<String, String> textInputs) {
		return response;
	}
}
```

**Recap:**

- Clean tests are just as important as clean production code
- If your test is too long, your production code is probably too long
- Test methods should test one and only one unit of code
- Tests should handle negative as well as positive cases if applicable
- Mocking should be used to decouple tests from databases
- Database interaction should still happen with unit tests related to DAs so that full functionality is still covered
- Write tests along with the code they test, and deploy them together



