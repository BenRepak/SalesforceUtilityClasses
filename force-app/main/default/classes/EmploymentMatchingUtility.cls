/**
* @author Ben Repak
* @date 2020-05-04
*
*
* @description Utility class that helps with matching of new Employment__c records with existing Employment__c records. If a contact has existing Employment__c records where current_employer__c == true, this class will change the value to false for all previously existing records before inserting the new record.
*/
public with sharing class EmploymentMatchingUtility {

    /*******************************************************************************************************
    * @description holds map of any existing employment__c record(s) for contact(s) being processed, where key is Contact__r.code_key__c +  employer1__c + title__c 
    */
    public Map<string, Employment__c> mapEmploymentFound;
    /*******************************************************************************************************
    * @description holds pre-processed employment__c records, where key is Contact__r.code_key__c +  employer1__c + title__c 
    */
    public Map<string, Employment__c> mapEmploymentToProcess;
    /*******************************************************************************************************
    * @description for use with insert of new employment records, where key is Contact__r.code_key__c +  employer1__c + title__c 
    */
    public Map<String, Employment__c> mapEmploymentToInsert;
    /*******************************************************************************************************
    * @description for use with update of existing employment records, where key is employment id
    */
    public Map<Id, Employment__c> mapEmploymentToUpdate;
    /*******************************************************************************************************
    * @description builds set of contact ids for use in employment query WHERE clause
    */
    public Set<Id> setEmpLookup = new Set<Id>();
    /*******************************************************************************************************
    * @description default SELECT statement string for use in building employment record query. Set in class constructor.
    */
    private String selectString = '';
    /*******************************************************************************************************
    * @description default FROM clause string for use in building employment record query. Set in class constructor.
    */
    private String fromString = '';
    /*******************************************************************************************************
    * @description default WHERE clause string for use in building employment record query. Set in class constructor.
    */
    private String whereString = '';

    /*******************************************************************************************************
     * @description	Inner class to create custom exception. Provides ability to throw custom error messages. See documentation: https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_exception_custom.htm
     */
    private class EmploymentKeyFieldException extends Exception{}


    /*******************************************************************************************************
     * @description No-argument constructor used to new-up maps/sets and define default query values
     */
    public EmploymentMatchingUtility() {
        mapEmploymentFound = new Map<string, Employment__c>();
        mapEmploymentToProcess = new Map<string, Employment__c>();
        mapEmploymentToInsert = new Map<String, Employment__c>();
        mapEmploymentToUpdate = new Map<Id, Employment__c>();
        setEmpLookup = new Set<Id>();
        selectString = 'SELECT Id, Contact__c, Contact__r.code_key__c, Employer1__c, Title__c, Current_Employer__c ';
        fromString = 'FROM Employment__c ';
        whereString = 'WHERE Contact__c IN : setEmpLookup AND Employer1__c != NULL AND Title__c != NULL AND RecordType.Name = \'Employment\'';
    }


     /*******************************************************************************************************
     * @description Adds Contact Id to a set for use in query of existing Employment__c records
     * 
     * @param c an instance of a New or Existing Contact passed in from the class calling this utility. This should be represent the contact for the employment record being contact.
     */
    public void addContactIdToEmpLookupSet(Contact c) {
        if(c.id != null) {
            this.setEmpLookup.add(c.id);
        }
    }

    
    /*******************************************************************************************************
     * @description Executes query with default queryString
     */
    public Map<String, Employment__c> executeEmploymentQuery() {
        String empQuery = buildEmploymentQuery();
        for(Employment__c e : Database.query(empQuery)) {
            addEmploymentToFoundMap(e);
        }
        return mapEmploymentFound;
    }


    /*******************************************************************************************************
     * @description Allows a query to be executed with a custom queryString created in the calling class
     */
    public Map<String, Employment__c> executeEmploymentQuery(String queryString) {
        for(Employment__c e : Database.query(queryString)) {
            addEmploymentToFoundMap(e);
        }
        return mapEmploymentFound;
    }

    
     /*******************************************************************************************************
     * @description Adds new employment record to a temporary map for later comparision against existing records. The following fields are required at a minimum: Contact__r.Code_key__c, Title__c, Employer1__c.  
     * 
     * Contact__r.Code_key__c should be an instance of Contact object where only the Code_Key__c field value is set. For more info, see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/langCon_apex_dml_nested_object.htm or ContactMatchingHelper.findOrCreateCodeKey
     *
     *  @param e an instance of a new Employment__c record passed in from the class calling this utility
     */
    public void prepNewEmploymentRecord(Employment__c e) {
        //validateEmploymentKeyFields(e);
        String empKey = buildEmploymentKey(e);
        mapEmploymentToProcess.put(empKey, e);
    }


     /*******************************************************************************************************
     * @description Allows to conditionally insert and/or update employment records. Sets current_employer__c to false for all existing employment__c records.
     * 
     * @param insertRecords if true, new records from the calling class will be inserted
     * 
     * @param updateRecords if true, existing records will be updated and current_employer__c will be set to false 
     */
    public void executeDML(Boolean insertRecords, Boolean updateRecords) {

        // compare new records with any existing Salesforce, and add to update or insert maps
        reconcileNewEmploymentRecords();

        // set current_employer__c == false on existing records that do not match
        reconcileExistingCurrentEmploymentRecords();

        // conditionall process dml
        if(insertRecords == TRUE) {
            insertEmploymentRecords();
        }
        if(updateRecords == TRUE) {
            updateEmploymentRecords();
        }
    }


     /*******************************************************************************************************
     * @description compares new employment records pending processing to existing records found from query results. If a matching record for a given contact is found, the will be updated based on values set in the calling class. Matched employment__c record is removed from MapEmploymentFound to reduce update contlict with processing in the reconcileExistingCurrentEmploymentRecords() method. If no matching record is found, a new record will be added to mapEmploymentToInsert.
     * 
     */
    private void reconcileNewEmploymentRecords() {
        for(Employment__c e : mapEmploymentToProcess.values()) {
            String empKey = buildEmploymentKey(e);
            if(doesEmploymentExist(e) == TRUE) {
                e.id = mapEmploymentFound.get(empKey).id;
                mapEmploymentFound.remove(empKey);
                mapEmploymentToUpdate.put(e.id, e);
            } else {
                mapEmploymentToInsert.put(empKey, e);
            }
        }
    }


     /*******************************************************************************************************
     * @description all records remaining employment__c records in mapEmploymentFound.values() will have current_employer__c value set to FALSE
     * 
     */
    private void reconcileExistingCurrentEmploymentRecords() {
        for(Employment__c e : mapEmploymentFound.values()) {
            if(e.current_employer__c == TRUE) {
                e.current_employer__c = FALSE;
                mapEmploymentToUpdate.put(e.id, e);
            }
        }
    }

     /*******************************************************************************************************
     * @description processed Insert DML employment records  
     * 
     */
    private void insertEmploymentRecords() {
        insert mapEmploymentToInsert.values();
    }


     /*******************************************************************************************************
     * @description processed Update DML employment records  
     * 
     */
    private void updateEmploymentRecords() {
        update mapEmploymentToUpdate.values();
    }   


    /*******************************************************************************************************
     * @description Builds default query in class constructor
     */
    private string buildEmploymentQuery() {
        String queryString = selectString + fromString + whereString;
        return queryString;
    }
   

    /*******************************************************************************************************
     * @description Adds employment__c records to a map. Should only be used with records found query result. Can be called from within a loop of found records.
     * 
     * @param e Employment record found in query result. 
     */
    private void addEmploymentToFoundMap(Employment__c e) {
        String empKey = buildEmploymentKey(e);
        mapEmploymentFound.put(empKey,e);
        //addCurrentFoundEmploymentToMap(e);
    }


    /*******************************************************************************************************
     * @description Identifies if an instance of Employment__c exists within the map of query results 
     * 
     * @param e Represents a new employment record from a calling class
     * 
     * @return returns TRUE if record is found in the query results, oetherwise returns FALSE
     */
    private boolean doesEmploymentExist(Employment__c e) {
        validateEmploymentKeyFields(e);
        String empKey = buildEmploymentKey(e);
        if(mapEmploymentFound.containsKey(empKey)) {
            return true;
        } else {
            return false;
        }
    }

 
     /*******************************************************************************************************
     * @description Builds key for matching employmet record. Requires Contact__r.code_key__c, employer1__c, and title__c
     * 
     * @param e Represents an employment__c record
     * 
     * @return returns the string value of the concantenation of Contact__r.code_key__c, employer1__c (lower case), and title__c (lower case)
     */
    private string buildEmploymentKey(Employment__c e) {
        validateEmploymentKeyFields(e);
        String empKey = e.Contact__r.code_key__c+e.Employer1__c.toLowerCase()+e.Title__c.toLowerCase();
        return empKey;
    }


     /*******************************************************************************************************
     * @description Ensures the employment record has values for Contact__r.code_key__c, title__c and employer1__c 
     * 
     * @param e Represents an employment__c record
     * 
     * @return returns true if there are values in Contact__r.code_key__c, title__c and employer1__c, otherwise throws custom exception
     */
    private Boolean validateEmploymentKeyFields(Employment__c e) {
        if(e.Contact__r.code_key__c != null && e.Employer1__c != null && e.Title__c != null) {
            return true;
        } else {
            String exceptionString = '';
            exceptionString += 'Employment Key Field Exception. Requires Contact__r.Code_key__c, Employer1__c, and Title__c. Actual values ***' ;
            exceptionString += 'e.Contact__r.Code_Key__c *** ' + e.Contact__r.Code_Key__c;
            exceptionString += 'e.Title__c *** ' + e.Title__c;
            exceptionString += 'e.Employer1__c *** ' + e.Employer1__c;
            throw new EmploymentKeyFieldException(exceptionString);
        }
    }

} // end of class