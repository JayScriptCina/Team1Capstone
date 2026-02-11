// Name: Jay Cina
// Date: 02/10/2026
// Desc: Determines which Apex logic to run depending on the operation

public with sharing class CaseTriggerHandler {
  
  //private static Boolean hasRun = false;
  
  public static void run(System.TriggerOperation op) {
    //if(hasRun) return; // prevents duplicate execution
    //hasRun = true;
    
    List<Case> newList = (List<Case>) Trigger.new;
    Map<Id, Case> oldMap = (Map<Id, Case>) Trigger.oldMap;
    
    switch on op {
      when BEFORE_INSERT {
        Case_Manager.beforeInsert(newList);
      }
      when BEFORE_UPDATE {
         Case_Manager.beforeUpdate(newList, oldMap);
      }
      when AFTER_INSERT {
        Case_Manager.afterInsert(newList);
      }
      when AFTER_UPDATE {
        Case_Manager.afterUpdate(newList, oldMap);
      }
    }
  }
}