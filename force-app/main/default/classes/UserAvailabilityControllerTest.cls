@IsTest(SeeAllData=true)
public class UserAvailabilityControllerTest {
    private static User createUser(String profileName, String alias) {
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
        User u = new User(Alias = alias, Email = alias + '@test.com', EmailEncodingKey = 'UTF-8', LastName = alias,
            LanguageLocaleKey = 'en_US', LocaleSidKey = 'en_US', ProfileId = p.Id, TimeZoneSidKey = 'Asia/Kolkata', Username = alias + DateTime.now().getTime() + '@test.com');
        insert u;
        return u;
    }
    
    @IsTest
    static void testGetUsersAsSysAdmin() {
        User admin = createUser('System Administrator', 'admin');
        System.runAs(admin) {
            Test.startTest();
            List<User> users = UserAvailabilityController.getUsers();
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testGetUsersAsL2CreditMember() {
        User creditUser = createUser('Credit Officer', 'credit');
        User creditManager = createUser('Credit Manager', 'creditM');
        Id defaultBranchId = Id.valueOf(Label.Round_Robin_Default_Branch);
        AccountTeamMember atm = new AccountTeamMember(AccountId = defaultBranchId, UserId = creditUser.Id, TeamMemberRole = 'Credit', Level__c = 'L2');
        insert atm;
        System.runAs(creditUser) {
            Test.startTest();
            List<User> users = UserAvailabilityController.getUsers();
            Test.stopTest();
        }
    }

    @IsTest
    static void testGetUsersWithoutATM() {
        User normalUser = createUser('Credit Officer', 'noAtm');
        System.runAs(normalUser) {
            Test.startTest();
            List<User> users = UserAvailabilityController.getUsers();
            Test.stopTest();
        }
    }
    
    @IsTest
    static void testUpdateAvailability() {
        User creditUser = createUser('Credit Officer', 'availU');
        System.runAs(creditUser) {
            Test.startTest();
            UserAvailabilityController.updateAvailability(creditUser.Id, true);
            Test.stopTest();
        }

        User updatedUser = [SELECT I_am_available_today__c FROM User WHERE Id = :creditUser.Id];
    }
}