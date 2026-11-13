# Design Patterns Guide

## Contents
1. [Using Patterns](#using-patterns)
2. [Factory](#factory)
3. [Strategy](#strategy)
4. [Builder](#builder)
5. [Facade](#facade)
6. [Adapter](#adapter)

## Using Patterns
A design pattern is a known solution to a problem that keeps recurring. Its name is shared vocabulary: a reader who sees `PricingPolicyFactory` knows what the class does before reading it.

* Use the pattern's name in the class name when the class is that pattern, as described in [Use Solution Domain Names](./APEX_STYLE_GUIDE.md#use-solution-domain-names)
* Introduce a pattern when the problem it solves appears, not before. The fourth rule of simple design is to minimize the number of classes and methods, and a pattern applied without its problem only adds them

[Back to Contents](#contents)

## Factory
Creates the right implementation of an interface in one place, so the code that uses it does not need to know which implementation it has.

#### Use when
* The implementation depends on data, such as a record type, an account type, or a setting
* Tests need to substitute a different implementation

#### Avoid when
* There is only one implementation. Call its constructor

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

A factory usually chooses a [Strategy](#strategy). Its `switch` is the only one in the code that depends on the account type.

[Back to Contents](#contents)

## Strategy
Puts each variation of a behavior in its own class behind a shared interface. The caller works with the interface and does not know which variation it has.

#### Use when
* The same behavior differs by type, and a `switch` or `if` chain on that type would otherwise repeat in several places
* A new variation should be a new class, not an edit to existing classes

#### Avoid when
* The variations differ only in a value, such as a rate or a limit. Store the value in custom metadata and keep one class
* There is only one variation

```java
public interface PricingPolicyInterface {
	Decimal calculateDiscount(Decimal orderAmount);
}
```

```java
public class StandardPricingPolicy implements PricingPolicyInterface {
	private static final Decimal DISCOUNT_RATE = 0.05;

	public Decimal calculateDiscount(Decimal orderAmount) {
		return orderAmount * DISCOUNT_RATE;
	}
}
```

```java
PricingPolicyInterface pricingPolicy = PricingPolicyFactory.forAccountType(customerAccount.Type);
Decimal discount = pricingPolicy.calculateDiscount(orderAmount);
```

The [Apex Style Guide](./APEX_STYLE_GUIDE.md#replace-repeated-switch-statements-with-polymorphism) shows the `switch` statements this replaces.

[Back to Contents](#contents)

## Builder
Builds an object step by step through named methods, so that code creating a complex object reads as a description of it.

#### Use when
* An object has many fields, most of which can take sensible defaults
* The same kind of object is created in many places, such as test records that must satisfy required fields and validation rules
* An object is assembled in steps, such as an HTTP request or a dynamic query

#### Avoid when
* An object has only a few fields. A constructor or a field initializer is clearer

```java
@isTest
public class AccountBuilder {
	private Account account = new Account(
		Name = 'Acme Corporation',
		Type = 'Customer'
	);

	public AccountBuilder withType(String accountType) {
		account.Type = accountType;
		return this;
	}

	public AccountBuilder withAnnualRevenue(Decimal annualRevenue) {
		account.AnnualRevenue = annualRevenue;
		return this;
	}

	public Account build() {
		return account;
	}
}
```

```java
Account partnerAccount = new AccountBuilder()
	.withType('Partner')
	.withAnnualRevenue(5000000)
	.build();
```

When a required field is added to Account, the default goes into the builder, and every test that uses it keeps working. The `MockSObjectBuilder` class in the [DAO Base Framework](./DAO%20Base%20Framework/classes/MockSObjectBuilder.cls) is a builder for mock records.

[Back to Contents](#contents)

## Facade
Gives a set of classes one simple entry point, so callers do not need to know how the work is divided among them.

#### Use when
* One event starts work spread across several classes, such as a trigger
* Callers would otherwise need to know the order in which to call several classes

#### Avoid when
* The facade starts to hold logic of its own. It only coordinates; the classes behind it do the work
* There is only one class behind it. Call that class

```java
public with sharing class ContactTriggerFacade {

	public static void onBeforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
		ContactEmailVerification.resetVerificationForChangedEmails(newContacts, oldContactsMap);
		ContactOwnerAssignment.assignOwnersForChangedRegions(newContacts, oldContactsMap);
	}
}
```

The trigger calls one facade method for each event. The [Trigger Facade Example](./Trigger%20Facade%20Example/README.md) shows the full structure.

[Back to Contents](#contents)

## Adapter
Wraps something the code does not own behind an interface it does own, translating between the two.

#### Use when
* The code depends on a callout, a managed package class, or a platform API such as `ConnectApi`
* The thing being wrapped cannot run in a unit test, so tests need to replace it
* Its errors and data formats should not spread through the rest of the code

#### Avoid when
* The code uses the thing in only one place and it can run in tests. Wrap it when either changes

```java
public interface BillingSystemInterface {
	void sendInvoices(List<Invoice__c> invoices);
}
```

```java
public with sharing class BillingSystemClient implements BillingSystemInterface {

	public void sendInvoices(List<Invoice__c> invoices) {
		// builds the request, sends it, and turns failures into BillingSyncException
	}
}
```

The rest of the code depends on `BillingSystemInterface`, and unit tests replace it with a mock. The [Apex Style Guide](./APEX_STYLE_GUIDE.md#wrap-what-you-do-not-own) shows the full client, and the [Agentforce Guide](./AGENTFORCE_GUIDE.md#invoke-templates-through-an-interface) applies the same pattern to prompt templates. The data accessors of the [Data Accessor Framework](./DATA_ACCESSOR_GUIDE.md) are adapters for the database.

[Back to Contents](#contents)
