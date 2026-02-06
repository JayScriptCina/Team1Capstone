import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseDetail extends LightningElement {
  @api recordData;
  @track isEditMode = false;
  @track isSaving = false;
  @track saveButtonLabel = "Save";
  

  get recordId() {
    console.log("recordData from get recordId:", this.recordData);
    return this.recordData?.Id;
  }

  get SLATargetDate() {
    return this.recordData?.SLATarget || null;
  }
  
  handleEdit() {
    this.isEditMode = true;
  }
  
  handleCancel() {
    this.isEditMode = false;
  }

  handleSave() {
    this.saveButtonLabel = 'Saving...';
    this.isSaving = true;
  }
  
  handleSuccess() {
    this.isEditMode = false;
    this.isSaving = false;
    // TO-DO: show toast and reload cache
    this.showToast();
  }
  
  showToast() {
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