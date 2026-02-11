// Name: Jay Cina
// Date: 02/11/26
// Desc: LWC data-retrieval functions for the providerInteraction LWC

public with sharing class ProviderInteractionController {
  
  // Returns the Case Providers the user has access to in SF database
  @AuraEnabled(cacheable=true)
  public static List<Case_Provider__c> getCaseProviders() {
    return [
    SELECT Id, Provider_Name__c, Phone_Number__c, Rating__c, Service_Category__c, Specialty__c
    FROM Case_Provider__c
    WITH USER_MODE
    ORDER BY Rating__c
    ];
  }
}