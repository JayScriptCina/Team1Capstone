import { LightningElement, api, track } from 'lwc';

export default class CaseActivityDetail extends LightningElement {
  _recordData;
  
  @api
  get recordData() {
    return this._recordData;
  }
  set recordData(value) {
    if(!value) return;

    this._recordData = value;
    console.log('_recordData in caseActivityDetail.js has been updated');
  }

  get recordId() {
    console.log("recordData from get recordId:", this.recordData);
    return this._recordData?.Id;
  }
}