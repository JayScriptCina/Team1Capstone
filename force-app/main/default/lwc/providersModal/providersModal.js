import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import NAME_FIELD from '@salesforce/schema/Provider__c.Name__c';
import PHONE_NUMBER_FIELD from '@salesforce/schema/Provider__c.Phone__c';
import RATING_FIELD from '@salesforce/schema/Provider__c.Rating__c';
import SERVICE_CATEGORY_FIELD from '@salesforce/schema/Provider__c.Service_Category__c';
import SPECIALTY_FIELD from '@salesforce/schema/Provider__c.Specialty__c';
import getProviders from '@salesforce/apex/ProviderInteractionController.getProviders';
// import setProvider from '@salesforce/apex/ProviderInteractionController.setProvider';
const COLUMNS = [
  { label: 'Provider Name', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
  { label: 'Rating', fieldName: RATING_FIELD.fieldApiName, type: 'text'},
  { label: 'Phone Number', fieldName: PHONE_NUMBER_FIELD.fieldApiName, type: 'text'},
  { label: 'Service Category', fieldName: SERVICE_CATEGORY_FIELD.fieldApiName, type: 'text'},
  { label: 'Speciality', fieldName: SPECIALTY_FIELD.fieldApiName, type: 'text'}
];

export default class ProvidersModal extends LightningModal {
  @api caseId; // case selected from parent
  providerSelected;

  providersData = []
  sortedProviders = [] 

  columns = COLUMNS;
  defaultSortDirection = 'desc';
  sortDirection = 'desc';
  sortedBy;

  @wire(getProviders, { caseId: '$caseId'})
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

  handleSelect() {
    // return the provider object
    this.close({ status: 'success', providerId: this.providerSelected });
  }

  handleCancel() {
    this.close('cancel')
  }
}