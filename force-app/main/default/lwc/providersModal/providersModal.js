import { api, wire } from 'lwc';
import LightningModal from 'lightning/modal';
import NAME_FIELD from '@salesforce/schema/Provider__c.Name__c';
import PHONE_NUMBER_FIELD from '@salesforce/schema/Provider__c.Phone__c';
import RATING_FIELD from '@salesforce/schema/Provider__c.Rating__c';
import SERVICE_CATEGORY_FIELD from '@salesforce/schema/Provider__c.Service_Category__c';
import SPECIALTY_FIELD from '@salesforce/schema/Provider__c.Specialty__c';
import getProviders from '@salesforce/apex/ProviderInteractionController.getProviders';
import setProviders from '@salesforce/apex/ProviderInteractionController.setProviders';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const COLUMNS = [
  { label: 'Provider Name', fieldName: NAME_FIELD.fieldApiName, type: 'text' },
  { label: 'Rating', fieldName: RATING_FIELD.fieldApiName, type: 'text'},
  { label: 'Phone Number', fieldName: PHONE_NUMBER_FIELD.fieldApiName, type: 'text'},
  { label: 'Service Category', fieldName: SERVICE_CATEGORY_FIELD.fieldApiName, type: 'text'},
  { label: 'Speciality', fieldName: SPECIALTY_FIELD.fieldApiName, type: 'text'}
];

export default class ProvidersModal extends LightningModal {
  @api caseId; // case selected from parent
  selectedProviders = [];
  
  providersData = [];
  sortedProviders = [];
  
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
  
  get selectButtonDisabled() {
    return this.selectedProviders.length < 1;
  }
  
  handleRowSelection(event) {
    this.selectedProviders = event.detail.selectedRows;
    console.log('Selected providers:', this.selectedProviders);
  }
  
  async handleSelect() {
    const providerIds = this.selectedProviders.map(p => p.Id);
    
    // Call Apex
    try {
      const result = await setProviders({
        caseId: this.caseId,
        providerIds: providerIds
      });

      if (result.success) {
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Success',
            message: result.message,
            variant: 'success',
          })
          // refresh console(s)
        );
        this.close('success');
      } else { // result is false
        this.dispatchEvent(
          new ShowToastEvent({
            title: 'Error',
            message: result.message,
            variant: 'error'
          })
        );
      }
    } catch (error) {
      console.log('Error in apex:', error);
    //   this.dispatchEvent(
    //     new ShowToastEvent({
    //       title: 'Error',
    //       message: error.body?.message || 'Unknown error occurred',
    //       variant: 'error'
    //     })
    //   );
    }
    
    // return the provider object
    //this.close({ status: 'success', providerId: this.providerSelected });
  }
  
  handleCancel() {
    this.close({ status: 'cancel' });
  }
}