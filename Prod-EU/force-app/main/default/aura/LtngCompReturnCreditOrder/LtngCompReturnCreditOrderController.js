({
	doInit : function(component, event, helper) {
                
        var actions = helper.getRowActions.bind(this, component);
        component.set('v.columns', [
            {label: 'Product', fieldName: 'ProductCode', editable: false, type: 'text', sortable: false},
            {label: 'Available', fieldName: 'AvailableQty', editable: false, type: 'number', sortable: false, initialWidth: 90, cellAttributes: { alignment: 'center', minimumFractionDigits : '2' }},           
            {label: 'Return', fieldName: 'ReturnQty', editable: true, type: 'number', initialWidth: 80, cellAttributes: { class: {fieldName: 'errorQTY'}, alignment: 'center', minimumFractionDigits : '2' } },
            {label: 'Return Reason', fieldName: 'ReturnReason', editable: false, type: 'text', initialWidth: 120, sortable: false },
            { type: 'action', typeAttributes: { rowActions: actions } }
        ]);
		
        console.log('***** 1.1 doInit recordId=' + component.get("v.recordId"));        
        helper.getReturnOrderProducts(component, helper);
        helper.getReturnReasons(component, helper);
    },
    
    handleRowAction: function (cmp, event, helper) {
    	 var action = event.getParam("action"),
            row = event.getParam("row"),
            data = cmp.get("v.data"),
            rowIndex = data.indexOf(row);        
        
        /*console.log('*** TPS:EH 1.1  handleRowAction row=' + JSON.stringify(row));
        console.log('*** TPS:EH 1.2  handleRowAction data=' + JSON.stringify(data));
        console.log('*** TPS:EH 1.3  handleRowAction rowIndex=' + rowIndex);
        console.log('*** TPS:EH 1.4  handleRowAction action=' + JSON.stringify(action));
        console.log('*** TPS:EH 1.5  handleRowAction action.label=' + action.label);
        console.log('*** TPS:EH 1.6  handleRowAction data[rowIndex]=' + JSON.stringify(data[rowIndex]));        
        console.log('*** TPS:EH 1.7  handleRowAction cmp.get("v.editedRecs")=' + JSON.stringify(cmp.get("v.editedRecs")));
        //data[rowIndex].ReturnReason=action.label;        
        //cmp.set("v.data", data);
        //cmp.set('v.draftValues', [{"ReturnQty":data[rowIndex].ReturnQty, "ReturnReason":action.label,"Id":data[rowIndex].Id}]);   
        //var objRR = []; objRR =cmp.get("v.editedRR"); 
        //objRR.push([{"ReturnQty":row.ReturnQty, "ReturnReason":action.label, "Id":row.Id}]);
        //cmp.set("v.editedRR", objRR);
        //console.log('*** TPS:EH 1.8 v.editedRR=' + JSON.stringify(cmp.get("v.editedRR")));*/
        //
        //console.log('*** TPS:EH 1.2  handleRowAction data1=' + JSON.stringify(data));
        var editedRecs = cmp.get("v.editedRecs");
        if(editedRecs){
            //console.log('*** TPS:EH 1.9 editedRecs.length=' + editedRecs.length);
            if(editedRecs.length==0){
        	   //console.log('*** TPS:EH 1.10 No Edits');
               cmp.set('v.draftValues', [{"ReturnQty":row.ReturnQty, "ReturnReason":action.label, "Id":row.Id}]);
               data[rowIndex].ReturnReason=action.label
            }
       		
        for (var i = 0; i < editedRecs.length; i++){
        	Object.keys(editedRecs).forEach(function (key){
                Object.keys(editedRecs[key]).forEach(function (field){
                	//console.log('*** TPS:EH 1.11  handleRowAction editedRecs Id=' + JSON.stringify(editedRecs[key][field].Id));
                    //console.log('*** TPS:EH 1.12  handleRowAction editedRecs ReturnQty=' + JSON.stringify(editedRecs[key][field].ReturnQty));
                    //console.log('*** TPS:EH 1.13  handleRowAction row Id=' + row.Id);
                    if(row.Id==editedRecs[key][field].Id){
                		data[rowIndex].ReturnQty=editedRecs[key][field].ReturnQty;
                    	data[rowIndex].ReturnReason=action.label;
                    	cmp.set('v.draftValues', [{"ReturnQty":editedRecs[key][field].ReturnQty, "ReturnReason":action.label, "Id":row.Id}]);
                        //console.log('*** TPS:EH 1.13 Setting values');
                	}
                });            	
            });
        }        
        console.log('*** TPS:EH 1.2  handleRowAction data2=' + JSON.stringify(data));
       
      }  
      /*editedRecs.forEach(element => {
                if(element.Id==row.Id){
                    console.log('*** TPS:EH 1.9  handleRowAction editedRecs ReturnQty=' + element.ReturnQty);
                	data[rowIndex].ReturnQty=element.ReturnQty;
                	data[rowIndex].ReturnReason=action.label;
                    cmp.set('v.draftValues', [{"ReturnQty":element.ReturnQty, "ReturnReason":action.label, "Id":row.Id}]);
                }
        	});
        console.log('*** TPS:EH 1.9  handleRowAction editedRecs Id=' + editedRecs[key].Id);
                console.log('*** TPS:EH 1.9  handleRowAction row Id=' + row.Id);
                if(row.Id==editedRecs[key].Id){
                	data[rowIndex].ReturnQty=editedRecs[key].ReturnQty;
                    data[rowIndex].ReturnReason=action.label;
                    cmp.set('v.draftValues', [{"ReturnQty":editedRecs[key].ReturnQty, "ReturnReason":action.label, "Id":row.Id}]);
        }*/
    },
    
    handleEditCellChange: function(cmp, event, helper) {
        helper.handleEditCell(cmp, event);
        cmp.set("v.isSave", false); cmp.set("v.RRCheck", false);    	
  	},
    
    handleSaveEdit: function(cmp, event, helper) {
        cmp.set("v.isSave", true); cmp.set("v.RRCheck", true);        
    	helper.handleSaveEdit(cmp, event, helper);
  	},
    
    handleCancelEdit: function(cmp, event, helper) {
        cmp.set("v.isError", false);	cmp.set("v.isErrorRR", false);
        helper.getReturnOrderProducts(cmp, helper);
        
        /*console.log('*** TPS:EH 1.1  handleCancelEdit event=' + event);
        cmp.set("v.isError", false);
        var data=cmp.get("v.data");
        for (var i = 0; i < data.length; i++){
        	data[i].error='';    
        }
        cmp.set("v.data", data);*/
  	},
    
})