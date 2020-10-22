({
	
    refershView : function(component, event, helper) {
        var saveLeadAction = component.get("c.Refreshview");
        saveLeadAction.setCallback(this, function(a) {
            //alert(a.getState());
            if (a.getState() === "SUCCESS") {
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();

            }else if (res.getState() === "ERROR") {
                //console.log("Errore Saving  ");
            } 
        }); 
        $A.enqueueAction(saveLeadAction);
    },
    
    //opportunityStageCheck(String oppRecId)
    checkOppStage : function(component, event, helper) {
        //fetchRequiredDoc(String oppRecId){
        var recordId = component.get("v.recordId");       
		var action = component.get("c.opportunityStageCheck");
        action.setParams({ oppRecId : recordId });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var IsStageCnf =  response.getReturnValue();
                component.set('v.isStagePass',IsStageCnf);
			}
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                
            }
        });
        $A.enqueueAction(action);
	},
	getPatientData : function(component, event, helper) {
        //fetchRequiredDoc(String oppRecId){
        var recordId = component.get("v.recordId");
       
		var action = component.get("c.fetchRequiredDoc");
        action.setParams({ oppRecId : recordId });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
               // alert(state+'--'+response.getReturnValue());
                var Pdoc =  response.getReturnValue();
                component.set('v.lstOfRequiredDoc',Pdoc);
			}
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                
            }
        });
        $A.enqueueAction(action);
	},
    getAccountId : function(component, event, helper) {
        //fetchRequiredDoc(String oppRecId){
        var recordId = component.get("v.recordId");
       
		var action = component.get("c.fetchAccId");
        action.setParams({ oppRecId : recordId });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                //alert(response+'--'+response.getReturnValue());
                var accId =  response.getReturnValue();
                component.set("v.accountRecId",accId);
			}
            else if (state === "INCOMPLETE") {
                // do something
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                
            }
        });
        $A.enqueueAction(action);
	}
})