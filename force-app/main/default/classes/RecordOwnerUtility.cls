public with sharing class RecordOwnerUtility {
    public RecordOwnerUtility() {

    }


    // group
    public static User getSingleUserByPublicGroupName(String groupName) {
        List<User> users  = [SELECT Id, Name FROM User WHERE isActive = TRUE AND ID IN (SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = :groupName)];
        return selectRandomUser(users);
    }

    // name
    public static User getSingleUserByFullName(String userFullName) {
        List<User> users  = [SELECT Id, Name FROM User WHERE isActive = TRUE AND Name =: userFullName LIMIT 1];
        return selectRandomUser(users);
    }

    // profile
    public static User getSingleUserByProfileName(String profileName) {
        List<User> users  = [SELECT Id, Name FROM User WHERE isActive = TRUE AND ProfileId  IN (SELECT Id FROM Profile WHERE name = :profileName)];
        return selectRandomUser(users);
    }

    // user by role
    public static User getSingleUserByRoleName(String roleName) {
        List<User> users  = [SELECT Id, Name FROM User WHERE isActive = TRUE AND UserROleId  IN (SELECT Id FROM UserRole WHERE name = :roleName)];
        return selectRandomUser(users);
    }


    public static User getCurrentUser() {
        User u = new User();
        u.id = UserInfo.getUserId();
        u.username = UserInfo.getUserName(); 
        u.firstName = UserInfo.getFirstName();
        u.lastName = UserInfo.getLastName();
       return u;
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

     private static User selectRandomUser(List<User> users) {
        Integer listSize = users.size();
        if(listSize > 0) {
            Integer randomIndex = getRandoIndexWithLimit(listSize);
            return users[randomIndex];
        } else {
            return getCurrentUser();
        }
     }

    
}
