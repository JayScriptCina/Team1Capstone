public class Case_ErrorHandler {

    public class Result {
        public Boolean success;
        public String userMessage;
        public Id activityId;

        public Result(Boolean success, String userMessage, Id activityId) {
            this.success = success;
            this.userMessage = userMessage;
            this.activityId = activityId;
        }
    }

    public static Result handle(Exception ex, Id caseId, String context) {
        String userMessage =
            'An error occurred while processing this Case. Reference: ' + caseId;

        Case_Activity__c logRec = new Case_Activity__c();
        logRec.Case__c = caseId;
        logRec.Activity_Type__c = 'Error';
        logRec.Error_Message__c = ex.getMessage();
        logRec.Stack_Trace__c = ex.getStackTraceString();
        logRec.Context__c = context;

        try {
            insert logRec;
            return new Result(false, userMessage, logRec.Id);
        } catch (Exception loggingEx) {
            // If logging fails, still return user-friendly message
            return new Result(false, userMessage, null);
        }
    }
}