({
    init : function(component, event, helper) {
        component.set('v.columns', [
            { label: 'Name', fieldName: 'Name', type: 'text', sortable: true, title: 'Name', initialWidth: 450},
            { label: 'Document Type', fieldName: 'Document_Type__c', type: 'text', sortable: true, initialWidth: 50},
            { label: 'Created Date', fieldName: 'Document_Created_Date__c', type: 'date', sortable: true, initialWidth: 50},  
            { label: 'Owned By', fieldName: 'Owned_By_User__c', type: 'text'}, 
            { label: 'Linked to', fieldName: 'Linked_Objects__c', sortable: true, type: 'text'}, 
            {label: 'Preview', type: 'button', initialWidth: 75, typeAttributes:{
                label: 'Preview', 
                initialWidth: 50,
                name: 'preview_file', 
                title: 'Click to Preview File'
            }}
        ]);
        helper.loadContentMetaData(component);
        //helper.sortData(component, component.get("v.sortedBy"), component.get("v.sortedDirection"));
    },
    handleRowAction: function (component, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        if(action.name == "display_row"){
            var rowDetails = JSON.stringify(row);	
            alert('rowDetails ' + rowDetails);
        }
    },
    filter: function(component, event, helper) {
        var data = component.get("v.data"),
            term = component.get("v.filter"),
            results = data, regex;
        var row = event.getParam('row');
        try {
            regex = new RegExp(term, "i");
            // filter checks each row, constructs new array where function returns true
            results = data.filter(row=>regex.test(row.Name) || regex.test(row.Document_Type__c) || regex.test(row.Linked_Objects__c));
        } catch(e) {
        }
        component.set("v.filteredData", results);
    },
    openSingleFile: function(component, event, helper) {
        var row = event.getParam('row');
        $A.get('e.lightning:openFiles').fire({
            recordIds: [row.Content_Document_Id__c]
        });
    },
    updateColumnSorting: function (component, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        component.set("v.sortedBy", fieldName);
        component.set("v.sortedDirection", sortDirection);
        helper.sortData(component, fieldName, sortDirection);
    }
})