// Name: Jay Cina

@isTest
private class CaseTimelineControllerTest {

    @isTest
    static void testGetCaseActivities_WithUserMode_Supervisor() {
    // Agent inserts cases into their queue and assigns a provider
    User agent = TestDataFactory.createAgentUser();
    TestDataFactory.assignUserToQueue(agent, 'Medical');
    // Supervisor should see all case activities
    User supervisor = TestDataFactory.createSupervisorUser();
    
    System.runAs(agent) {
      Case c = TestDataFactory.createCase('Medical');
      insert c;
      
      Provider__c p = TestDataFactory.createProvider('Medical');
      insert p;

      TestDataFactory.attachProviderToCase(c, p);
    }
    
    System.runAs(supervisor) {
      Test.startTest();
      List<Case_Activity__c> results = CaseTimelineController.getCaseActivities();
      Test.stopTest();
      
      System.assertEquals(
      1,
      results.size(),
      'Supervisor should see all case activities'
      );
    }
  }
}