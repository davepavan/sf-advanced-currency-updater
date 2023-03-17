/**
 * @description       : Scheduled apex class for updating the Dated Exchange Rates
 * @author            : dave.pavan1@gmail.com
 *
**/

global with sharing class SCH_AdvancedCurrencyUpdater implements Schedulable, Database.AllowsCallouts
{
    
    global SCH_AdvancedCurrencyUpdater() {}
    
    global void execute(SchedulableContext sc)
    {
        CTL_AdvancedCurrencyUpdater.start(System.today());
    }
}