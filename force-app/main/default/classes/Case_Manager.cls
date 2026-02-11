// Name: Jay Cina
// Date: 02/10/26
// Desc: Logic for case creation and insertion

public with sharing class Case_Manager {
  
  public static void beforeInsert(List<Case> newCases) {
    enforceRules(newCases);
  }
  
  public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
    enforceRules(newCases);
  }
  
  private static void enforceRules(List<Case> casesToCheck) {
    for (Case c : casesToCheck) {
      Boolean isHigh = (c.Priority == 'High');
      Integer len = (c.Description == null) ? 0 : c.Description.trim().length();
      
      if (isHigh && len < 30) {
        // Stop the record from being created/saved and displays the following error message to the user
        c.addError('If Priority is High, Description must be at least 30 characters.');
      }
    }
  }
  
  public static void afterInsert(List<Case> newCases) {
    // A Record Triggered flow should create an Intake Activity!
  }
  
  public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
    
    List<Case_Activity__c> logs = new List<Case_Activity__c>();
    
    List<String> fieldsToTrack = new List<String>{
      'Status', 'Priority', 'Subject', 'Description'
    };

    List<String> changes = new List<String>();
    
    for (Case c : newCases) {
      // Store values that have changed
      Case oldC = oldMap.get(c.Id);
      
      // Loop thru the fields we track and compare
      for (String fieldName : fieldsToTrack) {
        Object newVal = c.get(fieldName);
        Object oldVal = oldC.get(fieldName);
        
        if (newVal != oldVal) {
          changes.add(fieldName + ': "' + String.valueOf(oldVal) + '" → "' + String.valueOf(newVal) + '"');
        }
      }
      
      // Create a Case_Activity__c where Activity Type = "Status Changed" 
      if (!changes.isEmpty()) {
        Case_Activity__c logRec = new Case_Activity__c();
        logRec.Case__c = c.Id;
        logRec.Activity_Type__c = 'Status Change';
        logRec.Context__c = String.join(changes, ' | ');
        logs.add(logRec);
      }
    }
    
    if (!logs.isEmpty()) {
      insert logs;
    }
  }
}