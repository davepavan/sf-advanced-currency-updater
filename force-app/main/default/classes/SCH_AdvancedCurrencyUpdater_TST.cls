/**
 * @description       : Test class for SCH_AdvancedCurrencyUpdater
 * @author            : dave.pavan1@gmail.com
 * 
**/
@isTest
public with sharing class SCH_AdvancedCurrencyUpdater_TST 
{
    public static testMethod void scheduleTest() 
    {
        SCH_AdvancedCurrencyUpdater obj = new SCH_AdvancedCurrencyUpdater();
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second() + 5);
        //parse to cron expression
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        System.schedule('SCH_AdvancedCurrencyUpdater Job', nextFireTime, obj);
    }
}