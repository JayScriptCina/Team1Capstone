trigger CaseTrigger on Case (before insert, before update, after insert, after update) {
  Case_Manager.run(Trigger.operationType);
}