/**
 * @description       : Fetch the exchange rates (API call) and update the Dated Exchange Rates inside Salesforce.
 * @author            : dave.pavan1@gmail.com
 *
**/

public with sharing class CTL_AdvancedCurrencyUpdater 
{
    static String endPoint = 'https://www.backend-rates.bazg.admin.ch/api/xmldaily?d=REPLACE_DATE&locale=en';    
    static Map<String, Decimal> fxRates;

    @future(callout = true)
    public static void start(Date fxDate)
    {
        if(!Test.isRunningTest())
        {
            // ------------------------------------------------------------------------------------------ //
            // --------------------- Get Exchange Rates from Federal website ---------------------------- //
            // ------------------------------------------------------------------------------------------ //
            
            fxRates = getExchangeRates(fxDate);

            if(!fxRates.isEmpty())
            {
                // ------------------------------------------------------------------------------------------ //
                // ------------------------ Update/Create Date Exchange Rates ------------------------------- //
                // ------------------------------------------------------------------------------------------ //
                
                insertOrUpdateDCR(fxRates, fxDate);
            }
        }        
    }

    public static Map<String, Decimal> getExchangeRates(Date exchagneDate) 
    {
        System.debug('exchagneDate-->'+exchagneDate);
        endPoint = endPoint.replaceAll('REPLACE_DATE', getDateString(exchagneDate));
        System.debug('endPoint-->'+endPoint);

        Map<String, Decimal> exchangeRates = new Map<String, Decimal>();        
        String currencyText;
        Integer currencyVal;
        String currencyType;

        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint(endPoint);
        request.setMethod('GET');
        HttpResponse response = http.send(request);
        // If the request is successful, parse the JSON response.
        if(response.getStatusCode() == 200) 
        {        
            DOM.Document doc = new DOM.Document();
            doc.load(response.getBody());

            for(DOM.XmlNode node: doc.getRootElement().getChildren())
            {
                //System.debug('node-->'+node);
                //System.debug('node getName-->'+node.getName());

                if(node.getName() == 'devise')
                {
                    DOM.XmlNode devise = node;
                    for(DOM.XmlNode deviseItem: devise.getChildren())
                    {
                        // System.debug('deviseItem-->'+deviseItem);
                        // System.debug('deviseItem.getName()-->'+deviseItem.getName());
                        if(deviseItem.getName() == 'waehrung')
                        {
                            currencyText = deviseItem.getText();
                            System.debug('waehrung-->'+currencyText);
                            currencyVal = Integer.valueOf(currencyText.split(' ')[0]);
                            currencyType = currencyText.split(' ')[1];
                            exchangeRates.put(currencyType, null);
                        }

                        if(deviseItem.getName() == 'kurs')
                        {
                            System.debug('kurs-->'+deviseItem.getText());
                            exchangeRates.put(currencyType, currencyVal / Decimal.valueOf(deviseItem.getText()));
                        }                                                
                    }

                    currencyText = null;
                    currencyVal = null;
                    currencyType = null;
                }
            }

            System.debug('exchangeRates-->'+exchangeRates);                

        }  
        else 
        {
            // throw exception
            throw new SCH_AdvancedCurrencyUpdaterException('Federal website webservice callout failure');
        }

        return exchangeRates;       
    }

    public static void insertOrUpdateDCR(Map<String, Decimal> exchangeRates, Date exchagneDate)
    {
        List<String> activeCurrCodes = new List<String>();
        String corpCurrType;

        List<CurrencyType> activeCurrTypes = [SELECT Id, IsoCode, IsActive, IsCorporate 
                                            FROM CurrencyType
                                            WHERE IsActive = true];

        for(CurrencyType item: activeCurrTypes)
        {
            if(item.IsCorporate)
            {
                corpCurrType = item.IsoCode;
            }
            else 
            {
                activeCurrCodes.add(item.IsoCode);    
            }                
        }

        // default current must be CHF
        // Below logic only supports CHF as default currency
        
        if(corpCurrType == 'CHF')
        {
            List<DatedConversionRate> listExistingConversionRate = [SELECT Id, IsoCode, StartDate, NextStartDate, ConversionRate 
                                                                    FROM DatedConversionRate
                                                                    WHERE IsoCode IN: activeCurrCodes
                                                                    AND StartDate =: exchagneDate];

            Map<String, DatedConversionRate> mapExistingConversionRate = new Map<String, DatedConversionRate>();
            for(DatedConversionRate item: listExistingConversionRate)
            {
                mapExistingConversionRate.put(item.IsoCode, item);
            }

            // Create a list of UpdatePatchRecordWrapper to write to the JSON string.
            List<UpdatePatchRecordWrapper> updatePatchRecordList = new List<UpdatePatchRecordWrapper>();

            List<InsertPatchRecordWrapper> insertPatchRecordList = new List<InsertPatchRecordWrapper>();

            for(String activeCurrCodeitem: activeCurrCodes)
            {
                if(mapExistingConversionRate.containsKey(activeCurrCodeitem))
                {
                    System.debug('DatedExchangeRate record already exists for Currency Code ---->' + activeCurrCodeitem + '  StartDate --->' + exchagneDate);                                             
                    updatePatchRecordList.add(new UpdatePatchRecordWrapper('DatedconversionRate', mapExistingConversionRate.get(activeCurrCodeitem).Id, exchangeRates.get(activeCurrCodeitem)));                                                    
                }
                else 
                {
                    System.debug('DatedExchangeRate record NOT FOUND for Currency Code ---->' + activeCurrCodeitem + '  StartDate --->' + exchagneDate);                                             
                    insertPatchRecordList.add(new InsertPatchRecordWrapper('DatedconversionRate', activeCurrCodeitem, exchagneDate, exchangeRates.get(activeCurrCodeitem)));
                }
            }


            Http h = new Http();
            HttpRequest req = new HttpRequest();                
            req.setHeader ('Authorization', 'Bearer ' + UserInfo.getSessionID()); 
            req.setHeader('Content-Type', 'application/json'); 
            req.setHeader('Content-Length', '0'); 
            String endpoint = URL.getSalesforceBaseUrl().toExternalForm(); 
            system.debug ('********endpoint:' + endpoint); 
            endpoint = endpoint + '/services/data/v56.0/composite/sObjects';                 
            
            System.debug('updatePatchRecordList size--->'+updatePatchRecordList.size());
            
            if(!updatePatchRecordList.IsEmpty())
            {
                // Make PATCH REST API Callout
                                    
                req.setEndpoint(endpoint + '?_HttpMethod=PATCH');
                req.setMethod('POST');
                
                // ------------------------------------------------ //                        
                // Prepare request body
                // ------------------------------------------------ //
                
                req.setBody(prepareCompositeCalloutBody(updatePatchRecordList));
                
                HttpResponse res = h.send(req);           
                System.debug('Update Response Body ---->'+res.getBody());        

                List<SYS_CompositeAPIResponseParser> outputList = SYS_CompositeAPIResponseParser.parse(res.getBody());                    
                                    
                if(hasFailureResponse(outputList)) 
                {
                    throw new SCH_AdvancedCurrencyUpdaterException('DatedConversionRate Update Failure Exception');
                }

                
            }

            System.debug('insertPatchRecordList size--->'+insertPatchRecordList.size());

            if(!insertPatchRecordList.isEmpty())
            {
                // Make POST REST API callout

                req.setEndpoint(endpoint);
                req.setMethod('POST');

                // ------------------------------------------------ //                        
                // Prepare request body
                // ------------------------------------------------ //
                
                req.setBody(prepareCompositeCalloutBody(insertPatchRecordList));

                HttpResponse res = h.send(req);         
                System.debug('Insert Response Body ---->'+res.getBody());

                List<SYS_CompositeAPIResponseParser> outputList = SYS_CompositeAPIResponseParser.parse(res.getBody());
                
                if(hasFailureResponse(outputList)) 
                {
                    throw new SCH_AdvancedCurrencyUpdaterException('DatedConversionRate Update Failure Exception');
                }
            }
        }
        else 
        {
            // throw exception    
            throw new SCH_AdvancedCurrencyUpdaterException('Default currency is not set to CHF');
        }
    }

    public static string getDateString(Date d)
    {
        String dateVal;

        dateVal = d.year() + '';
        
        if(d.month() < 10)
        {
            dateVal += '0' + d.month();
        }
        else 
        {
            dateVal += d.month();
        }

        if(d.day() < 10)
        {
            dateVal += '0' + d.day();
        }
        else 
        {
            dateVal += d.day();    
        }

        return dateVal;
    }

    public static String prepareCompositeCalloutBody(object anyObject)
    {   
        String jsonStringBody;

        // Create a JSONGenerator object.
        // Pass true to the constructor for jsonStringBody print formatting.
        JSONGenerator gen = JSON.createGenerator(true);
                                                    
        // Write data to the JSON string.
        gen.writeStartObject();
        gen.writeStringField('allOrNone', 'true');

        gen.writeFieldName('records');                       
        gen.writeObject(anyObject); 

        gen.writeEndObject();
        
        // Get the JSON string.
        jsonStringBody = gen.getAsString();
        System.debug('jsonStringBody--->'+jsonStringBody);

        return jsonStringBody;
    }

    public static Boolean hasFailureResponse(List<SYS_CompositeAPIResponseParser> outputList)
    {
        System.debug('outputList---->'+outputList);
        
        Boolean hasFailure = false;
        for(SYS_CompositeAPIResponseParser item: outputList)
        {
            if(item.success == false)
            {
                hasFailure = true;          //since allOrNone is set to true
                break;
            }
        }
        return hasFailure;
    }

    public class UpdatePatchRecordWrapper 
    { 
        PatchAttributeWrapper attributes;
        String Id;
        Decimal ConversionRate;
                
        public UpdatePatchRecordWrapper(String t, String recId, Decimal cr) 
        { 
            attributes = new PatchAttributeWrapper(t); 
            Id = recId;
            ConversionRate = cr;            
        }
    }

    public virtual class BaseException extends Exception {}
    public class SCH_AdvancedCurrencyUpdaterException extends BaseException {}
    
    public class PatchAttributeWrapper
    {
        String type;

        public PatchAttributeWrapper(String t) { type = t; }
    }

    public class InsertPatchRecordWrapper 
    { 
        PatchAttributeWrapper attributes;
        String IsoCode;
        String StartDate;
        Decimal ConversionRate;
                
        public InsertPatchRecordWrapper(String t, String c, Date d, Decimal cr) 
        { 
            attributes = new PatchAttributeWrapper(t); 
            IsoCode = c;
            StartDate = '' + d.year() + '-' + d.month() + '-' + d.day();            
            ConversionRate = cr;            
        }
    }
}