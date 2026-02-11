// Name: Jay Cina
// Date: 02/05/26
// Desc: LWC data-retrieval functions for the caseConsole LWC

public with sharing class CaseConsoleController {
  
  // Returns the Cases the user has access to in SF database
  @AuraEnabled(cacheable=true)
  public static List<CaseDTO> getCases() {
    List<CaseDTO> results = new List<CaseDTO>();
    for (Case c : [
    SELECT Id, CaseNumber, RecordType.Name, OwnerId, Description, Priority, SLA_Target__c, SLAViolation__c, Status, Subject, Triage_Category__c,
    Case_Provider__c,
    AccountId, ContactId, ContactPhone, Contact.Name
    FROM Case
    //WITH USER_MODE
    ]) {
      CaseDTO dto = new CaseDTO();
      dto.Id = c.Id;
      dto.CaseNumber = c.CaseNumber;
      dto.Status = c.Status;
      dto.Priority = c.Priority;
      dto.RecordTypeName = c.RecordType.Name != null ? c.RecordType.Name : null;
      dto.ContactId = c.ContactId != null ? c.ContactId : null;
      dto.ContactName = c.Contact != null ? c.Contact.Name : null;
      dto.SLATarget = c.SLA_Target__c != null ? c.SLA_Target__c : null;
      
      results.add(dto);
    }
    
    return results;
  }
}