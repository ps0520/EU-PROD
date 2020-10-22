({
	inithelper : function(cmp) {
        //var today = new Date();
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        cmp.set('v.today', today);
        //cmp.set('v.today', today.getFullYear() + "-" + (today.getMonth() + 1) + "-" + (today.getDate()+1));
        if(!$A.util.isUndefined(cmp)){
            var that = this;
        	that.queryaccess(cmp);            
        }
        
        
         
    },
    saveaudithelper : function(cmp) {
		// Call Apex method to Save the updated Audit Records
        var that = this;
        var action = cmp.get("c.saveaudit");
        action.setParams({ 
            auditrecs : cmp.get("v.auditlist")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS"){
                 	var result=response.getReturnValue();
                    if(result.indexOf('Error') > -1){
            		    that.showerror(cmp,result.split('-')[1]);
                    } else {
                        that.showsuccess(cmp,'Record Saved Successfully');
                        that.refreshcomp(cmp);
                        
                    }
            }
            else if (state === "INCOMPLETE") {
                Console.log('Server Call status Incomplete ');
            }
            else if (state === "ERROR") {
                 that.showerror(cmp,response.getError()[0].message);
            }
        });
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
	},
	submitaudithelper : function(cmp) {
		// call the Apex Method to Submit the Audit Records
        var that = this;

        var action = cmp.get("c.submitaudit");
        action.setParams({ 
            recordId : cmp.get("v.recordId"),
            lstaudit : cmp.get("v.auditlist")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
					var result=response.getReturnValue();
                    if(result.indexOf('Error') > -1){
            		    that.showerror(cmp,result.split('-')[1]);
                    }else if(result.startsWith('Task')){
                        that.showTaskModal(cmp,result.split('-')[1]);
                    } else {
                        that.showsuccess(cmp,'Record Submitted Successfully');
                        that.refreshcomp(cmp);
                    }
            }
            else if (state === "INCOMPLETE") {
                     Console.log('Server Call status Incomplete ');
            }
            else if (state === "ERROR") {
               that.showerror(cmp,response.getError()[0].message);
            }
        });
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
	},
    showTaskModal : function(cmp,taskinfo){
        
        //getTaskSubject
        var action = cmp.get("c.getTaskSubject");
        action.setCallback(this,function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();                
                var typeMap = [];
                for(var key in result ){
                    typeMap.push({key:key,value:result[key]});  
                }
                cmp.set("v.tasksubject", typeMap);
                var data1 = JSON.parse(taskinfo);
                //var JSONStr = JSON.stringify(taskinfo);
                //alert('Josn--'+JSONStr);
                cmp.set("v.taskObject",data1);        
                var taskd = cmp.get("v.taskObject");
                
                var action = cmp.get("c.searchUser");
                action.setParams({
                    "userId": taskd.OwnerId
                });
                action.setCallback(this, function(response) {
                    var state = response.getState();
                    if (state === "SUCCESS") {
                        var result = response.getReturnValue();
                        cmp.set("v.userRecId",result);   
                        cmp.set("v.users.id",result);
                    }else{
                        alert('Error Occured--');
                    }
                });
                $A.enqueueAction(action);
            }
        });
        $A.enqueueAction(action);
        
        var data = JSON.parse(taskinfo);
        cmp.set("v.taskObject",data);        
        var taskd = cmp.get("v.taskObject");
        cmp.set("v.tasksubject",taskd.Subject);
        cmp.set("v.taskType",taskd.Type);
		cmp.set("v.users.id",taskd.OwnerId);
		cmp.set("v.userRecId",taskd.OwnerId);        
        cmp.set("v.isOpen", true);
        
    },
   showsuccess : function(cmp,msg){
        // This Method Shows the Success Message
  		    			var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Action Info',
                            message: msg,
                            duration:'5000',
                            type: 'success',
                            mode: 'dismissible'
                        });
                        toastEvent.fire();
       $A.get('e.force:refreshView').fire();
    },
    showerror : function(cmp,msg){
        // This Method Shows the Error Message
  		    			var toastEvent = $A.get("e.force:showToast");
                        toastEvent.setParams({
                            title : 'Error Message',
                            message: msg,
                            duration:'5000',
                            type: 'error',
                            mode: 'dismissible'
                        });
                        toastEvent.fire();
    },
    refreshcomp : function(cmp){
        // This Method refreshes the current component
        $A.get('e.force:refreshView').fire();
    },
    queryaccess : function(cmp){
        // Call the Apex method to get Read/Edit Access and 
        // also Visibility for related Audit Records
        var that = this;
  		var action = cmp.get("c.getaccessibility");
        action.setParams({ 
            recid : cmp.get("v.recordId")
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                cmp.set("v.wrapperList",response.getReturnValue());
                var shipstatus=cmp.get("v.wrapperList.Shipholdstatus");
                var statusdiv = cmp.find('statusbannerid');
                if( shipstatus=="Not Started"){
                    $A.util.addClass(statusdiv,'color1');
                } else if( shipstatus=="In Progress"){
                    $A.util.addClass(statusdiv,'color2');
                } else if( shipstatus=="Completed"){
                    $A.util.addClass(statusdiv,'color3');
                }
                if(cmp.get("v.wrapperList").hasAccess){
                    that.getauditrecords(cmp);    
                }
                if(cmp.get("v.wrapperList").iscomplete){
                   cmp.set("v.isComplete",cmp.get("v.wrapperList").iscomplete);
                }
                if(!cmp.get("v.wrapperList").isEditable){
                    var completediv = cmp.find('maindiv');
                    $A.util.addClass(completediv,'readonlydiv');
                } 
            }
            else if (state === "ERROR") {
               that.showerror(cmp,response.getError()[0].message);
            }
        });
  		// $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);      
    },
    getauditrecords : function(cmp){
        // call the Apex Method to Get related Audit Records
        var action = cmp.get("c.inithelpermethod");
        action.setParams({ 
            recid : cmp.get("v.recordId")
        });
		action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                for (var key in result){
                    if(key.indexOf('Error') > -1){
            		    that.showerror(cmp,key.split('-')[1]);
                    } else {
                        console.log(result[key]);
                        cmp.set("v.auditlist",result[key]); 
                    }
            	}    	
            }
            else if (state === "INCOMPLETE") {
                     Console.log('Server Call status Incomplete ');
            }
            else if (state === "ERROR") {
                 that.showerror(cmp,response.getError()[0].message);
            }
        });
        // $A.enqueueAction adds the server-side action to the queue.
        $A.enqueueAction(action);
    }
})