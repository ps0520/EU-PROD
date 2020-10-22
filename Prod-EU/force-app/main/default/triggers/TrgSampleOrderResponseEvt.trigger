trigger TrgSampleOrderResponseEvt on Sample_Order_Response_Event__e (after insert) {
    System.debug('**OCE-OUT-SampleTriggerCall--'+trigger.new);
    new ClsSampleOrderCalloutReqHandler(trigger.new);
}