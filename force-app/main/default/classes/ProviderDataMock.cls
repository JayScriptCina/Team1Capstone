@IsTest
global class ProviderDataMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String body = '[' +
            '{' +
              '"id":1,' +
              '"rating":"⭐️",' +
              '"location":"Danbury, Connecticut, United States",' +
              '"specialty":"mental health",' +
              '"provider_id":"user_634",' +
              '"phone_number":"(555) 473-6703",' +
              '"provider_name":"Twitter",' +
              '"distance_miles":97,' +
              '"capacity_status":"limited",' +
              '"service_category":"medical",' +
              '"accepting_new_patients":true' +
            '},' +
            '{' +
              '"id":2,' +
              '"rating":"⭐️⭐️⭐️⭐️",' +
              '"location":"Redmond, Washington, United States",' +
              '"specialty":"surgical",' +
              '"provider_id":"user_876",' +
              '"phone_number":"(555) 221-3613",' +
              '"provider_name":"Valero Energy",' +
              '"distance_miles":70,' +
              '"capacity_status":"available",' +
              '"service_category":"nutrition",' +
              '"accepting_new_patients":false' +
            '}' +
        ']';

        res.setBody(body);
        return res;
    }
}