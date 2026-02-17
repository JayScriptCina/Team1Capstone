// Name: Jay Cina

@IsTest
private class Case_ErrorHandlerTest {
  
  // Successful Error Logging
  @IsTest
  static void testHandle_SuccessfulLogging() {

    Case c = TestDataFactory.createCase('Medical');
    insert c;
    
    Exception ex;
    try {
      Integer x = 1 / 0; // Force exception
      ex = null;
    } catch (Exception e) {
      ex = e;
    }
    
    Test.startTest();
    Case_ErrorHandler.Result result = Case_ErrorHandler.handle(ex, c.Id, 'UnitTest');
    Test.stopTest();
    
    System.assertEquals(false, result.success);
    System.assert(result.userMessage.contains(c.Id), 'User message should reference Case Id');
    System.assertNotEquals(null, result.activityId, 'Activity log should be created');
    
    Case_Activity__c log = [
      SELECT Case__c, Activity_Type__c, Context__c
      FROM Case_Activity__c
      WHERE Id = :result.activityId
    ];
    
    System.assertEquals(c.Id, log.Case__c);
    System.assertEquals('Error', log.Activity_Type__c);
    System.assertEquals('UnitTest', log.Context__c);
  }
  
  // Logging Failure Still Returns Result
  @IsTest
  static void testHandle_LoggingFailure() {
    
    Exception ex;
    try {
      String s = null;
      s.length(); // Force exception
      ex = null;
    } catch (Exception e) {
      ex = e;
    }
    
    // Invalid Case Id (User Id) forces DML failure
    Id invalidCaseId = UserInfo.getUserId();
    
    Test.startTest();
    Case_ErrorHandler.Result result = Case_ErrorHandler.handle(ex, invalidCaseId, 'UnitTest');
    Test.stopTest();
    
    System.assertEquals(false, result.success);
    System.assert(result.userMessage.contains(invalidCaseId), 'User message should still reference Case Id');
    System.assertEquals(null, result.activityId, 'Activity Id should be null when logging fails');
  }
}
