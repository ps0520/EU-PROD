({  
    showToastErr : function(component,event,toastErrorMsg){
  		
            var resultsToast = $A.get("e.force:showToast");
            resultsToast.setParams({
            "title": "Error!",
            "type": "error",
            "message": toastErrorMsg
        });
        resultsToast.fire();
 	},
    disableDates : function (component, event, helper) {
        //alert('helper');
        var status =  component.get("v.docst");
        //alert('status--'+status);
        if(status == 'Sent'){
            component.set("v.isSent",true);
            component.set("v.isSent2",false);
            //alert('--'+component.get("v.isSent2"));
        }else if(status == 'Received'){
            component.set("v.isSent",true);
            component.set("v.isSent2",true);  
        }else if(status == 'Not Required'){
            component.set("v.isSent",false);
            component.set("v.isSent2",true);
            //component.find("dc_rdt").set("v.value",null);
        }else if(status == 'Not Sent'){
            component.set("v.isSent",false);
            component.set("v.isSent2",false);
            //component.find("dc_rdt").set("v.value",null);
            //component.find("dc_Sndt").set("v.value",null);
        }
    },
	getCFPicklist : function(component, event, helper) {
        var action = component.get("c.getDocTypePicklist");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var typeMap = [];
                for(var key in result ){
                    typeMap.push({key:key,value:result[key]});  
                }
                component.set("v.docTypes", typeMap);
            }
        });
        $A.enqueueAction(action);
	},
    getStatusPicklist : function(component, event, helper) {
        var action = component.get("c.getDocStatusPicklist");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var typeMap = [];
                for(var key in result ){
                    typeMap.push({key:key,value:result[key]});  
                }
                component.set("v.docStatus", typeMap);
            }
        });
        $A.enqueueAction(action);
	},
    getCLFRMPicklist : function(component, event, helper) {
        var action = component.get("c.getCLFPicklist");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var typeMap = [];
                for(var key in result ){
                    typeMap.push({key:key,value:result[key]});  
                }
                component.set("v.docCF", typeMap);
            }
        });
        $A.enqueueAction(action);
	}
})