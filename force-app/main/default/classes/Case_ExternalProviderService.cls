public with sharing class Case_ExternalProviderService implements Queueable, Database.AllowsCallouts {
    private Set<Id> caseIds;

    public Case_ExternalProviderService(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext qc) {
        if (caseIds == null || caseIds.isEmpty()) return;

        List<Case> casesToProcess = [
            SELECT Id, Subject, Description
            FROM Case
            WHERE Id IN :caseIds
        ];

        // Query existing providers for all cases in one go
        Map<Id, Set<String>> existingKeysByCase = new Map<Id, Set<String>>();
        for (Case_Provider__c cp : [
            SELECT Case__c, Provider_Id__c, Provider_Name__c
            FROM Case_Provider__c
            WHERE Case__c IN :caseIds
        ]) {
            Id cid = cp.Case__c;
            if (!existingKeysByCase.containsKey(cid)) existingKeysByCase.put(cid, new Set<String>());
            String key = !String.isBlank(cp.Provider_Id__c) ? cp.Provider_Id__c : cp.Provider_Name__c;
            if (!String.isBlank(key)) existingKeysByCase.get(cid).add(key);
        }

        List<Case_Provider__c> toInsert = new List<Case_Provider__c>();

        // Perform callout per case (Queueable allows callouts)
        for (Case c : casesToProcess) {
            try {
                HttpRequest req = new HttpRequest();
                // Use your Named Credential (base URL) and append the relative path
                req.setEndpoint('callout:Provider_API/provider_data');
                req.setMethod('GET');
                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                    throw new CalloutException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
                }

                // parse JSON array
                List<Object> raw = (List<Object>) JSON.deserializeUntyped(res.getBody());
                if (raw == null || raw.isEmpty()) continue;

                Set<String> existingKeys = existingKeysByCase.containsKey(c.Id) ? existingKeysByCase.get(c.Id) : new Set<String>();

                for (Object o : raw) {
                    Map<String, Object> prov = (Map<String, Object>) o;
                    String providerId = prov.containsKey('provider_id') && prov.get('provider_id') != null
                        ? String.valueOf(prov.get('provider_id')) : null;
                    String providerName = prov.containsKey('provider_name') && prov.get('provider_name') != null
                        ? String.valueOf(prov.get('provider_name')) : null;

                    // Build dedupe key preferring providerId
                    String dedupeKey = !String.isBlank(providerId) ? providerId : providerName;
                    if (String.isBlank(dedupeKey)) continue;

                    if (existingKeys.contains(dedupeKey)) continue; // skip duplicates

                    Case_Provider__c cp = new Case_Provider__c();
                    cp.Case__c = c.Id;
                    cp.Provider_Id__c = providerId;
                    cp.Provider_Name__c = providerName;
                    cp.Location__c = prov.containsKey('location') ? String.valueOf(prov.get('location')) : null;
                    cp.Specialty__c = prov.containsKey('specialty') ? String.valueOf(prov.get('specialty')) : null;
                    cp.Phone_Number__c = prov.containsKey('phone_number') ? String.valueOf(prov.get('phone_number')) : null;
                    cp.Capacity_Status__c = prov.containsKey('capacity_status') ? String.valueOf(prov.get('capacity_status')) : null;
                    cp.Service_Category__c = prov.containsKey('service_category') ? String.valueOf(prov.get('service_category')) : null;
                    cp.Accepting_New_Patients__c = prov.containsKey('accepting_new_patients') && prov.get('accepting_new_patients') != null
                        ? (Boolean) prov.get('accepting_new_patients') : null;

                    cp.Rating__c = prov.get('rating') == null ? null : String.valueOf(prov.get('rating'));

                    toInsert.add(cp);
                    existingKeys.add(dedupeKey);
                }

            } catch (Exception ex) {
                // centralized error handling (you already have Case_ErrorHandler)
                
                Case_ErrorHandler.handle(ex, c.Id, 'Case_ExternalProviderService.execute');
    
            }
        } // end cases loop

        if (!toInsert.isEmpty()) {
            // bulk insert
            insert toInsert;
        }
    }

    private class CalloutException extends Exception {}
}