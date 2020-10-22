({
    doInit : function(component, event, helper) {

        var actions =[{label: 'Edit', name: 'Edit'}] ;
        component.set('v.columns', [
            {label: 'Type', fieldName: 'Type__c',  sortable: true,type: 'text'},
            {label: 'High Level Feedback', fieldName: 'High_Level_Feedback_Box__c', type: 'text'},
            {label: 'Resolution', fieldName: 'Resolution_Box__c', type: 'text'},
            {label: '', type:  'button', typeAttributes:{iconName: 'action:edit', iconPosition:'center',name: 'Edit',title: 'Edit Record', disabled: false,value: 'test'}}
			//{label: 'Type', fieldName: 'Type__c',  sortable: true,type: 'url', typeAttributes: {label: { fieldName: 'Type__c'}}},
            //{label: 'Edit', type: 'action', typeAttributes:{rowActions: actions}}
        ]); 
        helper.getCustFeedback(component, event);
    },
    handleRowAction: function(component, event, helper) {
        // for handle row action (Edit) functionality
        var row = event.getParam('row');
        component.set("v.custfeedback",row);
        component.set("v.isOpen", true);
         
    },
    
    openModel: function(component, event, helper) {
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.custfeedback",'');
        component.set("v.isOpen", true);
    },
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    
    handleCloseModal : function(component, event, helper) {
        var value = event.getParam("param");
        component.set("v.isOpen", false);
    },
    SubmitFormData : function(component, event, helper) {       
       var ccForm = component.find('CMP_CustomerFeedback');
       ccForm.submitCCFormData();
	},
    
})