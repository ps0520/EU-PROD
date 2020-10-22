({
	doInit : function(component, event, helper) { 
    	component.set('v.columns', [
            {label: 'Primary',  type: 'boolean', cellAttributes: {iconName: { fieldName: 'primaryIconName' }, iconPosition: 'right', iconSize: 'x-small'}},          
            {label: 'Type', fieldName: 'Card_Type__c', type: 'text', sortable: true},
            {label: 'Last 4', fieldName: 'linkName', type: 'url', typeAttributes: {label: { fieldName: 'Last_4_Digits__c'}, target: '_self'}},
            {label: 'Expiry Date', fieldName: 'Expiry_Date__c', type: 'text'}
        ]);    
        helper.getCCData(component, helper);
    },
   
   SubmitFormData : function(component, event, helper) {       
       var ccForm = component.find('NCO_AddCreditCard');
       ccForm.submitCCFormData();
	},
   openModel: function(component, event, helper) {
      // for Display Model,set the "isOpen" attribute to "true"
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
})