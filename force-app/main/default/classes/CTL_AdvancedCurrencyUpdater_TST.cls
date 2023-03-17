/**
 * @description       : Test class for CTL_AdvancedCurrencyUpdater
 * @author            : dave.pavan1@gmail.com
**/

@isTest
public with sharing class CTL_AdvancedCurrencyUpdater_TST
{
    
    public static testMethod void getExchangeRatesSuccessTest()
    {
        Test.startTest();
        
        SYS_HTTPCalloutMockFxAPI_TST.setSuccessMode(true);

        Test.setMock(HttpCalloutMock.class, new SYS_HTTPCalloutMockFxAPI_TST());
        
        CTL_AdvancedCurrencyUpdater.getExchangeRates(System.today());

        Test.stopTest();
    }

    public static testMethod void getExchangeRatesFailureTest()
    {
        Test.startTest();
        
        SYS_HTTPCalloutMockFxAPI_TST.setSuccessMode(false);

        Test.setMock(HttpCalloutMock.class, new SYS_HTTPCalloutMockFxAPI_TST());
        
        String exceptionMessage;
        try 
        {
            CTL_AdvancedCurrencyUpdater.getExchangeRates(System.today());    
        } 
        catch (Exception e) 
        {
            exceptionMessage = e.getMessage();
        }
        
        System.assertEquals('Federal website webservice callout failure', exceptionMessage);

        Test.stopTest();

    }

    public static testMethod void insertOrUpdateDCRSuccessTest()
    {
        Test.startTest();
        
        SYS_HTTPCalloutMockCompositeAPI_TST.setSuccessMode(true);

        Test.setMock(HttpCalloutMock.class, new SYS_HTTPCalloutMockCompositeAPI_TST());
        
        Map<String, Decimal> exchangeRates = new Map<String,Decimal>();
        exchangeRates.put('USD', 1.9);
        exchangeRates.put('AUD', 1.5);
        CTL_AdvancedCurrencyUpdater.insertOrUpdateDCR(exchangeRates, System.today());

        Test.stopTest();
    }

    public static testMethod void insertOrUpdateDCRFailureTest()
    {
        Test.startTest();
        
        SYS_HTTPCalloutMockCompositeAPI_TST.setSuccessMode(false);

        Test.setMock(HttpCalloutMock.class, new SYS_HTTPCalloutMockCompositeAPI_TST());
        
        Map<String, Decimal> exchangeRates = new Map<String,Decimal>();
        exchangeRates.put('USD', 1.9);
        exchangeRates.put('AUD', 1.5);

        String exceptionMessage;
        try 
        {            
            CTL_AdvancedCurrencyUpdater.insertOrUpdateDCR(exchangeRates, System.today());
        } 
        catch (Exception e) 
        {
            exceptionMessage = e.getMessage();
        }
        
        System.assertEquals('DatedConversionRate Update Failure Exception', exceptionMessage);        

        Test.stopTest();
    }
}