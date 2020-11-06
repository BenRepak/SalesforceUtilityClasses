@isTest

public with sharing class EmploymentMatchingUtility_TEST {
    
    public static Id houseAcctRecTypeid;
    public static string ecclesAccountId;
    final static String EMP_RECORD_TYPE = Schema.SObjectType.Employment__c.getRecordTypeInfosByDeveloperName().get('Employment').getRecordTypeId();

    @testSetup 
    static void setupData() {
        houseAcctRecTypeid = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Eccles House Account').getRecordTypeId();
    // build accounts
        List<Account> testAccounts = new List<Account>();
        Set<String> names = new Set<String>();
        names.add('D. Eccles School of Business');
        names.add('Executive Education');

        for(String s : names) {
            Account a = new Account();
            a.name = s;
            a.RecordTypeId = HouseAcctRecTypeid;
            testAccounts.add(a);  
        }
        if(testAccounts.size()>0) {
        insert testAccounts;
        }
        ecclesAccountId = testAccounts[0].id;
    }


    // expect new contact and new employment
    @isTest
    static void insertContactAndEmployment(){
        Contact c = new Contact();
        c.firstname = 'Taylor';
        c.lastname = 'Swift';
        c.email = 'shiftyswifty@bad.com';
        c.accountid = ecclesAccountId;
        insert c;

        Contact result = new Contact();
        result = [SELECT Id, Name, Code_key__c FROM Contact WHERE Id = :c.id LIMIT 1][0];

        Test.startTest();
        EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
        employmentUtility.addContactIdToEmpLookupSet(c);
		Employment__c e = new Employment__c();
		e.Contact__r = new Contact(code_key__c = result.code_key__c);
		e.Employer1__c = 'employer';
		e.Title__c = 'title';
		e.Current_Employer__c = TRUE;
		e.recordtypeid = EMP_RECORD_TYPE;
		employmentUtility.prepNewEmploymentRecord(e);
        employmentUtility.executeEmploymentQuery();
        employmentUtility.executeDML(true, true);
        Test.stopTest();

        Integer contactSize = [SELECT count() FROM Contact];
        Integer employmentSize = [SELECT count() FROM Employment__c];
        System.assertEquals(1,contactSize,'Expect 1 contact record');
        System.assertEquals(1,employmentSize,'Expect 1 employment record');
    }


    // match on an existing employment for an existing contact
    @isTest
    static void updateExistingEmployment(){        
        Contact c = new Contact();
        c.firstname = 'Taylor';
        c.lastname = 'Swift';
        c.email = 'shiftyswifty@bad.com';
        c.accountid = ecclesAccountId;
        insert c;
		Employment__c emp = new Employment__c();
        emp.Contact__c = c.id;
		emp.Employer1__c = 'employer';
		emp.Title__c = 'title';
		emp.Current_Employer__c = TRUE;
		emp.recordtypeid = EMP_RECORD_TYPE;
        insert emp;
     
        Contact result = new Contact();
        result = [SELECT Id, Name, Code_key__c FROM Contact WHERE Id = :c.id LIMIT 1][0];
        Test.startTest();
        EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
        employmentUtility.addContactIdToEmpLookupSet(c);
		Employment__c e = new Employment__c();
		e.Contact__r = new Contact(code_key__c = result.code_key__c);
		e.Employer1__c = 'employer';
		e.Title__c = 'title';
		e.Current_Employer__c = TRUE;
		e.recordtypeid = EMP_RECORD_TYPE;
		employmentUtility.prepNewEmploymentRecord(e);
        employmentUtility.executeEmploymentQuery();
        employmentUtility.executeDML(true, true);
        Test.stopTest();

        Integer contactSize = [SELECT count() FROM Contact];
        Integer employmentSize = [SELECT count() FROM Employment__c];
        System.assertEquals(1,contactSize,'Expect 1 contact record');
        System.assertEquals(1,employmentSize,'Expect 1 employment record');
    }


    // match on existing contact with existing employment records
    // for all existing employment records, current_employer__c field set to false, insert new employment
    @isTest
    static void updateExistingAndInsertNewEmployment(){        
        List<Employment__c> emps = new List<Employment__c>();
        Contact c = new Contact();
        c.firstname = 'Taylor';
        c.lastname = 'Swift';
        c.email = 'shiftyswifty@bad.com';
        c.accountid = ecclesAccountId;
        insert c;
        Integer i = 1;
        while(i <= 5) {
            Employment__c emp = new Employment__c();
            emp.Contact__c = c.id;
            emp.Employer1__c = 'employer'+i;
            emp.Title__c = 'title'+i;
            emp.Current_Employer__c = TRUE;
            emp.recordtypeid = EMP_RECORD_TYPE;
            emps.add(emp);
            i++;
        }
        insert emps;
     
        Contact result = new Contact();
        result = [SELECT Id, Name, Code_key__c FROM Contact WHERE Id = :c.id LIMIT 1][0];
        
        Test.startTest();
        EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
        employmentUtility.addContactIdToEmpLookupSet(c);
		Employment__c e = new Employment__c();
		e.Contact__r = new Contact(code_key__c = result.code_key__c);
		e.Employer1__c = 'employer';
		e.Title__c = 'title';
		e.Current_Employer__c = TRUE;
		e.recordtypeid = EMP_RECORD_TYPE;
		employmentUtility.prepNewEmploymentRecord(e);
        employmentUtility.executeEmploymentQuery();
        employmentUtility.executeDML(true, true);
        Test.stopTest();

        Integer contactSize = [SELECT count() FROM Contact];
        Integer employmentSize = [SELECT count() FROM Employment__c];
        Integer countCurrentEmployerTrue = [SELECT count() FROM Employment__c where current_employer__c = true];
        Integer countCurrentEmployerFalse = [SELECT count() FROM Employment__c where current_employer__c = false];
        System.assertEquals(1,contactSize,'Expect 1 contact record');
        System.assertEquals(6,employmentSize,'Expect 6 employment records');
        System.assertEquals(1,countCurrentEmployerTrue,'Expect 1 current employer record == TRUE');
        System.assertEquals(5,countCurrentEmployerFalse,'Expect 5 current employer record == FALSE');
    }


        // handle bulk processing of 201 employment records
        // match on existing contact with existing employment records
        // for all existing employment records, current_employer__c field set to false, insert new employment
   
        @isTest
        static void updateExistingAndInsertNewEmployment_BULK(){        
            List<Employment__c> emps = new List<Employment__c>();
            Contact c = new Contact();
            c.firstname = 'Taylor';
            c.lastname = 'Swift';
            c.email = 'shiftyswifty@bad.com';
            c.accountid = ecclesAccountId;
            insert c;
            Integer i = 1;
            while(i < 202) {
                Employment__c emp = new Employment__c();
                emp.Contact__c = c.id;
                emp.Employer1__c = 'employer'+i;
                emp.Title__c = 'title'+i;
                emp.Current_Employer__c = TRUE;
                emp.recordtypeid = EMP_RECORD_TYPE;
                emps.add(emp);
                i++;
            }
            insert emps;
         
            Contact result = new Contact();
            result = [SELECT Id, Name, Code_key__c FROM Contact WHERE Id = :c.id LIMIT 1][0];
            
            Test.startTest();
            EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
            employmentUtility.addContactIdToEmpLookupSet(c);
            Employment__c e = new Employment__c();
            e.Contact__r = new Contact(code_key__c = result.code_key__c);
            e.Employer1__c = 'employer';
            e.Title__c = 'title';
            e.Current_Employer__c = TRUE;
            e.recordtypeid = EMP_RECORD_TYPE;
            employmentUtility.prepNewEmploymentRecord(e);
            employmentUtility.executeEmploymentQuery();
            employmentUtility.executeDML(true, true);
            Test.stopTest();
    
            Integer contactSize = [SELECT count() FROM Contact];
            Integer employmentSize = [SELECT count() FROM Employment__c];
            Integer countCurrentEmployerTrue = [SELECT count() FROM Employment__c where current_employer__c = true];
            Integer countCurrentEmployerFalse = [SELECT count() FROM Employment__c where current_employer__c = false];
            System.assertEquals(1,contactSize,'Expect 1 contact record');
            System.assertEquals(202,employmentSize,'Expect 202 employment records');
            System.assertEquals(1,countCurrentEmployerTrue,'Expect 1 current employer record == TRUE');
            System.assertEquals(201,countCurrentEmployerFalse,'Expect 201 current employer record == FALSE');
        }

        // multiple contacts, 2 with existing employment records and 1 without any existing employment records
        // match on existing contact with existing employment records
        // for all existing employment records, current_employer__c field set to false, insert new employment
   
        @isTest
        static void updateExistingAndInsertNewEmployment_MultipleContacts(){        
            List<Employment__c> emps = new List<Employment__c>();
            List<Contact> cons = new List<Contact>();
            // create 3 contacts, 2 of which will have employment records and 1 will not have any employment records
            // existing employment
            Contact c1 = new Contact();
            c1.firstname = 'Taylor';
            c1.lastname = 'Swift';
            c1.email = 'shiftyswifty@bad.com';
            c1.accountid = ecclesAccountId;
            cons.add(c1);
        
            // existing employment
            Contact c2 = new Contact();
            c2.firstname = 'Ariana';
            c2.lastname = 'Grande';
            c2.email = 'bigsky@bad.com';
            c2.accountid = ecclesAccountId;
            cons.add(c2);

            // no existing employment
            Contact c3 = new Contact();
            c3.firstname = 'Ariana';
            c3.lastname = 'Grande';
            c3.email = 'bigsky@bad.com';
            c3.accountid = ecclesAccountId;
            cons.add(c3);
            insert cons;
            Employment__c emp1 = new Employment__c();
            emp1.Contact__c = c1.id;
            emp1.Employer1__c = 'employer'+c1.email;
            emp1.Title__c = 'title'+c1.email;
            emp1.Current_Employer__c = TRUE;
            emp1.recordtypeid = EMP_RECORD_TYPE;
            emps.add(emp1);
            Employment__c emp2 = new Employment__c();
            emp2.Contact__c = c2.id;
            emp2.Employer1__c = 'employer'+c2.email;
            emp2.Title__c = 'title'+c2.email;
            emp2.Current_Employer__c = TRUE;
            emp2.recordtypeid = EMP_RECORD_TYPE;
            emps.add(emp2);
            insert emps;

            List<Contact> consResult = new List<Contact>();
            consResult = [SELECT Id, Name, Code_key__c FROM Contact];
            
            Test.startTest();
            EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
            for(Contact c : consResult){
                employmentUtility.addContactIdToEmpLookupSet(c);
                Employment__c e = new Employment__c();
                e.Contact__r = new Contact(code_key__c = c.code_key__c);
                e.Employer1__c = 'new employer';
                e.Title__c = 'new title';
                e.Current_Employer__c = TRUE;
                e.recordtypeid = EMP_RECORD_TYPE;
                employmentUtility.prepNewEmploymentRecord(e);
            }
            employmentUtility.executeEmploymentQuery();
            employmentUtility.executeDML(true, true);
            Test.stopTest();
    
            Integer contactSize = [SELECT count() FROM Contact];
            Integer employmentSize = [SELECT count() FROM Employment__c];
            Integer countCurrentEmployerTrue = [SELECT count() FROM Employment__c where current_employer__c = true];
            Integer countCurrentEmployerFalse = [SELECT count() FROM Employment__c where current_employer__c = false];
            System.assertEquals(3,contactSize,'Expect 3 contact records');
            System.assertEquals(5,employmentSize,'Expect 5 employment records');
            System.assertEquals(3,countCurrentEmployerTrue,'Expect 3 current employer record == TRUE');
            System.assertEquals(2,countCurrentEmployerFalse,'Expect 2 current employer record == FALSE');
        }


    // build custom query using executeEmploymentQuery(arg1) method
    @isTest
    static void insertContactAndEmployment_customQuery(){
        String selectString = 'SELECT Id, Contact__c, Contact__r.code_key__c, Employer1__c, Title__c, Current_Employer__c ';
        String fromString = 'FROM Employment__c ';
        String whereString = 'WHERE Contact__c IN : setEmpLookup AND Employer1__c != NULL AND Title__c != NULL AND RecordType.Name = \'Employment\' AND createddate <= TODAY';
        String queryString = selectString + fromString + whereString;

        Contact c = new Contact();
        c.firstname = 'Taylor';
        c.lastname = 'Swift';
        c.email = 'shiftyswifty@bad.com';
        c.accountid = ecclesAccountId;
        insert c;
		Employment__c emp = new Employment__c();
        emp.Contact__c = c.id;
		emp.Employer1__c = 'employer';
		emp.Title__c = 'title';
		emp.Current_Employer__c = TRUE;
		emp.recordtypeid = EMP_RECORD_TYPE;
        insert emp;

        Contact result = new Contact();
        result = [SELECT Id, Name, Code_key__c FROM Contact WHERE Id = :c.id LIMIT 1][0];
        
        Test.startTest();
        EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
        employmentUtility.addContactIdToEmpLookupSet(c);
		Employment__c e = new Employment__c();
		e.Contact__r = new Contact(code_key__c = result.code_key__c);
		e.Employer1__c = 'employer';
		e.Title__c = 'title';
		e.Current_Employer__c = TRUE;
		e.recordtypeid = EMP_RECORD_TYPE;
		employmentUtility.prepNewEmploymentRecord(e);
        employmentUtility.executeEmploymentQuery(queryString);
        employmentUtility.executeDML(true, true);
        Test.stopTest();

        Integer contactSize = [SELECT count() FROM Contact];
        Integer employmentSize = [SELECT count() FROM Employment__c];
        System.assertEquals(1,contactSize,'Expect 1 contact record');
        System.assertEquals(1,employmentSize,'Expect 1 employment record');
    }


    // expect custom exception thrown due to missing code key on contact record
    @isTest
    static void insertEmploymentFailCodeKey(){
        String actualCustomExceptionType;
        Contact c = new Contact();
        c.firstname = 'Taylor';
        c.lastname = 'Swift';
        c.email = 'shiftyswifty@bad.com';
        c.accountid = ecclesAccountId;
        insert c;

        Test.startTest();
        EmploymentMatchingUtility employmentUtility = new EmploymentMatchingUtility();
        employmentUtility.addContactIdToEmpLookupSet(c);
		Employment__c e = new Employment__c();
		e.Contact__r = new Contact(code_key__c = c.code_key__c);
		e.Employer1__c = 'employer';
		e.Title__c = 'title';
		e.Current_Employer__c = TRUE;
        e.recordtypeid = EMP_RECORD_TYPE;
        try{
            employmentUtility.prepNewEmploymentRecord(e);
            employmentUtility.executeEmploymentQuery();
            employmentUtility.executeDML(true, true);
        } catch(Exception ex){
            actualCustomExceptionType = (string)ex.getTypeName();
        }
        Test.stopTest();

        Integer contactSize = [SELECT count() FROM Contact];
        Integer employmentSize = [SELECT count() FROM Employment__c];
        String expectedCustomExceptoinType = 'EmploymentMatchingUtility.EmploymentKeyFieldException';
        System.assertEquals(1,contactSize,'Expect 1 contact record');
        System.assertEquals(0,employmentSize,'Expect 0 employment records');
        System.assertEquals(expectedCustomExceptoinType,actualCustomExceptionType,'Expect a custom exception to be thrown');
    }
}