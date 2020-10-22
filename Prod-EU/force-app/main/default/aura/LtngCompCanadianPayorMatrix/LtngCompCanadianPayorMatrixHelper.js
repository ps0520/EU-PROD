({
	getData : function(component) {
		var payorId = component.get("v.accountId");
        var action = component.get("c.getReqDocs");
        action.setParams({ "recid" : payorId
                         });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state == "SUCCESS") {
                var result=response.getReturnValue();
                if (result != null) {
                    console.log(result);
                    component.set("v.coverage", result.CA_Coverage_Details__c);
                    component.set("v.respTo", result.CA_Determination_Response_Sent_To__c);
                    component.set("v.respBy", result.CA_Response_Communication_Method__c);
                    component.set("v.payor", result.Name);
                    //if (result.Parent.Name != null) component.set("v.respBy", result.Parent.Name);
                    if (result.CA_Docs_Required__c != null) this.setReqDocs(component,result.CA_Docs_Required__c);
                     component.set("v.finishedQuery", true);
 					return;
                }
            }
        });
        $A.enqueueAction(action);
	},
    
    setReqDocs: function(component, str) {
    	var parts = str.split(";");
        if (parts.length === 0 ) return;
        /*
         * <aura:attribute name="PIF" type="Boolean"  />
	<aura:attribute name="CMN" type="Boolean"  />
	<aura:attribute name="T1D" type="Boolean"  />
	<aura:attribute name="Claim" type="Boolean"  />
	<aura:attribute name="Prior" type="Boolean"  />
	<aura:attribute name="A1C" type="Boolean"  />
	<aura:attribute name="BG" type="Boolean"  />
	<aura:attribute name="CGM" type="Boolean"  />
    */
        parts.forEach(function(item) {
            if (item === "PIAF") component.set("v.PIAF", true);
            if (item === "CMN") component.set("v.CMN", true);
            if (item === "T1D Note") component.set("v.T1D", true);
            if (item === "Claim Form") component.set("v.Claim", true);
            if (item === "Prior-Auth Form") component.set("v.Prior", true);
            if (item === "A1C") component.set("v.A1C", true);
            if (item === "BG Logs") component.set("v.BG", true);
            if (item === "CGM Quest") component.set("v.CGM", true);
            if (item === "LIC") component.set("v.CGM", true);
            if (item === "Pregnancy RX") component.set("v.PRX", true);
            if (item === "Narrative Letter") component.set("v.NL", true);
            if (item === "ODSP Info FORM") component.set("v.OIF", true);
            if (item === "NIHB Claim FORM") component.set("v.NCF", true);
            if (item === "NIHB Estimate") component.set("v.NEST", true);
        })
        //component.set("v.finishedQuery", true);
	}
	
})