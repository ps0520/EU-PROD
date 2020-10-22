trigger TrgPEErrorsEvents  on CRM_Error_Event__e (after Insert) {
    for(CRM_Error_Event__e  e : trigger.new) system.debug('Published Error Log: ' + e);
}