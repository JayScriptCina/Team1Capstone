public class CaseDTO {
  @AuraEnabled public Id Id;
  @AuraEnabled public String CaseNumber;
  @AuraEnabled public String Status;
  @AuraEnabled public String Priority;
  @AuraEnabled public String RecordTypeName;
  @AuraEnabled public String ContactId;
  @AuraEnabled public String ContactName;
  @AuraEnabled public Datetime SLATarget;
}