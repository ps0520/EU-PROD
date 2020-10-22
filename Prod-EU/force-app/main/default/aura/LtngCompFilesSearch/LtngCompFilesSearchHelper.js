({
    loadContentMetaData : function(component) {
        //call apex class method by passing in the parameter
        var action = component.get("c.getContentMetadata");
        action.setParams({
            recordId : component.get("v.recordId")
        });
        //Retrieve and process the response
        action.setCallback (this, function(response){
            var state = response.getState();
            if(component.isValid() && state == "SUCCESS")
            {
                var ccData = response.getReturnValue();
                //alert('Got Response From Controller 12');
                component.set('v.data', ccData);
                component.set("v.filteredData", ccData);
            }
        });
        $A.enqueueAction(action);             
    },
    
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.filteredData");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse))
        cmp.set("v.filteredData", data);
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
        function(x) {return x[field]};
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    }
})