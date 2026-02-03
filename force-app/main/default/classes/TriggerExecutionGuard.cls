public class TriggerExecutionGuard {
    private static Set<String> processed = new Set<String>();

    public static Boolean alreadyProcessed(Set<Id> ids, String key) {
        // Returns true if we've already processed this set for this key in this transaction
        String composite = key + ':' + String.valueOf(ids);
        if (processed.contains(composite)) return true;
        processed.add(composite);
        return false;
    }

    public static Boolean alreadyProcessed(Id id, String key) {
        String composite = key + ':' + String.valueOf(id);
        if (processed.contains(composite)) return true;
        processed.add(composite);
        return false;
    }

    @TestVisible
    static void clear() { processed.clear(); }
}