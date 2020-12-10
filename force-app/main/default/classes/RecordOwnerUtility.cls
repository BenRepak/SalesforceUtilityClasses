public with sharing class RecordOwnerUtility {
    public static Boolean useCachedUserMap = true;

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

    // to be used to cache many users for multiple profiles / roles / groups in a single soql 
    // this is a work in progres....
    private static void cacheUserList(String fromWhereType, List<String> fromWhereNamesorIds){
        String queryString;
        List<User> users;
        // build query string
        queryString = buildMultiTypeQueryString(fromWhereType,fromWhereNamesorIds);
        // perform query
        users = Database.query(queryString);
        // role 
     
    
        querycounter++;
        String mapKey = getMapKey();
       // updatedCachedUserListMap(mapKey, users);
        system.debug(cachedUserMapList.size());


        // update map 
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



    private static User getRandomUser(String fromWhereType, String fromWhereNameOrId){
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
        String queryString;
        switch on fromWhereType.toLowerCase(){
            when 'group' {
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND ID IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :cachedFromWhereNameOrId OR GroupId = :cachedFromWhereNameOrId)';
            }
            when 'user'{
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND (Name =:cachedFromWhereNameOrId OR Id =:cachedFromWhereNameOrId) LIMIT 1';
            }
            when 'profile'{
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND ProfileId  IN (SELECT Id FROM Profile WHERE name = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId)';
            }
            when 'role'{
                queryString  = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND UserRoleId IN (SELECT Id FROM UserRole WHERE DeveloperName = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId)';
            }
        }
        // system.debug('queryString --> ' + queryString);
        return queryString;
    }


    private static string buildMultiTypeQueryString(String fromWhereType, List<String> cachedFromWhereNameOrId){
        String queryString;
        switch on fromWhereType.toLowerCase(){
            when 'group' {
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND ID IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName IN :cachedFromWhereNameOrId OR GroupId IN :cachedFromWhereNameOrId)';
            }
            when 'user'{
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND (Name IN :cachedFromWhereNameOrId OR Id IN :cachedFromWhereNameOrId) LIMIT 1';
            }
            when 'profile'{
                queryString = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND ProfileId  IN (SELECT Id FROM Profile WHERE name IN :cachedFromWhereNameOrId or Id IN :cachedFromWhereNameOrId)';
            }
            when 'role'{
                queryString  = 'SELECT Id, FirstName, LastName, Name, UserName FROM User WHERE isActive = TRUE AND UserRoleId IN (SELECT Id FROM UserRole WHERE DeveloperName IN :fromWhereNameOrId or Id IN :cachedFromWhereNameOrId)';
            }
        }
        // system.debug('queryString --> ' + queryString);
        return queryString;
    }


     // dynamic user query
     private static User getSingleUserbyDynamicQuery(String dynamicQuery) {
        List<User> users  = new List<User>();
        User u = searchCachedUserListMap();
        if(u == null && dynamicQuery != null) {
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
       // cachedOwnerUser = u;
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
        @InvocableVariable (required=true)
        public boolean userCacheEnabled;

        @InvocableVariable (required=true)
        public string fromWhereType;

        @InvocableVariable (required=true)
        public string fromWhereNameOrId;
    }

    public class RecordOwnerResponse{
        @InvocableVariable
        public User randomUser;
    }

    @InvocableMethod (label='Get Random User' description='Returns the list of random users from specified profiles, roles, or groups.')
    public static List<RecordOwnerResponse> getRandomUser(List<RecordOwnerRequest> requests){
        List<RecordOwnerResponse> responses = new List<RecordOwnerResponse>();
        for(RecordOwnerRequest request : requests){
            RecordOwnerResponse response = new RecordOwnerResponse();
            response.randomUser = getRandomUser(request.fromWhereType, request.fromWhereNameOrId);
            responses.add(response);
        }
        return responses;
    }

    
}
