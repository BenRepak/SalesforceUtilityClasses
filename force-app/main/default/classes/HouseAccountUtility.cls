/**
* @author Ben Repak
* @date 2020-05-28
*
* @description Utility class that can be used to get house account id. Based on naming convention "Unknown Employer YYYY-MM", where each month a new house account is created. 
*/
public with sharing class HouseAccountUtility {

    /*******************************************************************************************************
    * @description date used in YYYY-MM naming convention for house accounts. Can be overridden if needed (e.g. for testing)
    */
    public static Date houseAccountNameDate = system.today();

    /*******************************************************************************************************
    * @description date used in naming convention for house accounts. Can be overridden if needed (e.g. for testing or if new conventio is needed)
    */
    public static String houseAccountNamePrefix = 'Unknown Employer';

    /*******************************************************************************************************
    * @description recordTypeId for house accounts, used if creating new account
    */
    private final static Id HOUSE_ACCT_REC_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Eccles House Account').getRecordTypeId();


    /*******************************************************************************************************
     * @description No-argument constructor, should not be used as all methods are static
     */
    private HouseAccountUtility() {
        system.debug('No-argument HouseAccountUtility constructor should not be used as methods are static');
    }

    /*******************************************************************************************************
     * @description method to be called from other classes in constructor. Will find or create a house account based. DO NOT CALL IN A LOOP!
     * 
     * @return Account
     */
    public static Account getOrCreateSingleHouseAccount() {
        String accountName = buildHouseAccountNameByDate(houseAccountNameDate);
        Account a = getOrCreateSingleHouseAccountByName(accountName);
        return a;
    }


     /*******************************************************************************************************
     * @description finds or createas a house account by name
     * 
     * @param accountName name of account to be queried or created
     * 
     * @return Account
     */
    public static Account getOrCreateSingleHouseAccountByName(String accountName) {
        Account a = new Account();     
        try {
            a = [SELECT Id, RecordTypeId, Name FROM Account WHERE name = :accountName and recordTypeId = :HOUSE_ACCT_REC_TYPE  LIMIT 1];
        } catch(QueryException  qe) {
            System.debug('<<<<<<<< EXCEPTION: AccountUtility.getSingleAccountByName >>>>>>>>');
            System.debug('Exception type caught: ' + qe.getTypeName());    
            System.debug('Message: ' + qe.getMessage());    
            System.debug('Cause: ' + qe.getCause());    // returns null
            System.debug('Line number: ' + qe.getLineNumber());    
            System.debug('Stack trace: ' + qe.getStackTraceString());
            a = createSingleHouseAccountByName(accountName);
        }
        return a;
    }


    /*******************************************************************************************************
     * @description parses name of house account based on date
     * 
     * @param d date in format YYYY-MM-DD
     * 
     * @return string value of account name (e.g. Unknown Employer 2020-05)
     */
    private static String buildHouseAccountNameByDate(Date d) {
        String year = getYearFromDate(d);
        String month = getMonthFromDate(d);
        month = formatMonthString(month);
        return (houseAccountNamePrefix + ' ' + year + '-'  + month);
    }


    /*******************************************************************************************************
     * @description converts the year of a specific date to a string
     * 
     * @param d date value YYYY-MM-DD
     * 
     * @return string value of year (YYYY)
     */
    private static string getYearFromDate(Date d) {
        return string.valueOf(d.year());
    }


    /*******************************************************************************************************
     * @description converts the month of a specific date to a string
     * 
     * @param d date value YYYY-MM-DD
     * 
     * @return string value of month (MM or M)
     */    
    private static string getMonthFromDate(Date d) {
        return string.valueOf(d.month());
    }


    /*******************************************************************************************************
     * @description adds leading zero to months 1-9
     * 
     * @param month string value of month (MM or M)
     * 
     * @return 2 character String of month (MM)
     */
    private static string formatMonthString(String month) {
        return (month.length() == 1 ? '0'+month : month);
    }
   

    /*******************************************************************************************************
     * @description creates a single account with record type Eccles House Account
     * 
     * @param accountName name of new account to be created
     * 
     * @return Account
     */
    private static Account createSingleHouseAccountByName(String accountName) {
        Account a = new Account();
        a.name = accountName;
        a.recordTypeId = HOUSE_ACCT_REC_TYPE;
        a.ownerId = getOwnerId();
        insert a;
        return a;
    }


    /*******************************************************************************************************
     * @description used to return the id of either a random admin or, on exception, the current users's id. The exception handles if there isn't an active admin
     * 
     * @return Salesforce user Id
     */    
    private static Id getOwnerId(){
        try{
            return getAdminUserId();
        } catch(Exception e) {
            System.debug('<<<<<<<< EXCEPTION: AccountUtility.getOwnerId >>>>>>>>');
            System.debug('Exception type caught: ' + e.getTypeName());    
            System.debug('Message: ' + e.getMessage());    
            System.debug('Cause: ' + e.getCause());   
            System.debug('Line number: ' + e.getLineNumber());    
            System.debug('Stack trace: ' + e.getStackTraceString());
            return getCurrentUserId();
        }
    }


    /*******************************************************************************************************
     * @description retreives the Id of a random salesforce admin that is active and doesn't have a last name of "user"
     * 
     * @return Salesforce user Id
     */
    private static Id getAdminUserId() {
         return [SELECT Id FROM User WHERE isActive = true AND userrole.name = 'Admin' and lastname != 'User' LIMIT 1][0].id;
    }


    /*******************************************************************************************************
     * @description retrieves the current user's Id
     * 
     * @return Salesforce user Id
     */
    private static Id getCurrentUserId() {
       return UserInfo.getUserId();
    }

}
