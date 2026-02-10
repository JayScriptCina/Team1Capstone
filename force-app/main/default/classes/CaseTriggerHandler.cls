// Name: Jay Cina
// Date: 02/10/26
// Desc: Enforces data quality: high priority cases must have a description of 30 length
//        Creates Case_Activity__c logs upon Case creation or field changes (upsert/update)

public class CaseTriggerHandler {

    public static void beforeInsert(List<Case> newCases) {
        enforceRule(newCases);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        enforceRule(newCases);
    }

    private static void enforceRule(List<Case> casesToCheck) {
        for (Case c : casesToCheck) {
            Boolean isHigh = (c.Priority == 'High');
            Integer len = (c.Description == null) ? 0 : c.Description.trim().length();

            if (isHigh && len < 30) {
                c.addError('If Priority is High, Description must be at least 30 characters.');
            }
        }
    }

    public static void afterInsert(List<Case> newCases) {
      List<Case_Activity__c> casesToInsert = new List<Case_Activity__c>();

      for (Case c : newCases) {
        // Create a Case_Activity__c where Activity Type = "Intake" 
        Case_Activity__c logRec = new Case_Activity__c();
        logRec.Case__c = c.Id;
        logRec.Activity_Type__c = 'Intake';
        logRec.Context__c = 'Case created';

        casesToInsert.add(logRec);
      }

      insert casesToInsert;
      
    }


    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
      List<Case_Activity__c> casesToInsert = new List<Case_Activity__c>();

      for (Case c : newCases) {
  

        // Determine which values have changed from the oldMap to newCases

        // Create a Case_Activity__c where Activity Type = "Status Changed" 
        Case_Activity__c logRec = new Case_Activity__c();
        logRec.Case__c = c.Id;
        logRec.Activity_Type__c = 'Status Changed';
        logRec.Context__c = 'Case values changed';

        casesToInsert.add(logRec);
      }

      insert casesToInsert;
    }
}