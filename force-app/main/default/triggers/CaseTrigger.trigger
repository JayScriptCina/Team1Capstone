trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
  CaseTriggerHandler.run(Trigger.operationType);
}