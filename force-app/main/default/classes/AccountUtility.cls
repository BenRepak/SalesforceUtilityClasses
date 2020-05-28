public with sharing class AccountUtility {

    final static Id HOUSE_ACCT_REC_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Eccles House Account').getRecordTypeId();
    static Date houseAccountNameDate = system.today();
    static String houseAccountNamePrefix = 'Unknown Employer';


    private AccountUtility() {

    }

    public static Account getSingleHouseAccount() {
        String accountName;
   
        accountName = buildHouseAccountNameByDate(houseAccountNameDate);
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
        String year = string.valueOf(d.year());
        String month = string.valueOf(d.month());
        month = (month.length() == 1 ? '0'+month : month);
        String houseAccountName = houseAccountNamePrefix + ' ' + year + '-'  + month;
        return houseAccountName;
    }

    private static Account createSingleHouseAccountByName(String accountName) {
        Account a = new Account();
        a.name = accountName;
        a.recordTypeId = HOUSE_ACCT_REC_TYPE;
        insert a;
        return a;
    }
    

}
