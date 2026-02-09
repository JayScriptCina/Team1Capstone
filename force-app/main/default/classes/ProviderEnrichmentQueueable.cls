// Name: Razam Zaman, Jay Cina

// Desc: Upserts case providers which are attached to the contact Ids queued in Set<Id> caseIds

public with sharing class ProviderEnrichmentQueueable implements Queueable, Database.AllowsCallouts {
  private final Set<Id> caseIds;
  
  public ProviderEnrichmentQueueable(Set<Id> caseIds) {
    this.caseIds = caseIds == null ? new Set<Id>() : caseIds.clone();
  }
  
  public void execute(QueueableContext qc) {
    // if (caseIds.isEmpty()) return;
    
    // Only query standard fields to avoid compile errors if custom fields don't exist yet.
    List<Case> cases = [
    SELECT Id
    FROM Case
    WHERE Id IN :caseIds
    ];
    
    List<Case> updates = new List<Case>(); // what is updates for?
    List<Case_Provider__c> providerUpserts = new List<Case_Provider__c>(); // this is the List we store provider data to upsert at the end
    
    for (Case c : cases) {
      
      // Read Provider_Id__c dynamically so this compiles even if the field isn't present.
      String providerId;
      try {
        providerId = (String) c.get('Provider_Id__c');
      } catch (Exception e) {
        providerId = null;
      }
      
      if (String.isBlank(providerId)) continue; // continue ends this iteration of the loop, moving to the next record
      
      // Build a "partial update" record. Safer than updating the queried record.
      Case upd = new Case(Id = c.Id);
      Case_Provider__c cp = new Case_Provider__c();
      
      // Fetch the provider
      try {
        ProviderDataDTO dto = ProviderDataService.fetchByProviderId(providerId);
        
        if (dto == null) {
          // create a Case_Activity__c Provider Not Found error for the current case
        } else {
          // Update Provider fields
          try { cp.put('Provider_Name__c', dto.provider_name); } catch (Exception ignore) {}
          try { cp.put('Specialty__c', dto.specialty); } catch (Exception ignore) {}
          try { cp.put('Location__c', dto.location); } catch (Exception ignore) {}
          try { cp.put('Phone_Number__c', dto.phone_number); } catch (Exception ignore) {}
          try { cp.put('Rating__c', dto.rating); } catch (Exception ignore) {}
          try { cp.put('Distance_Miles__c', dto.distance_miles); } catch (Exception ignore) {}
          try { cp.put('Capacity_Status__c', dto.capacity_status); } catch (Exception ignore) {}
          try { cp.put('Service_Category__c', dto.service_category); } catch (Exception ignore) {}
          try { cp.put('Accepting_New_Patients__c', dto.accepting_new_patients); } catch (Exception ignore) {}
          
          cp.Case__c = c.Id;
          
          // Setting our external id for duplicate prevention using upsert
          cp.put('External_Id__c', dto.id);
          
          // cp.put('Provider_Case_Key__c', providerCaseKey);
          
          providerUpserts.add(cp);
        }
        
        updates.add(upd);
        
      } catch (ProviderDataService.ProviderServiceException pex) {
        // create a Case_Activity__c error for the current case
        updates.add(upd);
      } catch (Exception ex) {
        // create a Case_Activity__c error for the current case
        updates.add(upd);
      }
    }
    
    if (!updates.isEmpty()) {
      update updates;
    }
    
    // Bulk-safe upsert: prevents duplicates using the External_Id__c field 
    if (!providerUpserts.isEmpty()) {
      upsert providerUpserts External_Id__c;
    }
  }
}