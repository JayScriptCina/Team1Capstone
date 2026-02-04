public with sharing class ProviderEnrichmentQueueable implements Queueable, Database.AllowsCallouts {
    private final Set<Id> caseIds;

    public ProviderEnrichmentQueueable(Set<Id> caseIds) {
        this.caseIds = caseIds == null ? new Set<Id>() : caseIds.clone();
    }

    public void execute(QueueableContext qc) {
        if (caseIds.isEmpty()) return;

        // IMPORTANT: Only query standard fields to avoid compile errors if custom fields don't exist yet.
        List<Case> cases = [
            SELECT Id
            FROM Case
            WHERE Id IN :caseIds
        ];

        List<Case> updates = new List<Case>();

        for (Case c : cases) {

            // Read Provider_Id__c dynamically so this compiles even if the field isn't present.
            String providerId;
            try {
                providerId = (String) c.get('Provider_Id__c');
            } catch (Exception e) {
                providerId = null;
            }

            if (String.isBlank(providerId)) continue;

            // Build a "partial update" record. Safer than updating the queried record.
            Case upd = new Case(Id = c.Id);

            try {
                ProviderDataDTO dto = ProviderDataService.fetchByProviderId(providerId);

                if (dto == null) {
                    try { upd.put('Provider_Enrichment_Status__c', 'Failed'); } catch (Exception ignore) {}
                    // CaseActivityLogger.log(c.Id, 'Provider Lookup', 'Failed', 'Not found: ' + providerId);
                } else {
                    try { upd.put('Provider_Name__c', dto.provider_name); } catch (Exception ignore) {}
                    try { upd.put('Provider_Specialty__c', dto.specialty); } catch (Exception ignore) {}
                    try { upd.put('Provider_Location__c', dto.location); } catch (Exception ignore) {}
                    try { upd.put('Provider_Phone__c', dto.phone_number); } catch (Exception ignore) {}
                    try { upd.put('Provider_Rating__c', dto.rating); } catch (Exception ignore) {}
                    try { upd.put('Provider_Distance_Miles__c', dto.distance_miles); } catch (Exception ignore) {}
                    try { upd.put('Provider_Capacity_Status__c', dto.capacity_status); } catch (Exception ignore) {}
                    try { upd.put('Provider_Service_Category__c', dto.service_category); } catch (Exception ignore) {}
                    try { upd.put('Provider_Accepting_New__c', dto.accepting_new_patients); } catch (Exception ignore) {}
                    try { upd.put('Provider_Last_Enriched__c', System.now()); } catch (Exception ignore) {}
                    try { upd.put('Provider_Enrichment_Status__c', 'Success'); } catch (Exception ignore) {}
                    // CaseActivityLogger.log(c.Id, 'Provider Lookup', 'Success', 'Enriched');
                }

                updates.add(upd);

            } catch (ProviderDataService.ProviderServiceException pex) {
                try { upd.put('Provider_Enrichment_Status__c', 'Failed'); } catch (Exception ignore) {}
                updates.add(upd);
                // CaseActivityLogger.log(c.Id, 'Provider Lookup', 'Failed', pex.getMessage());
            } catch (Exception ex) {
                try { upd.put('Provider_Enrichment_Status__c', 'Failed'); } catch (Exception ignore) {}
                updates.add(upd);
                // CaseActivityLogger.log(c.Id, 'Provider Lookup', 'Failed', ex.getMessage());
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }
}