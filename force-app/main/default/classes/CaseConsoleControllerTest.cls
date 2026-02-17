// Name: Jay Cina

@isTest
private class CaseConsoleControllerTest {
  
  // Security & Bulk (Case Agent)
  @IsTest
  static void testGetCases_WithUserMode_Agent_Bulk() {
    // Create a User and assign them to Medical Queue
    User testUser = TestDataFactory.createAgentUser();
    TestDataFactory.assignUserToQueue(testUser, 'Medical');
    
    System.runAs(testUser) {
      List<Case> casesMedical = TestDataFactory.createBulkCases(200, 'Medical');
      insert casesMedical;
      List<Case> casesHousing = TestDataFactory.createBulkCases(200, 'Housing');
      insert casesHousing;
      
      Test.startTest();
      List<CaseDTO> results = CaseConsoleController.getCases();
      Test.stopTest();
      
      System.assertEquals(
      200,
      results.size(),
      'User should only see accessible cases'
      );
      
      System.assertNotEquals(
      null,
      results[0].CaseNumber,
      'DTO fields should be populated'
      );
    }
  }
  
  // Security (Supervisor)
  @IsTest
  static void testGetCases_WithUserMode_Supervisor() {
    // Agent inserts cases
    User agent = TestDataFactory.createAgentUser();
    // Supervisor should see all cases
    User supervisor = TestDataFactory.createSupervisorUser();
    
    System.runAs(agent) {
      List<Case> casesMedical = TestDataFactory.createBulkCases(2, 'Medical');
      insert casesMedical;
      List<Case> casesHousing = TestDataFactory.createBulkCases(4, 'Housing');
      insert casesHousing;
    }
    
    System.runAs(supervisor) {
      Test.startTest();
      List<CaseDTO> results = CaseConsoleController.getCases();
      Test.stopTest();
      
      System.assertEquals(
      6,
      results.size(),
      'User should only see accessible cases'
      );
      
      System.assertNotEquals(
      null,
      results[0].CaseNumber,
      'DTO fields should be populated'
      );
    }
  }
  
  // Case Provider Query: Agents should see all providers
  @IsTest
  static void testGetCaseProviders_UserMode() {
    // Create an Agent in the Medical Queue
    User agent = TestDataFactory.createAgentUser();
    TestDataFactory.assignUserToQueue(agent, 'Housing');
    
    // Create case outside of the agent's queues
    System.runAs(agent) {
      Case c = TestDataFactory.createCase('Housing');
      insert c;
      
      Provider__c p = TestDataFactory.createProvider('Housing');
      insert p;

      TestDataFactory.attachProviderToCase(c, p);
      
      Test.startTest();
      List<Case_Provider__c> results =
      CaseConsoleController.getCaseProviders();
      Test.stopTest();
      
      System.assertEquals(1, results.size());
      System.assertEquals(p.Id, results[0].Provider__c);
    }
  }
  
}