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
    console.log('date value received:', value);

    if(!value) return;

    this._date = value // 2026-07-25T00:00:00
    console.log('date value is now:', this._date);

    this.startCountdown();
  }

  startCountdown() {
    clearInterval(this.timerInterval); // prevent multiple timers

    const endTime = new Date(this.date).getTime();
    
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
}