public class Case_ExternalProviderService implements Queueable, Database.AllowsCallouts {

    private Set<Id> caseIds;

    public Case_ExternalProviderService(Set<Id> caseIds) {
        this.caseIds = caseIds;
    }

    public void execute(QueueableContext qc) {
        List<Case> casesToProcess = [
            SELECT Id, Subject, Description
            FROM Case
            WHERE Id IN :caseIds
        ];

        List<Case> updates = new List<Case>();

        for (Case c : casesToProcess) {
            try {
                HttpRequest req = new HttpRequest();
                // Must match your Named Credential name
                req.setEndpoint('callout:My_Named_Credential/external/case');
                req.setMethod('POST');
                req.setHeader('Content-Type', 'application/json');

                req.setBody(JSON.serialize(new Map<String, Object>{
                    'caseId' => c.Id,
                    'subject' => c.Subject,
                    'description' => c.Description
                }));

                Http http = new Http();
                HttpResponse res = http.send(req);

                if (res.getStatusCode() >= 200 && res.getStatusCode() < 300) {
                    Map<String, Object> payload =
                        (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                    // Map provider response to Case_Provider__c
                    c.Case_Provider__c = (String) payload.get('providerId');
                    updates.add(c);
                } else {
                    throw new CalloutException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
                }

            } catch (Exception ex) {
                // Centralized error logging
                Case_ErrorHandler.handle(ex, c.Id, 'Case_ExternalProviderService.execute');
            }
        }

        if (!updates.isEmpty()) {
            update updates;
        }
    }

    private class CalloutException extends Exception {}
}