@IsTest
public class ProviderInteractionControllerTest {

  @TestSetup
  static void setupData() {

    Id medicalRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
    .get('Medical')
    .getRecordTypeId();

    // Create Case
    Case c = new Case(
      Subject = 'Test Case',
      Status = 'New',
      Origin = 'Phone',
      RecordTypeId = medicalRecordTypeId
    );
    insert c;

    // Create Providers
    List<Provider__c> providers = new List<Provider__c>{
      new Provider__c(
        Name__c = 'Provider A',
        Service_Category__c = 'medical',
        Accepting_New_Patients__c = true,
        Rating__c = '⭐️⭐️⭐️⭐️'
      ),
      new Provider__c(
        Name__c = 'Provider B',
        Service_Category__c = 'medical',
        Accepting_New_Patients__c = false,
        Rating__c = '⭐️⭐️⭐️'
      )
    };
    insert providers;
  }

  //** Get  Providers */

  @IsTest
  static void testGetProviders_withCategory() {
    Case c = [SELECT Id FROM Case LIMIT 1];

    Test.startTest();
    List<Provider__c> results =
      ProviderInteractionController.getProviders(c.Id);
    Test.stopTest();

    System.assertEquals(1, results.size(),
      'Only accepting providers should be returned');
  }

  @IsTest
  static void testGetProviders_noCategory() {
    Case c = new Case(
      Subject = 'No Category',
      Status = 'New',
      Origin = 'Email'
    );
    insert c;

    Test.startTest();
    List<Provider__c> results =
      ProviderInteractionController.getProviders(c.Id);
    Test.stopTest();

    System.assertEquals(0, results.size(),
      'No providers should be returned if triage category is null');
  }

  //** Set Providers */
  @IsTest
  static void testSetProviders_noProvidersSelected() {
    Case c = [SELECT Id FROM Case LIMIT 1];

    ProviderInteractionController.ActionResponse result =
      ProviderInteractionController.setProviders(c.Id, new List<Id>());

    System.assertEquals(false, result.success);
    System.assertEquals('No providers selected', result.message);
  }

  @IsTest
  static void testSetProviders_success() {
    Case c = [SELECT Id, Status FROM Case LIMIT 1];
    Provider__c p = [
      SELECT Id FROM Provider__c
      WHERE Accepting_New_Patients__c = true
      LIMIT 1
    ];

    Test.startTest();
    ProviderInteractionController.ActionResponse result =
      ProviderInteractionController.setProviders(
        c.Id,
        new List<Id>{ p.Id }
      );
    Test.stopTest();

    System.assertEquals(true, result.success);
    System.assert(result.message.contains('successfully attached'));

    // Verify Case_Provider__c
    System.assertEquals(
      1,
      [SELECT COUNT() FROM Case_Provider__c WHERE Case__c = :c.Id]
    );

    // Verify Case Status update
    c = [SELECT Status FROM Case WHERE Id = :c.Id];
    System.assertEquals('In Progress', c.Status);
  }

  @IsTest
  static void testSetProviders_duplicateProvider() {
    Case c = [SELECT Id FROM Case LIMIT 1];
    Provider__c p = [
      SELECT Id FROM Provider__c
      WHERE Accepting_New_Patients__c = true
      LIMIT 1
    ];

    // Insert first link
    insert new Case_Provider__c(
      Case__c = c.Id,
      Provider__c = p.Id
    );

    Test.startTest();
    ProviderInteractionController.ActionResponse result =
      ProviderInteractionController.setProviders(
        c.Id,
        new List<Id>{ p.Id }
      );
    Test.stopTest();

    System.assertEquals(false, result.success);
    System.assert(
      result.message.contains('already attached') ||
      result.message.contains('not accepting'),
      'Duplicate provider should be blocked'
    );
  }
}
