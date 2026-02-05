public with sharing class Case_Manager {

    // After-save orchestration entrypoint
    public static void processAfterSave(List<Case> newCases, Map<Id, Case> oldMap, String contextKey) {
        Set<Id> toCallout = new Set<Id>();

        for (Case c : newCases) {
            if (c.Id == null) continue;

            // Idempotent guard
            if (TriggerExecutionGuard.alreadyProcessed(c.Id, contextKey)) continue;

            Boolean shouldCall = false;

            if (oldMap == null) {
                // After insert
                shouldCall = true;
            } else if (oldMap.containsKey(c.Id)) {
                // After update example condition: Priority changed
                Case oldC = oldMap.get(c.Id);
                if (c.Priority != oldC.Priority) {
                    shouldCall = true;
                }
            }

            if (shouldCall) toCallout.add(c.Id);

            // Flow orchestration hook (optional):
            // If you have an autolaunched Flow you want to run here, tell me the Flow API name.
        }

        if (!toCallout.isEmpty()) {
            System.enqueueJob(new Case_ExternalProviderService(toCallout));
        }
    }

    /* LWC data-retrieval functions below - Jay Cina */

    // Returns the Case Providers the user has access to in SF database
    // used in providerInteraction LWC
    @AuraEnabled(cacheable=true)
    public static List<Case_Provider__c> getCaseProviders() {
        return [
            SELECT Id, Provider_Name__c, Phone_Number__c, Rating__c, Service_Category__c, Specialty__c
            FROM Case_Provider__c
            WITH USER_MODE
            ORDER BY Rating__c
        ];
    }

    public class CaseDTO {
        @AuraEnabled public Id Id;
        @AuraEnabled public String CaseNumber;
        @AuraEnabled public String Status;
        @AuraEnabled public String Priority;
        @AuraEnabled public String RecordTypeName;
        @AuraEnabled public String ContactId;
        @AuraEnabled public Datetime SLATarget;
    }

    // Returns the Cases the user has access to in SF database
    // Used in caseConsole LWC
    @AuraEnabled(cacheable=true)
    public static List<CaseDTO> getCases() {
        List<CaseDTO> results = new List<CaseDTO>();
        for (Case c : [
            SELECT Id, CaseNumber, RecordType.Name, OwnerId, Description, Priority, SLA_Target__c, SLAViolation__c, Status, Subject, Triage_Category__c,
            Case_Provider__c,
            AccountId, ContactId, ContactPhone
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
            dto.SLATarget = c.SLA_Target__c != null ? c.SLA_Target__c : null;

            results.add(dto);
            }

        return results;
    }
}