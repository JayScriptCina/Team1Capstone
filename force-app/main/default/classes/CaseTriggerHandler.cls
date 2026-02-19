// Name: Jay Cina
// Date: 02/10/26
// Desc: Logic for case creation and insertion

public without sharing class CaseTriggerHandler {
 
  private static final String SUPERVISOR_QUEUE_DEV_NAME = 'Case_Supervisors_Queue';
  private static Set<Id> resolvedTransferProcessedIds = new Set<Id>();

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
  
  // Log the update in Case_Activity__c object
  public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
    
    List<Case_Activity__c> logs = new List<Case_Activity__c>();
    
    List<String> fieldsToTrack = new List<String>{
      'Status', 'Priority', 'Subject', 'Description'
    };

    List<String> changes = new List<String>();
    
    for (Case c : newCases) {
      Case oldC = oldMap.get(c.Id);
      
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
    // Collect cases that just updated to resolved
    List<Case> casesToTransfer = new List<Case>();
    for (Case c : newCases) {
      Case oldC = oldMap.get(c.Id);
      if (oldC == null) continue;

      Boolean statusJustBecameResolved =
        oldC.Status != 'Resolved' &&
        c.Status == 'Resolved';

      if (statusJustBecameResolved && !resolvedTransferProcessedIds.contains(c.Id)) {
        resolvedTransferProcessedIds.add(c.Id);
        casesToTransfer.add(c);
      }
    }

    if (!casesToTransfer.isEmpty()) {
      // Lookup Supervisor Queue Id by name
      Group supervisorQueue = [
        SELECT Id
        FROM Group
        WHERE Type = 'Queue'
        AND DeveloperName = :SUPERVISOR_QUEUE_DEV_NAME
        LIMIT 1
      ];

      // owner transfer in system context
      List<Case> ownerUpdates = new List<Case>();
      for (Case c : casesToTransfer) {
        ownerUpdates.add(new Case(
          Id = c.Id,
          OwnerId = supervisorQueue.Id
        ));
      }
      Database.update(ownerUpdates, false);
    }
  } 
}
