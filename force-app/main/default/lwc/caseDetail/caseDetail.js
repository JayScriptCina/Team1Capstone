import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseDetail extends LightningElement {
  @track _recordData;
  @track isEditMode = false;
  @track isSaving = false;
  @track isDirty = false;
  @track saveButtonLabel = "Save";
  
  @api
  get recordData() {
    return this._recordData;
  }
  set recordData(value) {
    if (this.isDirty) {
      this.showUnsavedDataToast();
      return;
    }

    if(!value) return;
    this._recordData = value
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
    this.showSavedDataToast();
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