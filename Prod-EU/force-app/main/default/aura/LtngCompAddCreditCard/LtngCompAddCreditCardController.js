({
	 //Load Account Industry Picklist
    doInit: function(component, event, helper) {
        helper.getAccData(component, event);
        helper.getAccAddrAsPL(component, event);
        $A.util.addClass(component.find("fd_CCImg"), "slds-hide");
    },
    
     //handle Industry Picklist Selection
    handleAddrOnChange : function(component, event, helper) {
        var selectedAddress = component.get("v.selAddr");
        //alert(selectedAddress);
    },
    
  	checkValidityOfExpDate : function(component, event, helper) {
      console.log('checkValidityOfExpDate called');
    },
    
    checkCardType : function(component, event, helper) {
    	var ccNum = component.find("fd_CardNum").get("v.value");    	
      	console.log('**** ccNum value=' + ccNum + ' ****');
        
        // Strip spaces and dashes
  		ccNum = ccNum.replace(/[ -]/g, '');
  // See if the card is valid
  // The regex will capture the number in one of the capturing groups
  var match = /^(?:(4[0-9]{12}(?:[0-9]{3})?)|(5[1-5][0-9]{14})|(6(?:011|5[0-9]{2})[0-9]{12})|(3[47][0-9]{13})|(3(?:0[0-5]|[68][0-9])[0-9]{11})|((?:2131|1800|35[0-9]{3})[0-9]{11}))$/.exec(ccNum);
  if (match) {
  	// List of card types, in the same order as the regex capturing groups
    var types = ['Visa', 'MasterCard', 'Discover', 'American Express',
                 'Diners Club', 'JCB'];
    // Find the capturing group that matched
    // Skip the zeroth element of the match array (the overall match)
    for (var i = 1; i < match.length; i++) {
      if (match[i]) {
        // Display the card type for that group
        //document.getElementById('notice').innerHTML = types[i - 1];
          $A.util.removeClass(component.find("fd_CCImg"), "slds-hide");
          component.set('v.srcvalue','/CCImages/' + 'blank.png');
          if(types[i - 1]=='American Express'){               
              component.set('v.srcvalue','/CCImages/' + 'AA.png');   component.set('v.cardType','American Express');
          } else if (types[i - 1]=='Visa'){
              component.set('v.srcvalue','/CCImages/' + 'VI.png');   component.set('v.cardType','Visa');
          } else if (types[i - 1]=='MasterCard'){
              component.set('v.srcvalue','/CCImages/' + 'MC.png');   component.set('v.cardType','Mastercard');
          } else {
              component.set('v.srcvalue','/CCImages/' + 'blank.png'); component.set('v.cardType','N/A'); 
          }
        console.log('**** ccNum type=' + types[i - 1]);
        break;
      }
    }
  } else {
    console.log('**** ccNum type= not found');
  }  
  },
    
  submitCCFormData : function (component, event, helper) {    
    $A.enqueueAction(component.get('c.handleSubmitCCFormData'));
  },
 
  handleSubmitCCFormData : function(component, event, helper) {
  	var isValid=true;
    console.log('**** start handleSubmitCCFormData');
    
    var cardNum = component.find("fd_CardNum");        
    //console.log('*** cardNum=' + cardNum.get("v.value"));
    if(component.find("fd_CardNum").get("v.value")==null){
    	$A.util.addClass(cardNum, 'slds-has-error');
        isValid=false;
    } else {
    	$A.util.removeClass(cardNum, 'slds-has-error');
    }
    
    var expNum = component.find("fd_ExpDate").get("v.value");
    var CmpCardNum = component.find("fd_ExpDate"); 
    console.log('*** expNum=' + expNum);
    $A.util.removeClass(CmpCardNum, 'slds-has-error');  
    var matchExp = /^(0[1-9]|1[0-2])\/([0-9]{4}|[0-9]{2})$/.exec(expNum);
    console.log('*** matchExp=' + matchExp);  
    if (!matchExp) {
        $A.util.addClass(CmpCardNum, 'slds-has-error');
    	isValid=false;
    }
      
    /*if(expNum.includes('/')){
    	var yy=expNum.split('/')[1];
        console.log('*** yy=' + yy);
        if(yy.length()==2){
            var cy=new Date().getFullYear().toString().substr(-2);
            if(int.valueOf(yy)<int.valueOf(cy)){
            	$A.util.addClass(component.find("fd_ExpDate"), 'slds-has-error');
    			isValid=false;
            }
        }
        console.log('*** Current yy=' + new Date().getFullYear().toString().substr(-2));
    }*/
      
    if(!isValid){return;}
    var ccNum=cardNum.get("v.value").replace(/\s/g,'')
    console.log('**** ccNum=' + ccNum + ' card type=' + component.get("v.cardType"));
    
    var recFDData = component.get("v.recFD");
    recFDData.Name_on_Account__c=component.find("fd_CustName").get("v.value");
    recFDData.Expiry_Date__c=component.find("fd_ExpDate").get("v.value");
	recFDData.CC_Address__c=component.get("v.selAddr");
    recFDData.Account__c=component.get("v.accountId"); // component.get("v.recordId");
    recFDData.CC_CUR__c=component.get("v.currISOCode");
    recFDData.Primary__c=component.find("fd_Primary").get("v.value"); 
    recFDData.Card_Type__c=component.get("v.cardType");
    console.log('**** recFDData=' + JSON.stringify(recFDData));    
    
    var action = component.get("c.getCCNumberToken");
    action.setParams({ "recFD" : recFDData, "ccNum" : ccNum });    
    action.setCallback(this, function(response){
    	var state = response.getState();
                    if (state === "SUCCESS") {
                        console.log('response-->'+ JSON.stringify(response.getReturnValue()) + '');
                        var message; message=response.getReturnValue();
                        
                        if(response.getReturnValue()=='ERROR:BAD_REQUEST'){
                        	var errorToast = $A.get("e.force:showToast");
                            errorToast.setParams({
                                "title": "ERROR adding credit card",
                                "message": "Could not save, please check credit card number entry.",
                                "type": "error"
                            });
                            errorToast.fire();
                        } else{
                             if(message){
                                if(message.startsWith('ERROR:')){
                                    helper.showToast('Error: Please review data:', 'error', 'dismissible', message);
                                    return;
                                }
                			}
                        	var resultsToast = $A.get("e.force:showToast");
                            resultsToast.setParams({
                                "title": "Success!",
                                "type": "success",
                                "message": "CC Saved successfully."
                            });
                            resultsToast.fire();
                            
                            var myEvent = component.getEvent("myRefreshTable");
        					myEvent.setParams({"param": "Financial Records"});
        					myEvent.fire();
                            
                            var myEvent = component.getEvent("CloseModal");
                        	myEvent.setParams({"param": "NCO_AddCreditCard"});
                        	myEvent.fire();
                            
                        }
                    }
                	else if (state === "ERROR") {
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