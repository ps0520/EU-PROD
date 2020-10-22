({
	 doInit : function(component, event, helper) {
         // Loads Related Audit Records 
         helper.inithelper(component);
         
     },
	 saveauditbtn : function(cmp,event,helper) {
       // Save the Updated Audit Records  
       helper.saveaudithelper(cmp);
     },
     submitauditbtn : function(cmp,event,helper) {
       // Submits the Audit Records  
       helper.submitaudithelper(cmp);
     },
    selectchange : function(component, event, helper) {
         console.log(component.get("v.auditlist"));
         var s=event.getSource();
         var v=s.get("v.value");
         console.log(v);
     },
    closeModel : function(component, event, helper) {
        component.set("v.isOpen", false);
     },
    
    updateTaskDetails : function(component, event, helper) {
        
        var taskd = component.get("v.taskObject");
        var tskId = taskd.Id;
        var tskSubject = component.get("v.type");
        var tskCmt = component.get("v.comments");
        
        //alert('tskCmt--'+tskCmt);
        if(tskSubject == '--None--' || tskSubject == ''){
           helper.showerror(component,'Please select Subject Type');; 
        }else{
           var duedate = component.get("v.today");
        var userId = component.get("v.users.id");
        
        var action = component.get("c.updateTask");
            action.setParams({ 
                tskRecId : tskId,
                tskSubjectInfo : component.get("v.type"),
                tskDueDate : component.get("v.today"),
                tskAssignTo : component.get("v.users.id"),
                recordId : component.get("v.recordId"),
                tskCmt : component.get("v.comments")
            });
            action.setCallback(this, function(response) {
                var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();   
               // alert(result);
                if(result == 'Success'){
                    component.set("v.isOpen", false);
                   // $A.get('e.force:refreshView').fire();
                    helper.showsuccess(component,'Record Created Successfully');
                }
            }
        });
        $A.enqueueAction(action); 
        }
        
        
     },

})