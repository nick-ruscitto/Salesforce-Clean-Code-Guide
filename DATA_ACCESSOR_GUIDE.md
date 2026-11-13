
# Apex Data Accessor Framework

**Introduction:**

The main purpose of the Data Accessor Framework is twofold: First, it eliminates duplicate code by having any Query or DML logic for an object exist in one location. This acts as a Model layer in the Model-View-Controller (MVC) design pattern that Salesforce often follows with an Apex Controller being the Controller, and a Lightning Web Component being the View. The second purpose is to allow for easy mocking when unit testing. The purpose of a unit test is to test a single unit of code so that if defects are prevalent, the unit test can be run to figure out where in the code there may be an issue. Mocking database actions are highly encouraged in unit tests where the particular unit of code under test does not care about what the setup of the data consists of. For example, if there is a method that takes in a list of Accounts and performs some sort of calculation on a custom field and returns that number, the unit test shouldn't fail because the Account had a new field marked as required where that new field does not interact at all with the method under test. This results in a false negative error in the context of that particular unit test. Mocking can be used to prevent the database action which would cause the DML exception.

## Components:

**{Object}DAO:**
The DAO (Data Access Object) is the interface named after the pattern itself. This interface contains all queries related to that particular object.

**Example:**

```java 
public interface UserDAO extends DmlInterface {
	User getUserById(String userId);
	List<User> getUsersByIds(Set<Id> userIds);
}
```


**{Object}DataAccessor:**

The DataAccessor is the class that implements the DAO. All of the queries are built within this class.

**Example:**
```java
public inherited sharing class UserDataAccessor extends DmlBase implements UserDAO {
	public User getUserById(String userId) {
		return [
			SELECT Id
				, FirstName
				, LastName
				, ContactId
			FROM User
			WHERE Id = :userId
		];
	}
	
	public List<User> getUsersByIds(Set<Id> userIds) {
		return [
			SELECT Id
				, FirstName
				, LastName
				, ContactId
			FROM User
			WHERE Id IN :userIds
		];
	}
}
```

**{Object}DataAccessorMock:**

The DataAccessorMock is the class that mocks the queries from its related DataAccessor and is used in unit tests. Each Mock class should have a class variable of type List of the object it is for to represent the data that would be in Salesforce. Then each method should check against that list. For example, if you have a method in an AccountDataAccessor that returns the Account from the passed in AccountId, that mock method should iterate through the class list of mocked Accounts, and if it finds an Account that matches the passed in Id it should return that Account, otherwise a QueryException should be thrown to mimic what would happen if an actual query failed to find an Account.

Tests put records into the mock's list with `addExistingRecords`, which stands in for records that already exist in the database. `insertRecords` is for records the code under test creates.


**Example:**

```java
@isTest
public inherited sharing class UserDataAccessorMock extends DmlBaseMock implements UserDAO {
	public List<User> mockDatabaseUsers;

	public UserDataAccessorMock() {
		super(new List<User>());
		this.mockDatabaseUsers = (List<User>)super.records;
	}
	
	public User getUserById(String userId) {
		User userToReturn;
		
		for (User u : mockDatabaseUsers) {
			if (u.Id == userId) {
				userToReturn = u;
			}
		}
		
		if (userToReturn != null) {
			return userToReturn;
		} else {
			throw new QueryException('User not found');
		}
	}
	
	public List<User> getUsersByIds(Set<Id> userIds) {
		List<User> usersToReturn = new List<User>();

		for (User u : mockDatabaseUsers) {
			if (userIds.contains(u.Id)) {
				usersToReturn.add(u);
			}
		}
	
		return usersToReturn;
	}
}
```

## Utility Components:
These components are utilities that provide the DML logic for each object. This code was extracted out to prevent duplicate code within the DataAccessors which likely need DML operations.

**DmlInterface:**
Interface that manages the various methods to perform DML operations.


**Code:**
```java
public interface DmlInterface {
	void insertRecords(List<SObject> newRecords);
	void updateRecords(List<SObject> records);
	void upsertRecords(List<SObject> records);
	void deleteRecords(List<SObject> records);
}
```

**DmlBase:**
Abstract class that contains the implementation of the DML operations. The DataAccessors will extend the DmlBase so that you can call the DML methods using the local instance of the DataAccessor.

**Code:**
```java
public inherited sharing abstract class DmlBase implements DmlInterface {
	public void insertRecords(List<SObject> newRecords) {
		insert newRecords;
	}

	public void updateRecords(List<SObject> records) {
		update records;
	}

	public void upsertRecords(List<SObject> records) {
		upsert records;
	}

	public void deleteRecords(List<SObject> records) {
		delete records;
	}
}
```

**DmlBaseMock:**
Abstract class that contains the mock implementations of the DML operations. Similar to the DataAccessorMock, the DmlBaseMock keeps its records in a class variable and changes that list for each DML operation. Records are matched on Id.


**Code:**
```java
public abstract class DmlBaseMock implements DmlInterface {
	protected List<SObject> records;
	private static final String ID_FIELD = 'Id';

	public DmlBaseMock(List<SObject> records) {
		this.records = records;
	}

	public List<SObject> getRecords() {
		return this.records;
	}

	public void addExistingRecords(List<SObject> existingRecords) {
		for (SObject record : existingRecords) {
			if (!hasId(record)) {
				throw new DmlException('Existing records must have a record Id.');
			}
		}

		this.records.addAll(existingRecords);
	}

	public void insertRecords(List<SObject> newRecords) {
		for (SObject record : newRecords) {
			if (hasId(record)) {
				throw new DmlException('Cannot insert a record with an ID.');
			}
			addId(record);
			this.records.add(record);
		}
	}

	public void updateRecords(List<SObject> changedRecords) {
		for (SObject record : changedRecords) {
			if (!hasId(record)) {
				throw new DmlException('Records to update must have a record Id.');
			}
			replaceRecord(record);
		}
	}

	public void upsertRecords(List<SObject> upsertedRecords) {
		for (SObject record : upsertedRecords) {
			if (hasId(record)) {
				replaceRecord(record);
			} else {
				addId(record);
				this.records.add(record);
			}
		}
	}

	public void deleteRecords(List<SObject> deletedRecords) {
		Set<Id> deletedIds = new Set<Id>();

		for (SObject record : deletedRecords) {
			if (!hasId(record)) {
				throw new DmlException('Records to delete must have a record Id.');
			}
			deletedIds.add(record.Id);
		}

		List<SObject> remainingRecords = new List<SObject>();
		for (SObject record : this.records) {
			if (!deletedIds.contains(record.Id)) {
				remainingRecords.add(record);
			}
		}

		this.records.clear();
		this.records.addAll(remainingRecords);
	}

	private Boolean hasId(SObject record) {
		return record.get(ID_FIELD) != null;
	}

	private void addId(SObject record) {
		record.put(ID_FIELD, MockIdGenerator.getMockId(record.getSObjectType()));
	}

	private void replaceRecord(SObject changedRecord) {
		for (Integer index = 0; index < this.records.size(); index++) {
			if (this.records[index].Id == changedRecord.Id) {
				this.records[index] = changedRecord;
				return;
			}
		}

		throw new DmlException('Record to update does not exist: ' + changedRecord.Id);
	}
}
```




