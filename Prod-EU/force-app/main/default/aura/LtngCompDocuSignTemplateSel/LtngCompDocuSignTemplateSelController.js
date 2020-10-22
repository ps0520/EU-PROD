({
	doInit: function(component, event, helper) {
        var recId = component.get("v.recordId");
        var objType='';
        if(recId.startsWith("001")){
           objType='Account'; 
        } else if (recId.startsWith("006")){
            objType='Opportunity'; 
        }
        
        
        console.log('**** Starting ****  RecordId=' + recId + '  ** objType=' + objType);
        var action = component.get("c.getRecordDataType");
        action.setParams({ "recordId" : recId });
        action.setCallback(this, function(response){
        	var state = response.getState();
            if (state === "SUCCESS") {
                console.log('response-->'+ JSON.stringify(response.getReturnValue()));
                //console.log('*** RecepientName=' + response.getReturnValue().RecepientName);
                //console.log('*** RecepientEmail=' + response.getReturnValue().RecepientEmail);
                
                component.set("v.sObjectRecordName", response.getReturnValue().sObjectRecordName);
                component.find("tf_recepientName").set("v.value", response.getReturnValue().RecepientName);
                component.find("tf_recepientEmail").set("v.value", response.getReturnValue().RecepientEmail);
                //var lstDSConfig = response.getReturnValue().lstDSConfig;
                
                //component.set("v.entityId", recId);
                //component.set("v.recepientId", recId);
                if(objType=='Opportunity'){
                	//component.set("v.recordId", response.getReturnValue().AccountId);
                    //component.set("v.recepientId", response.getReturnValue().AccountId);
                    console.log('*** recId=' + component.get("v.recordId"));
                }
                
                var opts = [];
                var data=response.getReturnValue().lstDSConfig;
                component.set("v.data", data);
                opts.push({label: "-- None --", value: ""});
                data.forEach(function(item, index, array) {
  					console.log('--> ' + item.Template_Id__c, item.Template_Name__c);
                    opts.push({label: item.Template_Name__c, value: item.Template_Id__c});
				});
                component.set('v.optTemplates', opts);
            	//console.log('response-->'+ JSON.stringify(response.getReturnValue().lstDSConfig) + '');
                
            }
        });
        $A.enqueueAction(action);
              
   },
    
   onselTmpChange: function (cmp, evt, helper) {
       //console.log(cmp.find('tf_selTemplate').get('v.value') + ' selected');
       var selItem=cmp.find('tf_selTemplate').get('v.value');
       cmp.find("tf_EmailSubject").set("v.value", "");
       cmp.find("tf_EmailMsg").set("v.value", "");
       cmp.find("tf_SendDSButton").set('v.disabled',true);
       if(selItem != ''){
       		console.log(selItem + ' selected');
        	var data= cmp.get("v.data");
       
           var found = data.find(function(element) {
            return element.Template_Id__c==selItem;
           });
           cmp.find("tf_EmailSubject").set("v.value", found.Email_Subject__c);
           console.log('**** Name=' + cmp.find('tf_recepientName').get('v.value'));
           if(cmp.find('tf_recepientName')){
           	cmp.find("tf_EmailSubject").set("v.value", found.Email_Subject__c + ' - ' + cmp.find('tf_recepientName').get('v.value'));    
           }           
           cmp.find("tf_EmailMsg").set("v.value", found.Email_Message__c);
           cmp.find("tf_SendDSButton").set('v.disabled',false);
       }     
   },
   /* Purpose: When a user click on button [Send With DocuSign], this function gets email subject, message, recepient and selected template id to use.
      It then calls apex class controlelr method to create DocuSign envelope and send it to recepient.
      If DocuSign sends a status of 'sent', this function closes tool and provides success notification.
   */ 
   handleClickSendDS : function (cmp, event, helper) {
   	var recId = cmp.get("v.recordId");       
    var entityId= cmp.get("v.entityId");
    var recepientId= cmp.get("v.recepientId");
    var selItem=cmp.find('tf_selTemplate').get('v.value');
   
    var recipientName = cmp.find("tf_recepientName").get("v.value");
    var recepientEmail = cmp.find("tf_recepientEmail").get("v.value");
    var emailSubject = cmp.find("tf_EmailSubject").get("v.value");
    var emailMessage = cmp.find("tf_EmailMsg").get("v.value");
       
    cmp.find("tf_SendDSButton").set('v.disabled',true);
    console.log('*** recId=' + recId + ' entityId=' + entityId + ' recepientId=' + recepientId);   
    var action = cmp.get("c.SendDocument1");
    action.setParams({ "entityId" : recId,
                      "templateId" : selItem,
                      "recipientName" : recipientName,
                      "recepientEmail" : recepientEmail,
                      "emailSubject" : emailSubject,
                      "emailMessage" : emailMessage,
                      "recepientId" : recId });
    action.setCallback(this, function(response){
    	var state = response.getState();
        if (state === "SUCCESS") {
        	//console.log('response-->'+ JSON.stringify(response.getReturnValue()) + ''); 
            //console.log('status-->'+ response.getReturnValue()[0].status);
            var actionStatus = cmp.get("c.GetDocumentStatus");
    		actionStatus.setParams({ "entityId" : recId });
            actionStatus.setCallback(this, function(responseStatus){
            	var stateStatus = responseStatus.getState();   
                if (stateStatus === "SUCCESS") {
                    if(responseStatus.getReturnValue()[0].status=='sent'){
                        cmp.find("tf_SendDSButton").set('v.label','Document Sent!');
                        cmp.find("tf_SendDSButton").set('v.disabled',true);
                
                        var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                           "title": "Success!",
                            "message": "The document was sent to " + recipientName + " successfully.",
                            "type":"success"
                        });
                        toastEvent.fire();
                        $A.get("e.force:closeQuickAction").fire();
            		}
                }
            });
   			$A.enqueueAction(actionStatus);
            
            
        }
   });
   $A.enqueueAction(action);
        
   }    
})