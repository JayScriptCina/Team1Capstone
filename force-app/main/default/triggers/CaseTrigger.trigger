trigger CaseTrigger on Case (before insert, before update, after insert, after update) {

    /*****************************************************************
     * BEFORE: Apex-enforced business rules
     *****************************************************************/
    if (Trigger.isBefore) {
        for (Case c : Trigger.new) {
            // Business Rule:
            // If Priority = High, Description must be >= 30 characters
            if (c.Priority == 'High') {
                Integer len = (c.Description == null) ? 0 : c.Description.trim().length();
                if (len < 30) {
                    c.addError('If Priority is High, Description must be at least 30 characters.');
                }
            }
        }
    }

    /*****************************************************************
     * AFTER: Orchestration (Flow + Apex operations)
     * - Keep callouts async via Queueable (handled inside Case_Manager)
     *****************************************************************/
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            Case_Manager.processAfterSave(Trigger.new, null, 'Case_afterInsert');
        }
        if (Trigger.isUpdate) {
            Case_Manager.processAfterSave(Trigger.new, Trigger.oldMap, 'Case_afterUpdate');
        }
    }
}