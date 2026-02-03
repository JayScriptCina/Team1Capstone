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

    @AuraEnabled(cacheable=true)
    public static List<Case_Provider__c> getCaseProviders() {
        return [
            SELECT Id, Provider_Name__c, Phone_Number__c, Rating__c, Service_Category__c, Specialty__c
            FROM Case_Provider__c
            ORDER BY Rating__c
        ];
    }
}