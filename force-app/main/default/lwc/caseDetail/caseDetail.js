import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import ProvidersModal from 'c/providersModal';

export default class CaseDetail extends LightningElement {
  _recordData;
  @track isEditMode = false;
  @track isSaving = false;
  @track isDirty = false;
  @track saveButtonLabel = "Save";
    
  @api
  get recordData() {
    return this._recordData;
  }
  set recordData(value) {
    // When "More Details" is clicked for a different Case, unsaved data shouldn't be lost
    if (this.isDirty) {
      if(value != this._recordData) { // if the incoming value matches, this means it has been already revoked and should not be called again
        dispatchEvent(CustomEvent('revokerecordchange', {
          detail: this._recordData.Id
        }));
        this.showUnsavedDataToast();
      }
      return;
    }
    
    // When "More Details" is clicked for a different Case, Edit mode should disable
    if(this.isEditMode) {
      this.handleCancel();
    }
    
    if(!value) return;
    
    this._recordData = value;
    console.log('_recordData in caseDetail.js has been updated');
  }
  
  get recordId() {
    console.log("recordData from get recordId:", this.recordData);
    return this._recordData?.Id;
  }
  
  get SLATargetDate() {
    return this._recordData?.SLATarget || null;
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
    this.showSavedDataToast();
    this.handleRefresh();
  }
  
  handleRefresh() {
    this.dispatchEvent(new CustomEvent('refreshbutton'));
  }
  
  async handleFindProviders() {
    // Call the provider modal class
    const result = await ProvidersModal.open({
      caseId: this._recordData.Id
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