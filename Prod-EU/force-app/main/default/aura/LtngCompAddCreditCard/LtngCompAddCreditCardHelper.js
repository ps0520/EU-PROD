({
	//get Industry Picklist Value
    getAccAddrAsPL: function(component, event) {
        var action = component.get("c.getAccBTAddr");
        action.setParams({
            accId : component.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var industryMap = [];
                for(var key in result){
                    
                	industryMap.push({key: key, value: result[key]});
                    console.log('**** result[key]='+result[key]);
                    
                    
                    if(result[key].endsWith('(Primary)')){
                    	component.set("v.selAddr", key);
                        console.log('** selected');
                    }
                }
                component.set("v.mapAddr", industryMap);
            }
        });
        $A.enqueueAction(action);
    },
    
     getAccData : function(component, event, helper) {
        var action = component.get("c.getAccName");
        	action.setParams({ 'accId' : component.get("v.recordId")
        });
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var acc = response.getReturnValue();
                console.log('*** acc=' + JSON.stringify(acc));
				component.set("v.accName", acc.Name); component.set("v.accountId", acc.Id);component.set("v.currISOCode", acc.CurrencyIsoCode);
                console.log('*** v.accName=' + component.get("v.accName"));
                console.log('*** v.accountId=' + component.get("v.accountId"));
                console.log('*** v.currISOCode=' + component.get("v.currISOCode"));
                
                
            }
        });
        $A.enqueueAction(action);
    },
    
    showToast: function(title, type,mode,  message) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent){
            toastEvent.setParams({
                title: title, type: type, mode: mode, message: message
            });
            toastEvent.fire();
        }        
        else {
            alert(title + ', ' + message);
        }
    },
   
})