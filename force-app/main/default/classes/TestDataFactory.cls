// Name: Jay Cina

@isTest
public class TestDataFactory {
  
  // Returns an already inserted User with Case Agent profile and Case Agent permission set
  public static User createAgentUser() {
    Profile p = [
    SELECT Id FROM Profile
    WHERE Name = 'Case Agent'
    LIMIT 1
    ];
    
    User agent = new User(
    Alias = 'agent',
    Email = 'agent@test.com',
    EmailEncodingKey = 'UTF-8',
    LastName = 'Agent',
    LanguageLocaleKey = 'en_US',
    LocaleSidKey = 'en_US',
    ProfileId = p.Id,
    TimeZoneSidKey = 'America/New_York',
    Username = 'agent.' + System.currentTimeMillis() + '@test.com'
    );
    
    insert agent;
    
    PermissionSet caseAgentPS = [
    SELECT Id
    FROM PermissionSet
    WHERE Name = 'Case_Agent'
    LIMIT 1
    ];
    
    PermissionSetAssignment psa = new PermissionSetAssignment(
    AssigneeId = agent.Id,
    PermissionSetId = caseAgentPS.Id
    );
    
    insert psa;
    
    return agent;
  }
  
  // Returns an already inserted User with Case Supervisor profile and Case Supervisor permission set
  public static User createSupervisorUser() {
    Profile p = [
    SELECT Id FROM Profile
    WHERE Name = 'Case Supervisor'
    LIMIT 1
    ];
    
    User Supervisor = new User(
    Alias = 'super',
    Email = 'supervisor@test.com',
    EmailEncodingKey = 'UTF-8',
    LastName = 'Supervisor',
    LanguageLocaleKey = 'en_US',
    LocaleSidKey = 'en_US',
    ProfileId = p.Id,
    TimeZoneSidKey = 'America/New_York',
    Username = 'supervisor.' + System.currentTimeMillis() + '@test.com'
    );
    
    insert supervisor;
    
    PermissionSet caseSupervisorPS = [
    SELECT Id
    FROM PermissionSet
    WHERE Name = 'Case_Supervisor'
    LIMIT 1
    ];
    
    PermissionSetAssignment psa = new PermissionSetAssignment(
    AssigneeId = supervisor.Id,
    PermissionSetId = caseSupervisorPS.Id
    );
    
    insert psa;
    
    return supervisor;
  }
  
  // Assigns a user (usually an Agent) to queue specified
  // Queue Name options include Housing, Medical, or Nutrition
  public static void assignUserToQueue(User user, String queueName) {
    List<Group> queue = [
    SELECT Id
    FROM Group
    WHERE DeveloperName = :queueName
    AND Type = 'Queue'
    LIMIT 1
    ];
    
    // Add User to Queue
    GroupMember member = new GroupMember(
    GroupId = queue[0].Id,
    UserOrGroupId = user.Id
    );
    
    insert member;
  }
  
  // Type options include Housing, Medical, or Nutrition
  public static Case createCase(String type) {
    Id recordTypeId;
    if(type == 'Housing' || type == 'Medical' || type == 'Nutrition') {
      recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(type).getRecordTypeId();
    }
    else {
      recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();
    }
    
    // Create Case
    Case c = new Case(
      Subject = 'Test Case',
      Status = 'New',
      Origin = 'Phone',
      RecordTypeId = recordTypeId
    );
    return c;
  }
  
  // Type options include Housing, Medical, or Nutrition
  public static List<Case> createBulkCases(Integer count, String type) {
    Id recordTypeId;
    if(type == 'Housing' || type == 'Medical' || type == 'Nutrition') {
      recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(type).getRecordTypeId();
    }
    else {
      recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Other').getRecordTypeId();
    }
    
    List<Case> cases = new List<Case>();
    for (Integer i = 0; i < count; i++) {
      cases.add(new Case(
      Subject = 'Test Case ' + i,
      Status = 'New',
      Priority = 'Medium',
      Origin = 'Phone',
      RecordTypeId = recordTypeId
      ));
    }
    return cases;
  }

  // Type options include Housing, Medical, or Nutrition
  public static Provider__c createProvider(String type) {
    String category;
    if(type == 'Housing' || type == 'Medical' || type == 'Nutrition') {
      category = type.toLowerCase();
    }
    else {
      System.assert(false, 'invalid type of provider category in TestDataFactory.createProvider(). type: ' + type);
      //throw new Exception('invalid type of provider category in TestDataFactory.createProvider(). type: ' + type);
    }
    return new Provider__c(
      Name__c = 'Test Provider',
      Service_Category__c = category,
      Accepting_New_Patients__c = true,
      Rating__c = '⭐️⭐️⭐️⭐️'
    );
  }
  
  public static void attachProviderToCase(Case c, Provider__c p) {
    Case_Provider__c cp = new Case_Provider__c(
      Case__c = c.Id,
      Provider__c = p.Id
    );
    insert cp;
  }
  
  
}