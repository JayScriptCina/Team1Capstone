import { LightningElement, track } from 'lwc';

export default class DynamicDataTable extends LightningElement {
    // Sample Data
    @track tableData = [
        { id: '1', name: 'John Doe', status: 'Active', email: 'john@example.com', createdDate: '2024-01-10', role: 'Admin' },
        { id: '2', name: 'Jane Smith', status: 'Inactive', email: 'jane@example.com', createdDate: '2023-12-05', role: 'User' },
        { id: '3', name: 'Robert Brown', status: 'Active', email: 'robert@example.com', createdDate: '2024-02-20', role: 'Manager' },
        { id: '4', name: 'Emily Davis', status: 'Pending', email: 'emily@example.com', createdDate: '2023-11-15', role: 'User' }
    ];

    @track filteredData = [...this.tableData];
    @track filters = { name: '', status: '', email: '', createdDate: '', role: '' };

    // Columns Definition
    columns = [
        { label: 'Name', fieldName: 'name', type: 'text' },
        { label: 'Status', fieldName: 'status', type: 'text' },
        { label: 'Email', fieldName: 'email', type: 'email' },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
        { label: 'Role', fieldName: 'role', type: 'text' }
    ];

    // Get unique Status Options
    get statusOptions() {
        return this.getUniqueOptions('status');
    }

    // Get unique Role Options
    get roleOptions() {
        return this.getUniqueOptions('role');
    }

    // Generate unique picklist options dynamically
    getUniqueOptions(field) {
        const uniqueValues = [...new Set(this.tableData.map(item => item[field]))];
        return [{ label: 'All', value: '' }, ...uniqueValues.map(value => ({ label: value, value: value }))];
    }

    // Handle Filter Change
    handleFilterChange(event) {
        const filterType = event.target.dataset.filter;
        const filterValue = event.target.value.toLowerCase();
        
        this.filters = { ...this.filters, [filterType]: filterValue };
        this.applyFilters();
    }

    // Apply Filters to Data
    applyFilters() {
        this.filteredData = this.tableData.filter(item => {
            return (
                (this.filters.name ? item.name.toLowerCase().includes(this.filters.name) : true) &&
                (this.filters.status ? item.status.toLowerCase() === this.filters.status : true) &&
                (this.filters.email ? item.email.toLowerCase().includes(this.filters.email) : true) &&
                (this.filters.createdDate ? item.createdDate === this.filters.createdDate : true) &&
                (this.filters.role ? item.role.toLowerCase() === this.filters.role : true)
            );
        });
    }

    // Reset Filters
    resetFilters() {
        this.filters = { name: '', status: '', email: '', createdDate: '', role: '' };
        this.filteredData = [...this.tableData];

        // Reset UI Inputs
        this.template.querySelectorAll('lightning-input, lightning-combobox').forEach(input => {
            input.value = '';
        });
    }
}