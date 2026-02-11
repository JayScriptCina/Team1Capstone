trigger CaseTrigger on Case (before insert, before update, after insert, after update) {

  // Before Trigger
  if (Trigger.isBefore) {
    // Insert
    if (Trigger.isInsert) {
      CaseTriggerHandler.beforeInsert(Trigger.new);
    }
    // Update
    else if (Trigger.isUpdate) {
      CaseTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
    } 
  }
  // After Trigger
  else {
    // Insert
    if (Trigger.isInsert) {
      CaseTriggerHandler.afterInsert(Trigger.new);
    }
    // Update
    else if (Trigger.isUpdate) {
      CaseTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
    }
  }
}