/**
 * @description       : HTTP Mock Callout for Currency Exchange
 * @author            : dave.pavan1@gmail.com
 * 
**/

@isTest
global class SYS_HTTPCalloutMockFxAPI_TST_TST implements HttpCalloutMock 
{
    @testVisible static Boolean successMode;

    global HTTPResponse respond(HTTPRequest req) 
    {
        Boolean isFederalWebsite = req.getEndpoint().startsWith('https://www.backend-rates.bazg.admin.ch');
        System.assertEquals(isFederalWebsite, true);

        // This class is only going to support GET method since this webservice only used to fetch the records
        System.assertEquals('GET', req.getMethod());
        
        HttpResponse res = new HttpResponse();
            
        res.setHeader('Content-Type', 'application/xml');

        if(successMode == true)
        {
            String body = '<wechselkurse>'+
                                '<datum>16.03.2023</datum>'+
                                '<zeit>03:05:01</zeit>'+
                                '<gueltigkeit>17.03.2023</gueltigkeit>'+
                                '<devise code="eur">'+
                                    '<land_de>Europäische Währungsunion</land_de>'+
                                    '<land_fr>Union monétaire européenne</land_fr>'+
                                    '<land_it>Unione Monetaria Europea</land_it>'+
                                    '<land_en>Euro Member</land_en>'+
                                    '<waehrung>1 EUR</waehrung>'+
                                    '<kurs>0.99646</kurs>'+
                                '</devise>'+
                            '</wechselkurse>';
                        
            res.setBody(body);
            res.setStatusCode(200);
        }
        else 
        {
            res.setStatusCode(400);
            res.setBody('<error></error>');
        }            

        return res;
    }

    @TestVisible static void setSuccessMode(Boolean val)
    {   
        successMode = val;
    }
}