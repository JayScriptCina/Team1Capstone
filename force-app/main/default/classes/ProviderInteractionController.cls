// Name: Jay Cina
// Date: 02/11/26
// Desc: LWC data-retrieval functions for the providerInteraction LWC

public with sharing class ProviderInteractionController {
  
  public class ActionResponse {
    @AuraEnabled public Boolean success;
    @AuraEnabled public String message;

    public ActionResponse(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }


  //** Returns the Case Providers the user has access to in SF database
  @AuraEnabled(cacheable=true)
  public static List<Provider__c> getProviders(Id caseId) {
    
    Case c = [
    SELECT Id, Triage_Category__c
    FROM Case
    WHERE Id = :caseId
    LIMIT 1
    ];

    if (c.Triage_Category__c == null) {
      return new List<Provider__c>();
    }
    
    return [
    SELECT Id, Name__c, Phone__c, Location__c, Distance_Miles__c, Capacity_Status__c, Service_Category__c, Specialty__c, Rating__c, Accepting_New_Patients__c
    FROM Provider__c
    WHERE Service_Category__c=:c.Triage_Category__c AND Accepting_New_Patients__c=true
    WITH USER_MODE
    ORDER BY Rating__c DESC
    ];
  }
  
  //** Creates a Case_Provider__c connection between a case and selected provider(s). Inserts a Case_Activity__c log to finish
  @AuraEnabled
  public static ActionResponse setProviders(Id caseId, List<Id> providerIds) {

    if (providerIds == null || providerIds.isEmpty()) {
      return new ActionResponse(false, 'No providers selected');
    }
    
    // Query Case & Provider
    Case c = [
    SELECT Id, Status
    FROM Case
    WHERE Id = :caseId
    LIMIT 1
    ];

    List<Provider__c> providers = [
    SELECT Id, Accepting_New_Patients__c
    FROM Provider__c
    WHERE Id IN :providerIds
    ];

    // Check for duplicates
    Set<Id> existingProviderIds = new Set<Id>();
    for (Case_Provider__c cp : [
      SELECT Provider__c
      FROM Case_Provider__c
      WHERE Case__c = :c.Id
      AND Provider__c IN :providerIds
    ]) {
      existingProviderIds.add(cp.Provider__c);
    }

    List<Case_Provider__c> linksToInsert = new List<Case_Provider__c>();

    for (Provider__c p : providers) {
      if (
        p.Accepting_New_Patients__c &&
        !existingProviderIds.contains(p.Id)
      ) {
        linksToInsert.add(new Case_Provider__c(
          Case__c = c.Id,
          Provider__c = p.Id
        ));
      }
    }

    if (linksToInsert.isEmpty()) {
      return new ActionResponse(
        false,
        'All selected providers are either already attached or not accepting patients'
      );
    }

    // Insert Case_Provider__c records
    try {
      insert as user linksToInsert;
    } catch (Exception e) {
      System.debug('Error inserting Case Providers: ' + e.getMessage());
      return new ActionResponse(false, 'Failed to attach providers');
    }
    
    // Create Case_Activity__c for case
    try {
      insert as user new Case_Activity__c(
        Activity_Type__c = 'Provider Lookup',
        Case__c = c.Id,
        Context__c = linksToInsert.size() + ' provider(s) attached to this case'
      );
    }
    catch (Exception e) {
      System.debug('Error inserting Case Activity: ' + e.getMessage());
      return new ActionResponse(false, 'Providers attached, but activity failed');
    }
    
    // Change case status to In Progress -> this will trigger the after update case activity creation as well
    if (c.Status != 'In Progress') {
      c.Status = 'In Progress';
      update as user c;
    }
    
    return new ActionResponse(
      true,
      linksToInsert.size() + ' provider(s) successfully attached'
    );
  }
}