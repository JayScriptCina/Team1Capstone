// Name: Jay Cina
// Date: 02/04/2026
// Desc: A countdown UI based on the date provided
import { LightningElement, api, track } from 'lwc';

export default class SlaCountdown extends LightningElement {
  
  @track _date;
  @track days = 0;
  @track hours = 0;
  @track minutes = 0;
  @track seconds = 0;
  @track isExpired = false;
  
  timerInterval;

  @api
  get date() {
    return this._date;
  }
  set date(value) {
    this.clearCountdown();
    this._date = value

    if(value) {
      this.startCountdown();
    }
  }

  startCountdown() {
    clearInterval(this.timerInterval); // prevent multiple timers

    const endTime = new Date(this._date.value).getTime();
    console.log('_date is:', this._date)
    
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

  clearCountdown() {
    this.days = 0;
    this.hours = 0;
    this.minutes = 0;
    this.seconds = 0;
    this.isExpired = false;

    clearInterval(this.timerInterval);
  }
}