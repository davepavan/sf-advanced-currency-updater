/**
 * @description       : Scheduled apex class for updating the Dated Exchange Rates
 * @author            : pavan.dave@pitcher.com
 *
 * * Modifications Log 
 * Ver   Date           Author                          Modification
 * 1.0   10-Mar-2023   pavan.dave@pitcher.com           Initial Version
**/

global with sharing class SCH_AdvancedCurrencyUpdater implements Schedulable, Database.AllowsCallouts
{
    
    global SCH_AdvancedCurrencyUpdater() {}
    
    global void execute(SchedulableContext sc)
    {
        CTL_AdvancedCurrencyUpdater.start(System.today());
    }
}