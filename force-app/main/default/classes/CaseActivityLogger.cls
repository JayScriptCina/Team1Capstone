// Name: Jay Cina
// Date: 02/18/26
// Desc: Helper class to allow Case_Activity__c objects to be inserted in system context

public without sharing class CaseActivityLogger {

  public class LogResult {
    public Boolean success;
    public String message;

    public LogResult(Boolean success, String message) {
      this.success = success;
      this.message = message;
    }
  }

    public static LogResult createAttachProvidersLog(Case c, List<Case_Provider__c> caseProviders, Map<Id, Provider__c> providerById) {
      // Gather Provider names
      String contextString = '';

      for (Case_Provider__c cp : caseProviders) {
        Provider__c p = providerById.get(cp.Provider__c);
        if (p != null) {
          contextString += '\nId: ' + p.Id + ', Name: ' + p.Name__c;
        }
      }

      try {
        insert new Case_Activity__c(
          Activity_Type__c = 'Provider Lookup',
          Case__c = c.Id,
          Context__c = caseProviders.size() + ' provider(s) attached to this case: ' + contextString
        );
        return new LogResult(true, null);
      }
      catch (Exception e) {
        System.debug('Error inserting Case Activity: ' + e.getMessage());
        return new LogResult(false, 'Activity log creation failed');
      }
    }
}