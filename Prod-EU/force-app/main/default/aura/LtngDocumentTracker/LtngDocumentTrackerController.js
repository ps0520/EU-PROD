({
	doInit : function(component, event, helper) {
		var recordId = component.get("v.recordId");
        helper.getPatientData(component, event);
    	helper.checkOppStage(component,event);
	},
    SubmitFormData: function(component, event, helper) {
       var ccForm = component.find('CMP_PatientDoc');
       ccForm.submitCCFormData(); 
    },
    addDocuments: function(component, event, helper) {
        
       var doclst =  component.get("v.lstOfRequiredDoc");
        if(doclst != null && doclst.length>0){
            var accId = doclst[0].Patient_Document__r.Account__c;
        }else{
           helper.getAccountId(component, event);
        }        
       
       component.set("v.isOpen", true);
       component.set("v.PdocId",null);
       component.set("v.accountRecId",accId);
       component.set("v.oppRecId",component.get("v.recordId")); 
       
    },
    handleEdit : function(component, event, helper) {
        var recId = event.getSource().get("v.value");
        component.set("v.PdocId",recId);
        component.set("v.oppRecId",component.get("v.recordId"));
        component.set("v.isOpen", true);
    },
    handleDelete : function(component, event, helper) {
        var recordId = component.get("v.recordId");
		var recId = event.getSource().get("v.value");
        
        var action = component.get("c.deletePdocToOpppRec"); 
        action.setParams({ "PdocId" : recId,
                          "OpprecId" : recordId });
        action.setCallback(this, function(response){
                var state = response.getState();
                if (state === "SUCCESS") {
                    component.set('v.lstOfRequiredDoc',response.getReturnValue());
                    var toastMessage = 'Recrod deleted Successfully';
                    
                    var resultsToast = $A.get("e.force:showToast");
                    resultsToast.setParams({
                        "title": "Success!",
                        "type": "success",
                        "message": toastMessage
                    });
                    resultsToast.fire();
                    
                    var myEvent = component.getEvent("myRefreshTable");
                    myEvent.setParams({"param": "Patient Document"});
                    myEvent.fire();
                    //location.reload();
                    
                }else if (state === "ERROR") {
                    var errors = response.getError();
                    
                }  
            });
            $A.enqueueAction(action);
    },
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    handleCloseModal : function(component, event, helper) {
        component.set("v.isOpen", false);
    },
})