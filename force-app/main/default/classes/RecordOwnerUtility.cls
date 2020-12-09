public with sharing class RecordOwnerUtility {
    public static Boolean useCachedUserMap = true;

    private static User cachedOwnerUser;
    private static String cachedFromWhereNameOrId;
    private static String cachedFromWhereType;
    private static Map<String, User> cachedUserMap = new Map<String, User>();
    private static integer querycounter = 0;


    private static Map<String, List<User>> cachedUserMapList = new Map<String, List<User>>();



    // TODO - implement a method to get next item in cached user map


    public static void resetCachedVariables() {
        cachedOwnerUser = null;
        cachedFromWhereNameOrId = null;
    }

    public static User getRandomUser(String fromWhereType, String fromWhereNameOrId){
        User u;
        String queryString;
        // reset cached variables if values don't match
        // this means a new variable has been passed in
        if((cachedFromWhereType != fromWhereType) || (cachedFromWhereNameOrId != fromWhereNameOrId)) {
            resetCachedVariables();
            cachedFromWhereNameOrId = fromWhereNameOrId;
            cachedFromWhereType = fromWhereType;
        }    

        // check if user is cached from a previous query within execution context
        //u = searchCachedUserMap();
        u = searchCachedUserListMap();

        // if no cached user is found, build dynamic query string
        if(u == null){
            system.debug('enter query string');
            // build query string
            queryString = buildQueryString(cachedFromWhereType);
        }

        
        // execute query if a query string was built
        if(queryString != null){
            u = getSingleUserbyDynamicQuery(queryString);
        }

        // if after checking cache and executing query there still isn't a user, fall back to currentUser 
        if(u == null){
            system.debug('enter null');
            u = getCurrentUser();
        }
        system.debug('queryCounter --> ' + querycounter);
        
        // add current cached config to map if userCachedUserMap is enabled
        //updatedCachedUserListMap();
        updateCachedUserMap();
        return u;
    }

    private static string buildQueryString(String fromWhereType){
        String queryString;
        switch on fromWhereType.toLowerCase(){
            when 'group' {
                queryString = 'SELECT Id, Name FROM User WHERE isActive = TRUE AND ID IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = :cachedFromWhereNameOrId OR GroupId = :cachedFromWhereNameOrId)';
                //u = getSingleUserByPublicGroupName(cachedFromWhereNameOrId);
            }
            when 'user'{
                queryString = 'SELECT Id, Name FROM User WHERE isActive = TRUE AND (Name =:cachedFromWhereNameOrId OR Id =:cachedFromWhereNameOrId) LIMIT 1';

                // u = getSingleUserByFullName(cachedFromWhereNameOrId);
            }
            when 'profile'{
                queryString = 'SELECT Id, Name FROM User WHERE isActive = TRUE AND ProfileId  IN (SELECT Id FROM Profile WHERE name = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId)';

                // u = getSingleUserByProfileName(cachedFromWhereNameOrId);
            }
            when 'role'{
                queryString  = 'SELECT Id, Name FROM User WHERE isActive = TRUE AND UserRoleId IN (SELECT Id FROM UserRole WHERE DeveloperName = :cachedFromWhereNameOrId or Id =:cachedFromWhereNameOrId)';
                //u = getSingleUserByRoleName(cachedFromWhereNameOrId);
            }
        }
        system.debug('queryString --> ' + queryString);
        return queryString;
    }




     // dynamic user query
     private static User getSingleUserbyDynamicQuery(String dynamicQuery) {
        List<User> users  = new List<User>();
        if(cachedOwnerUser == null || cachedFromWhereNameOrId == null) {
            users = Database.query(dynamicQuery);
            querycounter++;
            cachedOwnerUser = selectRandomUser(users);
            updatedCachedUserListMap(users);
        }    
        return cachedOwnerUser;
    }

    private static User searchCachedUserMap(){
        if(cachedUserMap.get(cachedFromWhereType+cachedFromWhereNameOrId) != null){
            cachedOwnerUser = cachedUserMap.get(cachedFromWhereType+cachedFromWhereNameOrId);
        }
        return cachedOwnerUser;
    }
    
    private static void updateCachedUserMap(){
        if(useCachedUserMap == true){
            cachedUserMap.put(cachedFromWhereType+cachedFromWhereNameOrId,cachedOwnerUser);
        }
    }


    private static User searchCachedUserListMap(){
        if(cachedUserMapList.get(cachedFromWhereType+cachedFromWhereNameOrId) != null){
            List<User> users = cachedUserMapList.get(cachedFromWhereType+cachedFromWhereNameOrId);
            cachedOwnerUser = selectRandomUser(Users);
        }
        return cachedOwnerUser;
    }


    private static void updatedCachedUserListMap(List<User> userResults){
        if(useCachedUserMap == true){
            for(User u : userResults){
                if(cachedUserMapList.containsKey(cachedFromWhereType+cachedFromWhereNameOrId)) {
                    List<User> users = cachedUserMapList.get(cachedFromWhereType+cachedFromWhereNameOrId);
                    users.add(u);
                //    userRoleToUsers.put(newUser.UserRoleId, usersId);
                } else {
                    cachedUserMapList.put(cachedFromWhereType+cachedFromWhereNameOrId, new List<User> {cachedOwnerUser});
                }
            }
        }
    }

    private static User getCurrentUser() {
        User u = new User();
        u.id = UserInfo.getUserId();
        u.username = UserInfo.getUserName(); 
        u.firstName = UserInfo.getFirstName();
        u.lastName = UserInfo.getLastName();
        cachedOwnerUser = u;
       return cachedOwnerUser;
    }

     private static User selectRandomUser(List<User> users) {
        Integer listSize = users.size();
        if(listSize == 1){
            return users[0];
        }else if(listSize > 1) {
            Integer randomIndex = getRandoIndexWithLimit(listSize);
            return users[randomIndex];
        } else {
            return getCurrentUser();
        }
     }

     private static Integer getRandoIndexWithLimit(Integer upperLimit){
        Integer randTemp = Math.round(Math.random()*1000);
        Integer randFinal = Math.mod(randTemp, upperLimit);
        if(randFinal > upperLimit) {
            return upperLimit;
        } else {
            return randFinal;
        }
    }

    
}
