//Run: System.enqueueJob(new Case_ExternalProviderService());
 
public with sharing class Case_ExternalProviderService implements Queueable, Database.AllowsCallouts {
    private static final String ENDPOINT = 'callout:Provider_API/provider_data';

    public void execute(QueueableContext qc) {
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(ENDPOINT);
            req.setMethod('GET');

            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() < 200 || res.getStatusCode() >= 300) {
                throw new CalloutException('HTTP ' + res.getStatusCode() + ': ' + res.getBody());
            }

            Object root = JSON.deserializeUntyped(res.getBody());
            if (!(root instanceof List<Object>)) return;

            List<Object> raw = (List<Object>) root;
            if (raw.isEmpty()) return;

            Map<String, String> svcMap  = buildPicklistMap(Provider__c.Service_Category__c);
            Map<String, String> specMap = buildPicklistMap(Provider__c.Specialty__c);
            Map<String, String> capMap  = buildPicklistMap(Provider__c.Capacity_Status__c);
            Map<String, String> rateMap = buildPicklistMap(Provider__c.Rating__c);

            List<Provider__c> toUpsert = new List<Provider__c>();

            for (Object o : raw) {
                if (!(o instanceof Map<String, Object>)) continue;
                Map<String, Object> prov = (Map<String, Object>) o;

 
                String apiRowId = getString(prov, 'id');
                if (String.isBlank(apiRowId)) continue;

                Provider__c p = new Provider__c();

                p.Provider_Id__c = apiRowId;

                p.Provider_External_Id__c = getString(prov, 'provider_id');

                p.Name__c     = left(getString(prov, 'provider_name'), 255);
                p.Phone__c    = getString(prov, 'phone_number');
                p.Location__c = left(getString(prov, 'location'), 255);

                p.Distance_Miles__c = getDecimal(prov, 'distance_miles');

                p.Accepting_New_Patients__c = getBoolean(prov, 'accepting_new_patients');

                p.Service_Category__c = picklistMatch(svcMap,  getString(prov, 'service_category'));
                p.Specialty__c        = picklistMatch(specMap, getString(prov, 'specialty'));
                p.Capacity_Status__c  = picklistMatch(capMap,  getString(prov, 'capacity_status'));
                p.Rating__c           = picklistMatch(rateMap, getString(prov, 'rating')); // star emojis

                toUpsert.add(p);
            }

            if (toUpsert.isEmpty()) return;


            Database.upsert(toUpsert, Provider__c.Provider_Id__c, false);

        } catch (Exception ex) {
            System.debug('Case_ExternalProviderService failed: ' + ex.getMessage());
        }
    }

    private static String getString(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) return null;
        return String.valueOf(m.get(key)).trim();
    }

    private static Boolean getBoolean(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) return false;
        Object v = m.get(key);
        if (v instanceof Boolean) return (Boolean) v;

        String s = String.valueOf(v).trim().toLowerCase();
        return (s == 'true' || s == '1' || s == 'yes');
    }

    private static Decimal getDecimal(Map<String, Object> m, String key) {
        if (m == null || !m.containsKey(key) || m.get(key) == null) return null;

        Object v = m.get(key);
        try {
            if (v instanceof Decimal) return (Decimal) v;
            if (v instanceof Integer) return Decimal.valueOf((Integer) v);
            if (v instanceof Long)    return Decimal.valueOf((Long) v);
            return Decimal.valueOf(String.valueOf(v));
        } catch (Exception e) {
            return null;
        }
    }

    private static String left(String s, Integer maxLen) {
        if (String.isBlank(s)) return s;
        return (s.length() <= maxLen) ? s : s.substring(0, maxLen);
    }


    private static Map<String, String> buildPicklistMap(Schema.SObjectField f) {
        Map<String, String> out = new Map<String, String>();

        for (Schema.PicklistEntry pe : f.getDescribe().getPicklistValues()) {
            if (pe == null) continue;

            String val = pe.getValue();
            String lab = pe.getLabel();

            if (!String.isBlank(val)) out.put(val.trim().toLowerCase(), val);
            if (!String.isBlank(lab)) out.put(lab.trim().toLowerCase(), val);
        }
        return out;
    }


    private static String picklistMatch(Map<String, String> allowed, String raw) {
        if (String.isBlank(raw) || allowed == null) return null;

        String key = raw.trim().toLowerCase();
        return allowed.containsKey(key) ? allowed.get(key) : null;
    }

    private class CalloutException extends Exception {}
}