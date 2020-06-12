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

### Sample Implementation

```
public with sharing class MyClass {
  Id accountId;

  public myClass(){
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
