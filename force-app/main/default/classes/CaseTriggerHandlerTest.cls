@isTest
public class CaseTriggerHandlerTest {
  
  // Utility method to create a valid Case
  private static Case buildCase(String priority, String descr) {
    return new Case(
    Subject = 'Test Case',
    Status = 'New',
    Priority = priority,
    Description = descr,
    Origin = 'Phone'
    );
  }
  
  // BEFORE INSERT TESTS
  
  // Positive: High priority with valid description (>= 30 chars)
  @IsTest
  static void testBeforeInsert_Positive() {
    Case c = buildCase('High', 'This description is longer than thirty characters and will pass!');
    
    Test.startTest();
    insert c;
    Test.stopTest();
    
    System.assertNotEquals(null, c.Id, 'Case should be inserted successfully');
  }
  
  // Negative: High priority with short description (< 30 chars)
  @IsTest
  static void testBeforeInsert_Negative() {
    Case c = buildCase('High', 'Too short');
    
    Test.startTest();
    try {
      insert c;
      System.assert(false, 'Expected DmlException due to validation error');
    } catch (DmlException e) {
      System.assert(
      e.getMessage().contains('If Priority is High'),
      'Expected validation error message'
      );
    }
    Test.stopTest();
  }
  
  // Positive: Non-high priority should not trigger validation
  @IsTest
  static void testBeforeInsert_NonHighPriority() {
    Case c = buildCase('Medium', 'Short desc ok');
    
    Test.startTest();
    insert c;
    Test.stopTest();
    
    System.assertNotEquals(null, c.Id);
  }
  
  // AFTER INSERT TESTS
  
  // Positive: Case_Activity__c created after insert
  @IsTest
  static void testAfterInsert_LogCreated() {
    Case c = buildCase('Low', 'Valid description long enough for safety testing.');
    
    Test.startTest();
    insert c;
    Test.stopTest();
    
    // Fetch log data
    List<Case_Activity__c> logs = [
      SELECT Id, Activity_Type__c, Context__c, Case__c
      FROM Case_Activity__c
      WHERE Case__c = :c.Id
    ];
    
    System.assertEquals(1, logs.size(), 'One log should be created but we have ' + logs);
    System.assertEquals('Intake', logs[0].Activity_Type__c, 'Activity Type is ' + logs[0].Activity_Type__c + ' instead of: Intake. Logs are:' + logs);
  }
  
  // BEFORE UPDATE TESTS
  
  // Negative: Update to High priority with short description should fail
  @IsTest
  static void testBeforeUpdate_Negative() {
    Case c = buildCase('Low', 'This description is long enough initially.');
    insert c;
    
    c.Priority = 'High';
    c.Description = 'Short';
    
    Test.startTest();
    try {
      update c;
      System.assert(false, 'Expected validation error on update');
    } catch (DmlException e) {
      System.assert(
      e.getMessage().contains('If Priority is High'),
      'Expected validation error message'
      );
    }
    Test.stopTest();
  }
  
  // Positive: Update with valid High priority description
  @IsTest
  static void testBeforeUpdate_Positive() {
    Case c = buildCase('Low', 'This description is long enough initially.');
    insert c;
    
    c.Priority = 'High';
    c.Description = 'This description is definitely longer than thirty characters.';
    
    Test.startTest();
    update c;
    Test.stopTest();
    
    System.assertEquals('High', [SELECT Priority FROM Case WHERE Id = :c.Id].Priority);
  }
  
  // AFTER UPDATE TESTS
  
  // Positive: Change tracked and log created
  @IsTest
  static void testAfterUpdate_LogCreated() {
    Case c = buildCase('Low', 'Original description that is long enough.');
    insert c;
    
    c.Status = 'In Progress';
    c.Subject = 'Updated Subject';
    
    Test.startTest();
    update c;
    Test.stopTest();
    
    List<Case_Activity__c> logs = [
      SELECT Activity_Type__c, Context__c
      FROM Case_Activity__c
      WHERE Case__c = :c.Id
      AND Activity_Type__c = 'Status Change'
    ];
    
    System.assertEquals(1, logs.size(), 'One change log should be created');
    System.assert(logs[0].Context__c.contains('Status'), 'Status change should be tracked');
    System.assert(logs[0].Context__c.contains('Subject'), 'Subject change should be tracked');
  }
  
  // Edge Case: No tracked fields changed therefore no log created
  @IsTest
  static void testAfterUpdate_NoChanges_NoLog() {
    Case c = buildCase('Low', 'Original description that is long enough.');
    insert c;
    
    // Update a field NOT in fieldsToTrack (e.g., Origin)
    c.Origin = 'Email';
    
    Test.startTest();
    update c;
    Test.stopTest();
    
    List<Case_Activity__c> logs = [
      SELECT Id
      FROM Case_Activity__c
      WHERE Case__c = :c.Id
      AND Activity_Type__c = 'Status Changed'
    ];
    
    System.assertEquals(0, logs.size(), 'No log should be created if tracked fields did not change');
  }
  
  // BULK TEST
  
  // Multiple cases inserted & logged
  @IsTest
  static void testBulkInsert() {
    List<Case> cases = new List<Case>();
    for (Integer i = 0; i < 100; i++) {
      cases.add(buildCase('Low', 'Bulk test description long enough #' + i));
    }
    
    Test.startTest();
    insert cases;
    Test.stopTest();
    
    Integer logCount = [
      SELECT COUNT()
      FROM Case_Activity__c
      WHERE Case__c IN :cases
    ];
    
    System.assertEquals(100, logCount, 'Each case should create one log');
  }
  
  // USER TEST

  // Run as Agent

  // Run as Supervisor
}