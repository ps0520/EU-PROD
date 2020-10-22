({
	doInit : function(component, event, helper) {     	  
        helper.getVATData(component, helper);
    },
    submitVAT : function (component, event, helper) {    
    	$A.enqueueAction(component.get('c.handleSubmitVAT'));
  	},
    
    handleSubmitVAT : function(component, event, helper) {
  	var isValid=true; 
    console.log('**** start handleSubmitVAT');
    var vatNum = component.find("fd_VATNum");        
    console.log('*** vatNum=' + vatNum.get("v.value"));
    
    if(vatNum.get("v.value")==''){
        console.log('** empty value');
    	$A.util.addClass(vatNum, 'slds-has-error');
        isValid=false;
    } else {
    	$A.util.removeClass(vatNum, 'slds-has-error');
    }
    console.log('isValid=' + isValid);
    if(!isValid){return;}
      
    var vatNumValue=vatNum.get("v.value").replace(/\s/g,'')
    console.log('**** vatNumValue=' + vatNumValue);
    console.log('**** component.get("v.VatNum")=' + component.get("v.VatNum", "v.value"));
        
    
    console.log('**** AccId=' + component.get("v.recordId"));
    component.set("v.isValid", false);
    component.set("v.isInValid", false);
        
    var action = component.get("c.ValidateVATNum");
    action.setParams({ "vatNum" : vatNumValue, "accId" : component.get("v.recordId") });
    action.setCallback(this, function(response){
    	var state = response.getState();
        console.log('state-->'+ state);
        console.log('response-->'+ JSON.stringify(response.getReturnValue()) + '');
        if (state === "SUCCESS") {            
            if(response.getReturnValue()){
                component.set("v.isValid", true);
                component.set("v.isInValid", false);
            	var resultsToast = $A.get("e.force:showToast");
                resultsToast.setParams({
                    "title": "Success!",
                    "type": "success",
                    "message": "VAT # Saved successfully."
                 });
             resultsToast.fire();
             $A.get('e.force:refreshView').fire();
            $A.enqueueAction(component.get('c.doInit'));    
            } else{
                component.set("v.isInValid", true);
            	console.log('**** VAT # not valid');  
            }
            
          } else if (state === "ERROR") {
          	var errors = response.getError();
            console.log('** Errors=' +  JSON.stringify(response.getError()));
            if (errors != null) {
                var err1= errors[0];
                console.log('** err1=' +  JSON.stringify(err1));
                
            	if (err1 && err1.pageErrors) {
                    var errPageErrors=err1.pageErrors[0];
                    var err1StatusCode=errPageErrors.statusCode;
                    var err1Message=errPageErrors.message;
                    console.log("err1StatusCode: " +  err1StatusCode);
                	console.log("err1Message: " +  err1Message);
                    var errorToast = $A.get("e.force:showToast");
                    errorToast.setParams({
                                "title": "ERROR adding VAT Number",
                                "message": err1StatusCode + " - " + err1Message,
                                "type": "error",
                         		"mode": "pester"
                            });
                   // errorToast.fire();
                   component.set("v.isInValid", true);
                    
                }
                } else {
                	console.log("Unknown error");
                    component.set("v.isInValid", true);
                }
        }
    });
    $A.enqueueAction(action);
      
  }
    
    
})