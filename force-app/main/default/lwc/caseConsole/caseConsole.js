// Name: Jay Cina
// Date: 02/04/2026
// Desc: A console which displays a dynamic list (caseList) and a details panel (caseDetail) if a case is clicked
// Sources:
//      -> refreshApex() best practices https://salesforcegeek.in/refreshapex-in-lwc/
import { LightningElement, wire, track } from 'lwc';

import CASE_OBJECT from '@salesforce/schema/Case';
import STATUS_FIELD from '@salesforce/schema/Case.Status';
import PRIORITY_FIELD from '@salesforce/schema/Case.Priority';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCases from '@salesforce/apex/CaseController.getCases';

export default class CaseConsole extends LightningElement {
  @track cases = [];
  wiredCasesResult;
  @track statusOptions = [];
  @track priorityOptions = [];
  @track recordTypeOptions = [];
  caseRecordTypeId;
  @track selectedCaseId; // used for displaying data to children based on the selection in the caseList child component
  
  // 1. Get Case data in USER_MODE!
  @wire(getCases)
  wiredCases(result) {
    this.wiredCasesResult = result;
    if(result.data) { // creates a clickable link for Contacts
      this.cases = result.data.map(item => ({
        ...item,
        contactUrl: item.ContactId ? '/' + item.ContactId : null,
        caseUrl: '/' + item.Id
      }));
      console.log('data received from wire:', result.data)
    }
    else if(result.error) {
      console.error("Wire error:", result.error);
    }
  };
  
  // 2. Get the default Record Type ID for Case
  @wire(getObjectInfo, { objectApiName: CASE_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.caseObjectInfo = data;
      this.caseRecordTypeId = data.defaultRecordTypeId;
      
      // Process record types
      const rtis = this.caseObjectInfo.recordTypeInfos;
      // The recordTypeInfos is a map, so iterate over the keys (record type IDs)
      this.recordTypeOptions = Object.keys(rtis).map(typeId => ({
        label: rtis[typeId].name,
        value: rtis[typeId].name,
        id: typeId // metadata
      }));
      console.log('our record type options are', this.recordTypeOptions);
    }
    else if (error) {
      console.error('Error fetching case object info', error);
    }
  }
  
  // 3. Get the picklist values using the Record Type ID and Field Reference
  @wire(getPicklistValues, { 
    recordTypeId: '$caseRecordTypeId', 
    fieldApiName: PRIORITY_FIELD 
  })
  wiredPriorityPicklist({ data, error }) {
    if (data) {
      this.priorityOptions = data.values;
      console.log('Priority Values:', this.priorityOptions);
    } else if (error) {
      console.error('Error fetching priority picklist values', error);
    }
  }
  
  @wire(getPicklistValues, { 
    recordTypeId: '$caseRecordTypeId', 
    fieldApiName: STATUS_FIELD 
  })
  wiredStatusPicklist({ data, error }) {
    if (data) {
      this.statusOptions = [
        { label: 'Not Closed', value: 'Not Closed' },  // adds another value to the picklist
        ...data.values
      ];
      console.log('Priority Values:', this.statusOptions);
    } else if (error) {
      console.error('Error fetching status picklist values', error);
    }
  }
  
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const rowData = event.detail.row;
    
    if(actionName === 'view_details') {
      this.selectedCaseId = rowData.Id;
    }
  }
  
  // Retrieves data used in caseDetail child components
  get recordDetailData() {
    if(!this.selectedCaseId || !this.cases) return null;
    return this.cases.find(c => c.Id === this.selectedCaseId);
  }
  
  handleRefreshButton() {
    refreshApex(this.wiredCasesResult)
    .then(() => {
      console.log('Data refreshed successfully');
    })
    .catch(error => {
      console.error('Error refreshing data:', error);
    });
    console.log('refreshing apex');
    
    this.dispatchEvent(
      new ShowToastEvent({
        title: 'Refreshed Data',
        message: 'The data has been refreshed',
        variant: 'success',
        mode: 'dismissible'
      })
    );
  }

  handleRevokeRecordChange(event) {
    this.selectedCaseId = event.detail;
  }
}