public with sharing class RecordOwnerUtility {
    public static Boolean useCachedUserMap = true;

    public static Integer defaultQueryRecordLimit = 200;

    public static Boolean queryAllUserFields = false;
    private static String cachedUserFields;


    //private static User cachedOwnerUser;
    private static String cachedFromWhereNameOrId;
    private static String cachedFromWhereType;
    private static integer querycounter = 0;
    private static Map<String, List<User>> cachedUserMapList = new Map<String, List<User>>();

    // TODO 
    // - implement a method to query multiple groups / profiles / roles and cache them
    // - implement a method to get next item in cached user map
    // - implement an option to queue a first user or queue all users from query


    public static void resetCachedVariables() {
        cachedFromWhereType = null;
        cachedFromWhereNameOrId = null;
    }
 

    public static User getRandomUserByGroupOrQueue(String fromWhereNameOrId){
        return getRandomUser('group', fromWhereNameOrId);
    }

    public static User getRandomUserByProfile(String fromWhereNameOrId){
        return getRandomUser('profile', fromWhereNameOrId);
    }

    public static User getRandomUserByRole(String fromWhereNameOrId){
        return getRandomUser('role', fromWhereNameOrId);
    }

    public static User getUserByFullName(String fromWhereNameOrId){
        return getRandomUser('user', fromWhereNameOrId);
    }


    @InvocableMethod (label='Get Random User' description='Returns the list of random users from specified profiles, roles, or groups.')
    public static List<RecordOwnerResponse> getRandomUser(List<RecordOwnerRequest> requests){
        List<RecordOwnerResponse> responses = new List<RecordOwnerResponse>();
        for(RecordOwnerRequest request : requests){
            if(request.defaultQueryRecordLimit != null){
                defaultQueryRecordLimit = request.defaultQueryRecordLimit;
            }
            if(request.userCacheEnabled != null){
                useCachedUserMap = request.userCacheEnabled;
            }
            queryAllUserFields = request.queryAllUserFields;

            RecordOwnerResponse response = new RecordOwnerResponse();
            response.randomUser = getRandomUser(request.fromWhereType, request.fromWhereNameOrId);
            responses.add(response);
        }
        return responses;
    }


    private static User getRandomUser(String fromWhereType, String fromWhereNameOrId){
        validateQueryLimit();
        User u;
        String queryString;
        cachedFromWhereNameOrId = fromWhereNameOrId;
        cachedFromWhereType = fromWhereType;
         
        // build query string
        queryString = buildSingleTypeQueryString(cachedFromWhereType);

        // execute query if a query string was built
        u = getSingleUserbyDynamicQuery(queryString);

        // if after checking cache and executing query there still isn't a user, fall back to currentUser 
        if(u == null){
            u = getCurrentUser();
        }
        system.debug('queryCounter --> ' + querycounter);
        return u;
    }

    private static string buildSingleTypeQueryString(String fromWhereType){
        String selectString = 'Id, FirstName, LastName, Name, UserName';
        String whereString;
        String queryString;
       
        if(queryAllUserFields == true && cachedUserFields == null){
            cachedUserFields = getUserFields();
        } 
        if(queryAllUserFields == true && cachedUserFields != null) {
            selectString = cachedUserFields;
        }

        switch on fromWhereType.toLowerCase(){
            when 'group' {
                whereString = '(SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :cachedFromWhereNameOrId OR GroupId = :cachedFromWhereNameOrId) LIMIT ' + defaultQueryRecordLimit;
            }
            when 'user'{
                whereString = '(Name =:cachedFromWhereNameOrId OR Id =:cachedFromWhereNameOrId) LIMIT 1';
            }
            when 'profile'{
                whereString = 'ProfileId  IN (SELECT Id FROM Profile WHERE name = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId) LIMIT ' + defaultQueryRecordLimit;
            }
            when 'role'{
                whereString  = 'UserRoleId IN (SELECT Id FROM UserRole WHERE DeveloperName = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId) LIMIT ' + defaultQueryRecordLimit;
            }
        }
        // system.debug('queryString --> ' + queryString);
        if(whereString != null){
            queryString = 'SELECT ' + selectString + ' FROM User WHERE isActive = TRUE AND ' + whereString;
        }
        system.debug('select string --> ' + selectString);
        return queryString;
    }


    private static void validateQueryLimit(){
        if(defaultQueryRecordLimit < 1 || defaultQueryRecordLimit >= 50000){
            defaultQueryRecordLimit = 200;
        }
    }

     // dynamic user query
     private static User getSingleUserbyDynamicQuery(String dynamicQuery) {
        List<User> users  = new List<User>();
        User u = searchCachedUserListMap();
        if(u == null && dynamicQuery != null && Limits.getQueries() < 100) {
            users = Database.query(dynamicQuery);
            querycounter++;
            String mapKey = getMapKey();
            updatedCachedUserListMap(mapKey, users);
            u = selectRandomUser(users);
        }    
        return u;
    }
 

    private static User searchCachedUserListMap(){
        User u;
        String mapKey = getMapKey();
        if(cachedUserMapList.get(mapKey) != null){
            List<User> users = cachedUserMapList.get(mapKey);
            u = selectRandomUser(Users);
        }
        return u;
    }


    private static void updatedCachedUserListMap(String mapKey, List<User> userResults){
        // skip building map if cache option disabled
        if(useCachedUserMap != true){
            return;
        }
        for(User u : userResults){
            if(cachedUserMapList.containsKey(mapKey)) {
                List<User> users = cachedUserMapList.get(mapKey);
                users.add(u);
            //    userRoleToUsers.put(newUser.UserRoleId, usersId);
            } else {
                cachedUserMapList.put(mapKey, new List<User> {u});
            }
        }
    }

    private static string getMapKey(){
        return cachedFromWhereType+cachedFromWhereNameOrId;
    }

    private static User getCurrentUser() {
        User u = new User();
        u.id = UserInfo.getUserId();
        u.username = UserInfo.getUserName(); 
        u.firstName = UserInfo.getFirstName();
        u.lastName = UserInfo.getLastName();
       // add current user to the cached map to avoid looped query if no users are found
       String mapKey = getMapKey();
       updatedCachedUserListMap(mapKey, new User[]{u});

       return u;
    }

     private static User selectRandomUser(List<User> users) {
        Integer listSize = users.size();
        if(listSize == 1){
            return users[0];
        }else if(listSize > 1) {
           Integer randomIndex = getRandomInteger(listSize);
            return users[randomIndex];
        } else {
            return getCurrentUser();
        }
     }

    private static integer getRandomInteger(Integer upperLimit){
        Double randomNumber = Math.random() * upperLimit;
        Integer randomIndex = randomNumber.intValue();
        return randomIndex;
    }



    public class RecordOwnerRequest{
        @InvocableVariable (label='Enable User Query Caching' required=true)
        public boolean userCacheEnabled;

        @InvocableVariable (label='User Query Type(Profile, Group, Role, or User)' required=true)
        public string fromWhereType;

        @InvocableVariable (label='Name of component to query (e.g. My Custom User Profile' required=true)
        public string fromWhereNameOrId;

        @InvocableVariable (label='Query Limit # Override' required=false)
        public integer defaultQueryRecordLimit;

        @InvocableVariable (label='Query All User Fields' required=false)
        public boolean queryAllUserFields = false;

    }

    public class RecordOwnerResponse{
        @InvocableVariable
        public User randomUser;
    }


    private static string getUserFields(){
        List<String> userFieldsList = new List<String>();
        for(Schema.SObjectField fld : Schema.SObjectType.User.fields.getMap().values()) {
            // skip field if user cannot access
            if(!fld.getDescribe().isAccessible()){
                continue;
            }
            string fieldString = fld.getDescribe().getName();
            userFieldsList.add(fieldString);
        }
        String selectStringfields = String.join(userFieldsList, ', ');
        return selectStringfields;
    }


}
