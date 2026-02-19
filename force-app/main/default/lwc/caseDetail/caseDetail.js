import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ProvidersModal from 'c/providersModal';

import { getRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';

import CASE_NUMBER_FIELD from '@salesforce/schema/Case.CaseNumber';
import RECORD_TYPE_NAME_FIELD from '@salesforce/schema/Case.RecordType.Name';
import OWNER_FIELD from '@salesforce/schema/Case.OwnerId';
import DESCRIPTION_FIELD from '@salesforce/schema/Case.Description';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import SUBJECT_FIELD from '@salesforce/schema/Case.Subject';
import SLA_TARGET_FIELD from '@salesforce/schema/Case.SLA_Target__c';
import SLA_VIOLATION_FIELD from '@salesforce/schema/Case.SLAViolation__c';
import SLA_STATUS_FIELD from '@salesforce/schema/Case.SLA_Status__c';
import APPROVAL_STATUS_FIELD from '@salesforce/schema/Case.Approval_Status__c';
import SEND_FOR_APPROVAL_FIELD from '@salesforce/schema/Case.Send_for_Approval__c';
import TRIAGE_CATEGORY_FIELD from '@salesforce/schema/Case.Triage_Category__c';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Case.AccountId';
import CONTACT_ID_FIELD from '@salesforce/schema/Case.ContactId';
import CONTACT_PHONE_FIELD from '@salesforce/schema/Case.ContactPhone';
import CONTACT_NAME_FIELD from '@salesforce/schema/Case.Contact.Name';





export default class CaseDetail extends LightningElement {
  @api recordId;
  wiredCase;

  @wire(getRecord, {
    recordId: '$recordId',
    fields: [
      STATUS_FIELD,
      CASE_NUMBER_FIELD,
      RECORD_TYPE_NAME_FIELD,
      OWNER_FIELD,
      DESCRIPTION_FIELD,
      PRIORITY_FIELD,
      SLA_TARGET_FIELD,
      SLA_VIOLATION_FIELD,
      SUBJECT_FIELD,
      TRIAGE_CATEGORY_FIELD,
      SLA_STATUS_FIELD,
      APPROVAL_STATUS_FIELD,
      SEND_FOR_APPROVAL_FIELD,
      ACCOUNT_ID_FIELD,
      CONTACT_ID_FIELD,
      CONTACT_PHONE_FIELD,
      CONTACT_NAME_FIELD
    ]
  })
  wiredCaseRecord(result) {
    console.log('wiredCaseResult:', result);
    this.wiredCase = result;
    if (result.data) {
      this._recordData = result.data;
      this.handleCancel();
    }
  }

  // Public method exposed to the parent component
  @api
  handleRefreshApex() {
    // Logic to be executed when called by the parent
    console.log('Handle Refresh Apex function was called by the parent into caseDetail.js');
    refreshApex(this.wiredCase); // reset cache for lightning edit form
    console.log('finished resetting apex caseDetail.js');
  }

  @track _recordData;
  _caseProviderData;
  @track isEditMode = false;
  @track isSaving = false;
  @track isDirty = false;
  @track saveButtonLabel = "Save";
  // @api
  // get recordData() {
  //   return this._recordData;
  // }
  // set recordData(value) {
  //   // When "More Details" is clicked for a different Case, unsaved data shouldn't be lost
  //   if (this.isDirty) {
  //     if(value != this._recordData) { // if the incoming value matches, this means it has been already revoked and should not be called again
  //       dispatchEvent(CustomEvent('revokerecordchange', {
  //         detail: this._recordData.Id
  //       }));
  //       this.showUnsavedDataToast();
  //     }
  //     return;
  //   }
    
  //   // When "More Details" is clicked for a different Case, Edit mode should disable
  //   if(this.isEditMode) {
  //     this.handleCancel();
  //   }
    
  //   if(!value) return;
    
  //   this._recordData = value;
  //   console.log('_recordData in caseDetail.js has been updated');
  // }

  @api
  get caseProviderData() {
    return this._caseProviderData;
  }
  set caseProviderData(value) {
    this._caseProviderData = value
    console.log('_caseProviderData in caseDetail.js has been updated');
  }

  get caseProviderList() {
    return this._caseProviderData[0];
  }
  
  // get recordId() {
  //   console.log("recordData from get recordId:", this.recordData);
  //   return this._recordData?.Id;
  // }
  
  get SLATargetDate() {
    return this._recordData?.fields.SLA_Target__c || null;
  }
  
  get isSaveDisabled() {
    return !this.isDirty || this.isSaving;
  }
  
  handleFieldChange() {
    console.log('field change identified');
    this.isDirty = true;
  }
  
  handleEdit() {
    this.isEditMode = true;
  }
  
  handleCancel() {
    this.isDirty = false;
    this.isEditMode = false;
  }
  
  handleSave() {
    this.saveButtonLabel = 'Saving...';
    this.isSaving = true;
  }
  
  handleSuccess() {
    this.isDirty = false;
    this.isEditMode = false;
    this.isSaving = false;
    this.saveButtonLabel = 'Save';

    refreshApex(this.wiredCase); // reset cache for lightning edit form

    this.showSavedDataToast();
    this.handleRefresh();
  }

  handleError(event) {
    console.error('Error in form submission', event);
    // This will display the error in the console

    this.isSaving = false;
    this.saveButtonLabel = 'Save';

    this.dispatchEvent(
      new ShowToastEvent({
        title: 'There was a problem',
        message: event.detail.detail,
        variant: 'error',
        mode: 'dismissible'
      })
    );
}
  
  handleRefresh() {
    this.dispatchEvent(new CustomEvent('refreshbutton'));
  }
  
  async handleFindProviders() {
    // Call the provider modal class
    console.log('finding providers with this._recordData.Id:', this._recordData, ' normal recordId:', this.recordId);
    const result = await ProvidersModal.open({
      caseId: this.recordId
    });

    if (result.status === 'success') {
      this.handleRefresh();
    }
  }
  
  showUnsavedDataToast() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Unsaved Changes',
        message: 'You have unsaved data. Please save before navigating away.',
        variant: 'warning',
        mode: 'dismissible'
      })
    );
  }
  
  showSavedDataToast() {
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Success',
        message: 'Case updated successfully',
        variant: 'success',
        mode: 'dismissable'
      })
    );
  }
}