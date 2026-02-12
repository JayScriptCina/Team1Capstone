// Name: Jay Cina
// Date: 02/12/26
// Desc: LWC data-retrieval functions for the caseTimeline LWC

public with sharing class CaseTimelineController {
  
  @AuraEnabled(cacheable=true)
  public static List<Case_Activity__c> getCaseActivities() {
    List<Case_Activity__c> results = new List<Case_Activity__c>();
    
    // Note: Should LIMIT the query below to future proof this design!
    return [
    SELECT Id, Activity_Type__c, Name, Context__c, CreatedById, CreatedDate, Description__c, Error_Message__c, LastModifiedById, Stack_Trace__c,
    Case__r.CaseNumber
    FROM Case_Activity__c
    WITH USER_MODE
    ORDER BY CreatedDate DESC
    ];
  }
}