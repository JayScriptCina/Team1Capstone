import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class CaseDetail extends LightningElement {
  @api recordData = [];
  @track isEditMode = false;
  
  @api targetDate = '2026-07-25T00:00:00';
  @track days = 0;
  @track hours = 0;
  @track minutes = 0;
  @track seconds = 0;
  @track isExpired = false;
  
  timerInterval;

  @track isSaving = false;
  @track saveButtonLabel = "Save";
  
  connectedCallback() {
    this.startCountdown();
  }
  
  startCountdown() {
    const endTime = new Date(this.targetDate).getTime();
    
    this.timerInterval = setInterval(() => {
      const now = new Date().getTime();
      const distance = endTime - now;
      
      if (distance < 0) {
        clearInterval(this.timerInterval);
        this.isExpired = true;
        return;
      }
      
      // Time calculations
      this.days = Math.floor(distance / (1000 * 60 * 60 * 24));
      this.hours = Math.floor((distance % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
      this.minutes = Math.floor((distance % (1000 * 60 * 60)) / (1000 * 60));
      this.seconds = Math.floor((distance % (1000 * 60)) / 1000);
    }, 1000);
  }

  get recordId() {
    return this.recordData.Id;
  }
  
  handleEdit() {
    this.isEditMode = true;
  }
  
  handleCancel() {
    this.isEditMode = false;
  }

  handleSave() {
    console.log("HandleSave has been called");
    this.saveButtonLabel = 'Saving...';
    this.isSaving = true;
    console.log("HandleSave has reached the end");
  }
  
  handleSuccess() {
    console.log("HandleSuccess has been called");
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

  handleChange(event) {
    console.log(event);
  }
}