@IsTest
private class Case_ExternalProviderServiceTest {

    @IsTest
    static void testQueueableFetchProviders_upsertsAndDedupes() {

        Test.setMock(HttpCalloutMock.class, new ProviderDataMock());

        Test.startTest();
            System.enqueueJob(new Case_ExternalProviderService());
            System.enqueueJob(new Case_ExternalProviderService());
        Test.stopTest();

        List<Provider__c> providers = [
            SELECT Provider_Id__c,
                   Provider_External_Id__c,
                   Name__c,
                   Phone__c,
                   Location__c,
                   Distance_Miles__c,
                   Capacity_Status__c,
                   Service_Category__c,
                   Specialty__c,
                   Accepting_New_Patients__c,
                   Rating__c
            FROM Provider__c
            WHERE Provider_Id__c IN ('1', '2')
            ORDER BY Provider_Id__c
        ];

        System.assertEquals(2, providers.size(),
            'Running twice should result in exactly 2 Provider__c rows both APIS');

        Map<String, Provider__c> byId = new Map<String, Provider__c>();
        for (Provider__c p : providers) byId.put(String.valueOf(p.Provider_Id__c), p);

        Provider__c p1 = byId.get('1');
        System.assertNotEquals(null, p1);
        System.assertEquals('user_634', p1.Provider_External_Id__c);
        System.assertEquals('Twitter', p1.Name__c);
        System.assertEquals('(555) 473-6703', p1.Phone__c);
        System.assertEquals(97, p1.Distance_Miles__c.intValue());
        assertEqualsIgnoreCase('limited', p1.Capacity_Status__c);
        assertEqualsIgnoreCase('medical', p1.Service_Category__c);
        assertEqualsIgnoreCase('mental health', p1.Specialty__c);
        System.assertEquals(true, p1.Accepting_New_Patients__c);
        System.assertEquals('⭐️', p1.Rating__c);

        Provider__c p2 = byId.get('2');
        System.assertNotEquals(null, p2);
        System.assertEquals('user_876', p2.Provider_External_Id__c);
        System.assertEquals('Valero Energy', p2.Name__c);
        System.assertEquals('(555) 221-3613', p2.Phone__c);
        System.assertEquals(70, p2.Distance_Miles__c.intValue());
        assertEqualsIgnoreCase('available', p2.Capacity_Status__c);
        assertEqualsIgnoreCase('nutrition', p2.Service_Category__c);
        assertEqualsIgnoreCase('surgical', p2.Specialty__c);
        System.assertEquals(false, p2.Accepting_New_Patients__c);
        System.assertEquals('⭐️⭐️⭐️⭐️', p2.Rating__c);
    }

    private static void assertEqualsIgnoreCase(String expected, String actual) {
        System.assertEquals(
            expected == null ? null : expected.trim().toLowerCase(),
            actual == null ? null : actual.trim().toLowerCase()
        );
    }
} 
