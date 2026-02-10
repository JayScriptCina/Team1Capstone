// ProviderDataService.cls
public with sharing class ProviderDataService {

    // === CONFIG ===
    // Update this constant if your Named Credential has a different API name
    private static final String NC = 'Provider_Data_API';

    // Custom exception for clearer error handling in calling code
    public class ProviderServiceException extends Exception {}

    /**
     * Fetch provider info by provider_id.
     * - Calls the Named Credential endpoint: callout:Provider_Data_API/provider_data
     * - Parses the JSON array, returns the first matching ProviderDataDTO or null.
     *
     * Throws ProviderServiceException on callout / HTTP / parse failures so callers can handle it.
     */
    public static ProviderDataDTO fetchByProviderId(String providerId) {
        if (String.isBlank(providerId)) return null;

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:' + NC + '/provider_data');
        req.setMethod('GET');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(20000); // Explicit timeout (ms)

        Http http = new Http();
        HttpResponse res;
        try {
            res = http.send(req);
        } catch (CalloutException ce) {
            // Wrap with domain-specific exception
            throw new ProviderServiceException('Callout failed: ' + ce.getMessage());
        }

        Integer statusCode = res.getStatusCode();
        if (statusCode < 200 || statusCode > 299) {
            throw new ProviderServiceException('Provider API returned HTTP ' + statusCode);
        }

        String body = res.getBody();
        if (String.isBlank(body)) {
            return null;
        }

        List<ProviderDataDTO> records;
        try {
            records = (List<ProviderDataDTO>) JSON.deserialize(body, List<ProviderDataDTO>.class);
        } catch (Exception je) {
            throw new ProviderServiceException('Failed to parse provider API response: ' + je.getMessage());
        }

        // Find matching provider_id (exact match)
        for (ProviderDataDTO dto : records) {
            if (dto != null && dto.provider_id != null && dto.provider_id == providerId) {
                return dto;
            }
        }

        // Not found
        return null;
    }

    /**
     * Optional helper: safe fetch that returns a Result wrapper object
     * (Useful if you prefer no exceptions across async boundaries)
     */
    public class Result {
        public ProviderDataDTO dto;
        public Boolean success;
        public String errorMessage;
    }

    public static Result safeFetch(String providerId) {
        Result r = new Result();
        try {
            r.dto = fetchByProviderId(providerId);
            r.success = true;
        } catch (ProviderServiceException ex) {
            r.success = false;
            r.errorMessage = ex.getMessage();
        } catch (Exception ex) {
            r.success = false;
            r.errorMessage = ex.getMessage();
        }
        return r;
    }
}