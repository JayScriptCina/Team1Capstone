// Name: Jay Cina
// Date: 02/05/26
// Desc: LWC data-retrieval functions for the caseConsole LWC

public with sharing class CaseConsoleController {
  
  // Returns the Cases the user has access to in SF database
  @AuraEnabled(cacheable=true)
  public static List<CaseDTO> getCases() {
    List<CaseDTO> results = new List<CaseDTO>();
    for (Case c : [
    SELECT Id, CaseNumber, RecordType.Name, OwnerId, Description, Priority, SLA_Target__c, SLAViolation__c, Status, Subject, Triage_Category__c, SLA_Status__c,
    Case_Provider__c,
    AccountId, ContactId, ContactPhone, Contact.Name
    FROM Case
    WITH USER_MODE
    ]) {
      CaseDTO dto = new CaseDTO();
      dto.Id = c.Id;
      dto.OwnerId = c.OwnerId;
      dto.CaseNumber = c.CaseNumber;
      dto.Status = c.Status;
      dto.Priority = c.Priority;
      dto.RecordTypeName = c.RecordType.Name != null ? c.RecordType.Name : null;
      dto.ContactId = c.ContactId != null ? c.ContactId : null;
      dto.ContactName = c.Contact != null ? c.Contact.Name : null;
      dto.SLATarget = c.SLA_Target__c != null ? c.SLA_Target__c : null;
      dto.SLAStatus = c.SLA_Status__c != null ? c.SLA_Status__c : null;
      
      results.add(dto);
    }
    
    return results;
  }

  @AuraEnabled(cacheable=true)
  public static List<Case_Provider__c> getCaseProviders() {
    
    return [SELECT Id, Case__c, Provider__c,
    Provider__r.Name__c, Provider__r.Phone__c, Provider__r.Location__c, Provider__r.Distance_Miles__c, Provider__r.Capacity_Status__c,
    Provider__r.Service_Category__c, Provider__r.Specialty__c, Provider__r.Rating__c, Provider__r.Accepting_New_Patients__c
    FROM Case_Provider__c
    WITH USER_MODE
    ];
  }
}