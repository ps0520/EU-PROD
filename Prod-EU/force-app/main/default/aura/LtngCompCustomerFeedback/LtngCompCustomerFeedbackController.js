({
    doinit : function(component, event, helper) {
        
        component.set("v.isEditMode",false);
        helper.getAccData(component, event);
        helper.getCFPicklist(component,event);
        var updateCustFeedback= component.get("v.custfeedback");
        if(updateCustFeedback != '' ){
            component.set("v.isEditMode",true);
            var custFeedback = JSON.parse(JSON.stringify(updateCustFeedback));
            
            component.find("cf_Type").set("v.value",custFeedback.Type__c);   
            component.find("cf_hlfb").set("v.value",custFeedback.High_Level_Feedback_Box__c);
            component.find("cf_Nb").set("v.value",custFeedback.Note_Box__c);
            component.find("cf_Rb").set("v.value",custFeedback.Resolution_Box__c);
            component.set("v.custfeedbackId",custFeedback.Id);
        }
    },
    
    submitCCFormData : function (component, event, helper) {
        $A.enqueueAction(component.get('c.handleSubmitCCFormData'));
    },
    
    handleSubmitCCFormData : function(component, event, helper) {
        var checkIfCF = component.get("v.custfeedbackId");
        if ($A.util.isUndefinedOrNull(checkIfCF) || checkIfCF =='') {
            component.set("v.isEditMode",false);
        }else{
            component.set("v.isEditMode",true);
        }
        var checkMode=  component.get("v.isEditMode");
        var recCFData = component.get("v.recCF");
        recCFData.Account__c=component.get("v.accountId");
        recCFData.High_Level_Feedback_Box__c=component.find("cf_hlfb").get("v.value");
        recCFData.Note_Box__c=component.find("cf_Nb").get("v.value");
        recCFData.Resolution_Box__c=component.find("cf_Rb").get("v.value"); 
        recCFData.Type__c=component.get("v.type");
        console.log('*****refCFData'+JSON.stringify(recCFData)); 
        var action = '';
        if(checkMode==false){
            //alert('New Record');
            action = component.get("c.saveCustfeedbackDetails"); 
            action.setParams({ "recCF" : recCFData });
        }else{
            // alert('Update Record');
            var CustfeedbackId = component.get("v.custfeedbackId");
            action = component.get("c.updateCustfeedbackDetails"); 
            action.setParams({ "recCF" : recCFData, "custFeedbackId":CustfeedbackId}); 
        }
        
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                var toastMessage='';
                //alert('response --'+checkMode);
                if(checkMode==false){
                    toastMessage = "Customer Feedback Saved successfully.";
                    
                }
                if(checkMode){
                    // alert('Inupdate toast');
                    toastMessage=  "Customer Feedback updated successfully.";
                }
                var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success!",
                    "type": "success",
                    "message": toastMessage
                });
                resultsToast.fire();
                
                var myEvent = component.getEvent("myRefreshTable");
                myEvent.setParams({"param": "Customer Feedback"});
                myEvent.fire();
                
                var myEvent = component.getEvent("CloseModal");
                myEvent.setParams({"param": "CMP_CustomerFeedbac"});
                myEvent.fire();
                
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }  
        });
        $A.enqueueAction(action);
        
    }
    
})