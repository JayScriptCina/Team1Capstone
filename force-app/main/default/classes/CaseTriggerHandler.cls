public class CaseTriggerHandler {

    public static void beforeInsert(List<Case> newCases) {
        enforceRule(newCases);
    }

    public static void beforeUpdate(List<Case> newCases, Map<Id, Case> oldMap) {
        enforceRule(newCases);
    }

    private static void enforceRule(List<Case> casesToCheck) {
        for (Case c : casesToCheck) {
            Boolean isHigh = (c.Priority == 'High');
            Integer len = (c.Description == null) ? 0 : c.Description.trim().length();

            if (isHigh && len < 30) {
                c.addError('If Priority is High, Description must be at least 30 characters.');
            }
        }
    }

    public static void afterInsert(List<Case> newCases) { }
    public static void afterUpdate(List<Case> newCases, Map<Id, Case> oldMap) { }
}