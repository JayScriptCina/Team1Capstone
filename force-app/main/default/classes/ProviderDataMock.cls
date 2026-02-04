@IsTest
public class ProviderDataMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
        HttpResponse res = new HttpResponse();
        res.setStatusCode(200);
        res.setHeader('Content-Type', 'application/json');

        String body = '[{"id":1,"rating":"⭐️","location":"Danbury, Connecticut, United States",' +
            '"specialty":"mental health","provider_id":"user_634","phone_number":"(555) 473-6703",' +
            '"provider_name":"Twitter","distance_miles":97,"capacity_status":"limited","service_category":"medical",' +
            '"accepting_new_patients":true}]';

        res.setBody(body);
        return res;
    }
}