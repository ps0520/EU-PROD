({
    doInit : function(component, event, helper){
      helper.doInit(component, event);  
    },
	handleSave : function(component, event, helper){
      helper.sendEmail(component, event);  
    }
})