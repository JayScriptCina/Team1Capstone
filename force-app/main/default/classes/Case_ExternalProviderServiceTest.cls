@IsTest
private class Case_ExternalProviderServiceTest {

    @IsTest
    static void testQueueableFetchProviders_upsertsAndDedupes() {

        Test.setMock(HttpCalloutMock.class, new ProviderDataMock());

        Test.startTest();
            System.enqueueJob(new Case_ExternalProviderService());
        Test.stopTest();

        List<Provider__c> providers = [
            SELECT Id,
                   Provider_External_Id__c,
                   Provider_Id__c,
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
            WHERE Provider_External_Id__c IN ('user_634', 'user_876')
            ORDER BY Provider_External_Id__c
        ];

        System.assertEquals(2, providers.size(), 'Should upsert two Provider__c records');

        // --- Provider 1 ---
        Provider__c p1 = providers[0];
        System.assertEquals('user_634', p1.Provider_External_Id__c);
        System.assertEquals('1', String.valueOf(p1.Provider_Id__c), 'API "id" should map to Provider_Id__c');

        // Exact compare (you asked for this)
        System.assertEquals('Twitter', p1.Name__c);

        System.assertEquals('(555) 473-6703', p1.Phone__c);
        System.assert(!String.isBlank(p1.Location__c), 'Location should be populated');

        // Distance_Miles__c is TEXT in your org (based on your earlier compiler error)
        System.assertEquals('97', String.valueOf(p1.Distance_Miles__c));

        // Picklists: compare case-insensitively (because stored value may be "Medical" while API is "medical")
        assertEqualsIgnoreCase('limited', p1.Capacity_Status__c);
        assertEqualsIgnoreCase('medical', p1.Service_Category__c);
        assertEqualsIgnoreCase('mental health', p1.Specialty__c);

        System.assertEquals(true, p1.Accepting_New_Patients__c);

        // Rating stores actual stars (exact compare)
        System.assertEquals('⭐️', p1.Rating__c);

        // --- Provider 2 ---
        Provider__c p2 = providers[1];
        System.assertEquals('user_876', p2.Provider_External_Id__c);
        System.assertEquals('2', String.valueOf(p2.Provider_Id__c));

        // Exact compare (as requested)
        System.assertEquals('Valero Energy', p2.Name__c);

        System.assertEquals('(555) 221-3613', p2.Phone__c);

        assertEqualsIgnoreCase('available', p2.Capacity_Status__c);
        assertEqualsIgnoreCase('nutrition', p2.Service_Category__c);
        assertEqualsIgnoreCase('surgical', p2.Specialty__c);

        System.assertEquals(false, p2.Accepting_New_Patients__c);
        System.assertEquals('⭐️⭐️⭐️⭐️', p2.Rating__c);

        // Re-run to confirm upsert/dedupe (no duplicates created)
        Test.startTest();
            System.enqueueJob(new Case_ExternalProviderService());
        Test.stopTest();

        Integer countAfter = [
            SELECT COUNT()
            FROM Provider__c
            WHERE Provider_External_Id__c IN ('user_634', 'user_876')
        ];
        System.assertEquals(2, countAfter, 'Rerun should not create duplicate Provider__c records');
    }

    // Helper for case-insensitive comparisons (DO NOT prefix with System.)
    private static void assertEqualsIgnoreCase(String expected, String actual) {
        System.assertEquals(
            expected == null ? null : expected.trim().toLowerCase(),
            actual == null ? null : actual.trim().toLowerCase()
        );
    }
}