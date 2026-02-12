// Name: Jay Cina
// Date: 02/04/2026
// Desc: A timeline which displays a dynamic list (caseActivityList) and details panel (caseActivityDetail) if a case activity is clicked
import { LightningElement, wire, track } from 'lwc';

import CASE_ACTIVITY_OBJECT from '@salesforce/schema/Case_Activity__c';
import ACTIVITY_TYPE_FIELD from '@salesforce/schema/Case_Activity__c.Activity_Type__c';

import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getCaseActivities from '@salesforce/apex/CaseTimelineController.getCaseActivities';

export default class CaseTimeline extends LightningElement {
  @track activities = [];
  wiredActivitiesResult;
  @track activityTypeOptions = [];
  activityRecordTypeId;
  @track selectedActivityId; // used for displaying data to children based on the selection in the caseActivityList child component
  
  // 1. Get Case Activity data in USER_MODE!
  @wire(getCaseActivities)
  wiredActivities(result) {
    this.wiredActivitiesResult = result;
    if(result.data) { // creates a clickable link for Case
        this.activities = result.data.map(item => ({
          ...item,
          CaseNumber: item.Case__r?.CaseNumber
        }));
        console.log('data received from wire:', result.data);
      }
      else if(result.error) {
        console.error("Wire error:", result.error);
      }
    };
  
  // 2. Get the default Record Type ID for Case Activity
  @wire(getObjectInfo, { objectApiName: CASE_ACTIVITY_OBJECT })
  objectInfo({ data, error }) {
    if (data) {
      this.activityObjectInfo = data;
      this.activityRecordTypeId = data.defaultRecordTypeId;
    }
    else if (error) {
      console.error('Error fetching case activity object info', error);
    }
  }
  
  // 3. Get the picklist values using the Record Type ID and Field Reference
  @wire(getPicklistValues, { 
    recordTypeId: '$activityRecordTypeId', 
    fieldApiName: ACTIVITY_TYPE_FIELD
  })
  wiredPriorityPicklist({ data, error }) {
    if (data) {
      this.activityTypeOptions = data.values;
      console.log('Activity Type Values:', this.activityTypeOptions);
    } else if (error) {
      console.error('Error fetching activity type picklist values', error);
    }
  }
  
  handleRowAction(event) {
    const actionName = event.detail.action.name;
    const rowData = event.detail.row;
    
    if(actionName === 'view_details') {
      this.selectedActivityId = rowData.Id;
    }
  }
  
  // Retrieves data used in caseActivityDetail child components
  get recordDetailData() {
    if(!this.selectedActivityId || !this.activities) return null;
    return this.activities.find(a => a.Id === this.selectedActivityId);
  }
  
  handleRefreshButton() {
    refreshApex(this.wiredActivitiesResult)
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
    this.selectedActivityId = event.detail;
  }
}