# Salesforce Utility Classes

A collection of utility classes to make development easier and more consistent.

## HouseAccountUtility

Utility class that can be used to get house account id. Based on naming convention "Unknown Employer YYYY-MM", where each month a new house account is created.

```
// returns house account for current YYYY-MM based on today date or creates new
system.debug(HouseAccountUtility.getOrCreateSingleHouseAccount());

// returns house account for specificed date or creates new
HouseAccountUtility.houseAccountNameDate = date.valueOf('1999-01-01');
system.debug(HouseAccountUtility.getOrCreateSingleHouseAccount());

// returns house account based on name or creates new
system.debug(HouseAccountUtility.getOrCreateSingleHouseAccountByName('Graduate Programs'));
```

### TODO

- write test class

### Sample Implementation

```
MyClass mc = new MyClass();
mc.insertOrUpdateSingleContact('John','Doe ','anonymous@invalid.com');
```

```
public with sharing class MyClass {
  Id accountId;

  public myClass(){
    // assign account variable in current class by calling HouseAccountUtility utility class
    Account a = HouseAccountUtility.getOrCreateSingleHouseAccount();
    accountId = a.Id;
  }

  public void insertOrUpdateSingleContact(String firstName, String lastName, String emailAddress){
    List<Contact> cons = new List<Contact>();
    cons = [SELECT Id FROM Contact WHERE email = :emailAddress LIMIT 1];
    Contact c;

    if(cons.size() > 0) {
      // contact found
      c = cons[0];
    } else {
      // new contact
      c = new Contact();
      c.AccountId = accountId;
    }

    // make assignments to existing and new contacts
    c.firstName = firstname;
    c.lastName = lastname;
    c.email = emailAddress;

    upsert c;
  }

}
```

## RecordOwnerUtility

Utility class that allows random record ownership by public group membership, profile assignment, or role assigment.

```
// retrieve random active user from public group membership, with fall back to current user
system.debug(RecordOwnerUtility.getSingleUserByPublicGroupName('Exec Ed'));

// retrieve random active user from profile assignment, with fall back to current user
system.debug(RecordOwnerUtility.getSingleUserByProfileName('Eccles User LEX'));

// retrieve random active user from role assignment, with fall back to current user
system.debug(RecordOwnerUtility.getSingleUserByRoleName('MBA Admin'));

// retrieve active user by full name, with fall back to current user
system.debug(RecordOwnerUtility.getSingleUserByFullName('API User'));

// retrieve current user
system.debug(RecordOwnerUtility.getCurrentUser());
```

### TODO

- write test class
- update comments in class

### Sample Implementation

```
MyClass mc = new MyClass();
mc.insertOrUpdateSingleContact('John','Doe ','anonymous@invalid.com');
```

```
public with sharing class MyClass {
  Id ownerId;

  public myClass(){
    // assign user variable in current class by calling RecordOwnerUtility utility class
    User u = RecordOwnerUtility.getSingleUserByRoleName('MBA Admin');
    ownerId = u.Id;
  }

  public void insertOrUpdateSingleContact(String firstName, String lastName, String emailAddress){
    List<Contact> cons = new List<Contact>();
    cons = [SELECT Id FROM Contact WHERE email = :emailAddress LIMIT 1];
    Contact c;

    if(cons.size() > 0) {
      // contact found
      c = cons[0];
    } else {
      // new contact
      c = new Contact();
      c.ownerId = ownerId;
    }

    // make assignments to existing and new contacts
    c.firstName = firstname;
    c.lastName = lastname;
    c.email = emailAddress;

    upsert c;
  }

}
```
