public with sharing class HouseAccountUtility {
    public static Date houseAccountNameDate = system.today();
    public static String houseAccountNamePrefix = 'Unknown Employer';
    private final static Id HOUSE_ACCT_REC_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Eccles House Account').getRecordTypeId();

    private HouseAccountUtility() {

    }

    public static Account getOrCreateSingleHouseAccount() {
        String accountName = buildHouseAccountNameByDate(houseAccountNameDate);
        Account a = getSingleHouseAccountByName(accountName);
        return a;
    }

    private static Account getSingleHouseAccountByName(String accountName) {
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

    private static String buildHouseAccountNameByDate(Date d) {
        String year = getYearFromDate(d);
        String month = getMonthFromDate(d);
        month = formatMonthString(month);
        String houseAccountName = buildHouseAccountName(year, month);
        return houseAccountName;
    }

    private static string getYearFromDate(Date d) {
        return string.valueOf(d.year());
    }

    private static string getMonthFromDate(Date d) {
        return string.valueOf(d.month());
    }

    private static string formatMonthString(String month) {
        return (month.length() == 1 ? '0'+month : month);
    }

    private static string buildHouseAccountName(String yearString, String monthString) {
        return houseAccountNamePrefix + ' ' + yearString + '-'  + monthString;
    }


    private static Account createSingleHouseAccountByName(String accountName) {
        Account a = new Account();
        a.name = accountName;
        a.recordTypeId = HOUSE_ACCT_REC_TYPE;
        a.ownerId = getOwnerId();
        insert a;
        return a;
    }

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

    private static Id getAdminUserId() {
         return [SELECT Id FROM User WHERE isActive = true AND userrole.name = 'Admin' and lastname != 'User' LIMIT 1][0].id;
    }

    private static Id getCurrentUserId() {
       return UserInfo.getUserId();
    }

}
