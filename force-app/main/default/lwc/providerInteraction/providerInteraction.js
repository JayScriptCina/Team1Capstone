import { LightningElement, wire } from 'lwc';
import NAME_FIELD from '@salesforce/schema/Case_Provider__c.Provider_Name__c';
import PHONE_NUMBER_FIELD from '@salesforce/schema/Case_Provider__c.Phone_Number__c';
import RATING_FIELD from '@salesforce/schema/Case_Provider__c.Rating__c';
import SERVICE_CATEGORY_FIELD from '@salesforce/schema/Case_Provider__c.Service_Category__c';
import SPECIALTY_FIELD from '@salesforce/schema/Case_Provider__c.Specialty__c';
import getCaseProviders from '@salesforce/apex/Case_Manager.getCaseProviders';
const COLUMNS = [
  { label: 'Rating', fieldName: RATING_FIELD.fieldApiName, type: 'text'},
  { label: 'Provider Name', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
  { label: 'Phone Number', fieldName: PHONE_NUMBER_FIELD.fieldApiName, type: 'text'},
  { label: 'Service Category', fieldName: SERVICE_CATEGORY_FIELD.fieldApiName, type: 'text'},
  { label: 'Speciality', fieldName: SPECIALTY_FIELD.fieldApiName, type: 'text'}
];

export default class ProviderInteraction extends LightningElement {
  providersData = []
  sortedProviders = []

  columns = COLUMNS;
  defaultSortDirection = 'desc';
  sortDirection = 'desc';
  sortedBy;

  @wire(getCaseProviders)
  wiredRequests({ data, error}) {
    if(data) {
      this.providersData = data;
      this.sortedProviders = [...data];
      console.log('data:', data)
    }
    else if(error) {
      console.error("Wire error:", error);
    }
  }; 
  
  get hasData() {
    return this.sortedProviders && this.sortedProviders.length > 0;
  }
  
  get errors() {
    return this.providersData.error ? reduceErrors(this.providersData.error) : [];
  }

  onHandleSort(event) {

  }

  handleFindProviders(event) {
    
  }
}