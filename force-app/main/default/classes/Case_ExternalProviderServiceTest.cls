/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an org are executed whenever Apex code is deployed
 * to a production org to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production org. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the org size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@IsTest
private class Case_ExternalProviderServiceTest {
    @IsTest static void testQueueableFetchProviders_insertsAndDedupes() {
        // Create a Case (include any required fields for your org)
        Case c = new Case(
            Subject = 'Provider Lookup Test',
            Status  = 'New'
        );
        insert c;

        // Set the HTTP callout mock
        Test.setMock(HttpCalloutMock.class, new ProviderDataMock());

        Test.startTest();
            // Enqueue the queueable with the case id
            System.enqueueJob(new Case_ExternalProviderService(new Set<Id>{c.Id}));
        Test.stopTest();

        // Query the inserted provider records
        List<Case_Provider__c> providers = [
            SELECT Case__c, Provider_Id__c, Provider_Name__c, Location__c,
                   Specialty__c, Phone_Number__c, Capacity_Status__c,
                   Service_Category__c, Accepting_New_Patients__c, Rating__c
            FROM Case_Provider__c
            WHERE Case__c = :c.Id
            ORDER BY Provider_Id__c
        ];

        System.assertEquals(2, providers.size(), 'Should insert two providers');

        // Validate first provider
        Case_Provider__c p1 = providers[0];
        System.assertEquals('user_634', p1.Provider_Id__c);
        System.assertEquals('Twitter', p1.Provider_Name__c);
        System.assertEquals('(555) 473-6703', p1.Phone_Number__c);
        System.assertEquals('limited', p1.Capacity_Status__c);
        System.assertEquals('medical', p1.Service_Category__c);
        System.assertEquals(true, p1.Accepting_New_Patients__c);
        System.assertEquals('⭐️', p1.Rating__c);

        // Validate second provider
        Case_Provider__c p2 = providers[1];
        System.assertEquals('user_876', p2.Provider_Id__c);
        System.assertEquals('Valero Energy', p2.Provider_Name__c);
        System.assertEquals('(555) 221-3613', p2.Phone_Number__c);
        System.assertEquals('available', p2.Capacity_Status__c);
        System.assertEquals('nutrition', p2.Service_Category__c);
        System.assertEquals(false, p2.Accepting_New_Patients__c);
        System.assertEquals('⭐️⭐️⭐️⭐️', p2.Rating__c);

        // Now run the queueable again to verify dedupe (no new rows)
        Test.startTest();
            System.enqueueJob(new Case_ExternalProviderService(new Set<Id>{c.Id}));
        Test.stopTest();

        List<Case_Provider__c> providersAfter = [
            SELECT Id FROM Case_Provider__c WHERE Case__c = :c.Id
        ];
        System.assertEquals(2, providersAfter.size(), 'Rerun should not create duplicates');
    }
}
