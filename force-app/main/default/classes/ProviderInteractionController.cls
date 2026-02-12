// Name: Jay Cina
// Date: 02/11/26
// Desc: LWC data-retrieval functions for the providerInteraction LWC

public with sharing class ProviderInteractionController {
  
  // Returns the Case Providers the user has access to in SF database
  @AuraEnabled(cacheable=true)
  public static List<Provider__c> getProviders(Case c) {
    return [
    SELECT Id, Name__c, Phone__c, Location__c, Distance_Miles__c, Capacity_Status__c, Service_Category__c, Specialty__c, Rating__c, Accepting_New_Patients__c
    FROM Provider__c
    WHERE Service_Category__c=:c.Triage_Category__c AND Accepting_New_Patients__c=true
    WITH USER_MODE
    ORDER BY Rating__c
    ];
  }

  public static String setProviders(Case c, Provider__c p) {
    // Ensure accepting patients is true
    if (p.Accepting_New_Patients__c != true) {
      return 'This provider is currently not accepting patients. Please choose another';
    }

    // Create Case_Provider__c relationship between c and providers
    Case_Provider__c cp = new Case_Provider__c();
    cp.Case__c = c.Id;
    cp.Provider__c = p.Id;

    try {
      insert as user cp;
    }
    catch (Exception e) {
      System.debug('Error inserting Case Provider: ' + e.getMessage());
      return 'Error inserting Case Provider';
    }

    // Create Case_Activity__c for case
    Case_Activity__c ca = new Case_Activity__c();
    ca.Activity_Type__c = 'Provider Lookup';
    ca.Case__c = c.Id;
    ca.Context__c = 'A Provider has been attached to this case'; // Can make this more detailed!

    try {
      insert as user ca;
    }
    catch (Exception e) {
      System.debug('Error inserting Case Activity: ' + e.getMessage());
      return 'Error inserting Case Activity';
    }
    
    // Change case status to In Progress -> this will trigger the after update case activity creation as well
    c.Status = 'In Progress';
    update as user c;

    return 'Success'; // should return true is process finishes
  }
}