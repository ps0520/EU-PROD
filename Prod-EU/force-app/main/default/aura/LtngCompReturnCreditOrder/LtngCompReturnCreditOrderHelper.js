({
	getReturnOrderProducts : function(component, event, helper) {
        var action = component.get("c.getReturnProducts");
        	action.setParams({ 'recordId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();
                component.set("v.data", rows);
            }
        });
        $A.enqueueAction(action);
    },
    
    handleEditCell: function (cmp, event) {
        var draftValues = event.getParam('draftValues');
        console.log('**** 2.1 handleEditCell draftValues = '+JSON.stringify(draftValues));
        let objEditedRecs = cmp.get("v.editedRecs") || [];
        objEditedRecs.push(draftValues);
        cmp.set("v.editedRecs", objEditedRecs);
        console.log('**** 2.2 handleEditCell editedRecs = '+JSON.stringify(cmp.get("v.editedRecs")));
        this.FixDataValues(cmp, event);
        this.ValidateDataValues(cmp, event);
        var data = cmp.get("v.data");
        console.log('*** TPS:EH 2.3  handleEditCell data=' + JSON.stringify(data));
    },
    
    FixDataValues: function (cmp, event){
        var dtValues = cmp.get("v.data");
    	var draftValues = event.getParam('draftValues');
        for (var i = 0; i < draftValues.length; i++){
        	Object.keys(dtValues).forEach(function (key){
            	var existsInDV = draftValues.some(function (el) {return el.Id === dtValues[key].Id; });
                if(existsInDV){
                    var rowDraft=draftValues[i]; var rowData=dtValues[key];                    
                    if(rowDraft.Id==rowData.Id){
                    	console.log('**** 2.4 row draft=' + JSON.stringify(rowDraft));
                    	console.log('**** 2.4 row data=' + JSON.stringify(rowData));
                        rowData.ReturnQty=rowDraft.ReturnQty;                        
                    }
                }
            });
        }
	},
    
    ValidateDataValues: function (cmp, event){
        var dtValues = cmp.get("v.data");
    	var draftValues = event.getParam('draftValues');
        cmp.set("v.isError", false); cmp.set("v.errorMessage",null);
        var isError=false;	var errMsg=[];
        
        for (var i = 0; i < draftValues.length; i++){
        	Object.keys(dtValues).forEach(function (key){
            	var existsInDV = draftValues.some(function (el) {return el.Id === dtValues[key].Id; });
                if(existsInDV){
                    var rowDraft=draftValues[i]; var rowData=dtValues[key];                    
                    if(rowDraft.Id==rowData.Id){
                        rowData.errorQTY='No'; rowData.errorRR='No'; 
                    	console.log('**** 3.1 ValidateDataValues row draft=' + JSON.stringify(rowDraft));
                    	console.log('**** 3.2 ValidateDataValues row data=' + JSON.stringify(rowData));
                        if(parseFloat(rowDraft.ReturnQty) > parseFloat(rowData.AvailableQty)){
                			//console.log('**** 3.4 ValidateDataValues Error: Return > Available');
                    		isError=true; rowData.errorQTY='Yes'; errMsg.push('Error: ReturnQty > AvailableQty');
                		}
                        /* Check for return reason when save button is clicked */
                        if(cmp.get("v.RRCheck") && cmp.get("v.isSave")){
                        	if(parseFloat(rowDraft.ReturnQty) > 0 && rowData.ReturnReason=="" ){
                            	//console.log('**** 3.5 ValidateDataValues Error: RR is blank');
                            	isError=true; rowData.errorRR='Yes'; errMsg.push('Error: Return Reason is blank');                			
                			}    
                        }
                        
                        if(parseFloat(rowDraft.ReturnQty) == 0){
                			//console.log('**** 3.6 ValidateDataValues Set ReturnQty=0');
                    		rowData.ReturnReason='';
                		}    
                                                  
                    }
                }
            });
        }
        // cmp.set("v.errorMessage",errMsg);
        if(isError){
            var message='';
            for(var i=0; i < errMsg.length; i++) {
            	if(errMsg[i]) {
                	message += (message.length > 0 ? '\n' : '') + errMsg[i] + ' \n';
                    console.log('++++ ' + errMsg[i]);
                } 	   
            }
            this.showToast('Error: Please review data:', 'error', 'dismissible', message);
            cmp.set("v.isError", isError);
        }
	},
    
    handleSaveEdit: function (cmp, event, helper) {
        helper.ValidateDataValues(cmp, event);
        cmp.set("v.notifMessage", null);
    	var draftValues = event.getParam('draftValues'); console.log('**** 3.1 handleSaveEdit draftValues = '+JSON.stringify(draftValues));
        var dtValues=cmp.find("dtRCO").get("v.data");    console.log('**** 3.2 handleSaveEdit dt values = '+ JSON.stringify(dtValues));
    	var isError=cmp.get("v.isError");
        
       if(isError){
        return;
       }
        
   if (cmp.get('v.isSave') && !isError && !cmp.get("v.isError")) {
       var dtValues = cmp.get("v.data");
       console.log('**** 4.1 handleSaveEdit srcCCData = '+JSON.stringify(dtValues));
       
       var action = cmp.get("c.SaveReturnQty");
       action.setParams({
       		"srcCCData": JSON.stringify(dtValues),                   
            "orderId": cmp.get("v.recordId")
       });
       
       action.setCallback (this, function(response){
       		var state = response.getState();
            var isError=false; cmp.set("v.editedRecs", []); cmp.set("v.notifMessage", null);
           	if(state == "SUCCESS")
            {
            	var rows = response.getReturnValue();
                rows.forEach(element => {
                    if(element.error=='RR'){
                    	cmp.set("v.isErrorRR", true);
                    	isError=true;
                    	cmp.set("v.isError", true); cmp.set("v.errorMessage", "Error: Please review data. Return Reason.");
                	} else if(element.error=='Yes'){
                		cmp.set("v.isError", true);  cmp.set("v.errorMessage", "Error: Please review data. Quantity");
                    	isError=true;
                	}
        		});
                cmp.set("v.data", rows);                
                console.log('---- 4.5 handleSaveEdit rows=', JSON.stringify(rows));
                if(!isError){
                    cmp.set('v.draftValues', []);
                    cmp.set("v.isError", false); cmp.set("v.notifMessage", "Data saved.");
                    this.showToast('Success', 'success', 'dismissible', 'Data Saved');
                    cmp.set("v.isSave", false); cmp.set("v.RRCheck", false); 
                }
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    
                    var message = helper.getErrorMessage(cmp, state, response);
            		helper.showToast('Error', 'error', 'dismissible', message);
                    
                    if (errors[0] && errors[0].message) {
                        console.log("**** Error message: " + errors[0].message);                        
                        cmp.set("v.isError", true); //cmp.set("v.errorMessage", "Error: "  + errors[0].message);
                    }
                } else {
                    console.log("**** Unknown error");
                }
            }
       });
       $A.enqueueAction(action);
   }
    },
    
    displayError: function (cmp, event, helper) {
        var errors = cmp.get("v.errors");
        if(errors==undefined || errors==null ){
            errors = { rows: {}, table: {} }
        } 
        
        errors.table.title = "Error";
        errors.table.messages = ['Testing Error amount','Testing Error Email'];
        cmp.set("v.errors", errors);
    },
    
    removeError : function (cmp, event, helper) {
     var errors = cmp.get("v.errors");
     if(errors==undefined || errors==null ){
         errors = { rows: {}, table: {} }
     }      
     errors.table.title = " ";
     errors.table.messages = [];
     cmp.set("v.errors", errors);
  },
    
    getReturnReasons : function(component, event, helper) {
        var action = component.get("c.getReturnReasonsList");
        	action.setParams({ 'countryCode' : 'GB'
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var rows = response.getReturnValue();                
                //console.log('---- 1.1 getReturnReasons rows:',JSON.stringify(rows));
                component.set("v.returnReasons", rows);
                //console.log('---- 1.2 getReturnReasons v.returnReasons:',component.get("v.returnReasons"));
            }
        });
        $A.enqueueAction(action);
    },
    
    getRowActions: function(component, row, cb) {
        //console.log('**** getRowActions return reasons=' + component.get("v.returnReasons"));
        var actions = [];
        component.get("v.returnReasons").forEach(element => {
        	actions.push(
            	{label: element, name: element}
            );  
        });
        cb(actions);
    },
        
    showToast: function(title, type,mode,  message) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent){
            toastEvent.setParams({
                title: title,
                type: type,
                mode: mode,
                message: message
            });
            toastEvent.fire();
        }        
        else {
            alert(title + ', ' + message);
        }
    },
        
    getErrorMessage : function(component, state, response) {

        var message = '';

        if (state === "INCOMPLETE") {
            return  "No Response From Server";
        }

        if (state === "ERROR") {
            var errors = response.getError();
            if (errors) {
                for(var i=0; i < errors.length; i++) {
                    for(var j=0; errors[i].pageErrors && j < errors[i].pageErrors.length; j++) {
                        message += (message.length > 0 ? '\n' : '') + errors[i].pageErrors[j];
                    }
                    if(errors[i].fieldErrors) {
                        for(var fieldError in errors[i].fieldErrors) {
                            var thisFieldError = errors[i].fieldErrors[fieldError];
                            for(var j=0; j < thisFieldError.length; j++) {
                                message += (message.length > 0 ? '\n' : '') + thisFieldError[j].message;
                            }
                        }
                    }
                    if(errors[i].message) {
                        message += (message.length > 0 ? '\n' : '') + errors[i].message;
                    }
                }
            }
            else {
                message = "Unknown Error";
            }
        }
        else {
            message = "Unknown Status Error: " + state;
        }

        return message;
    },
})