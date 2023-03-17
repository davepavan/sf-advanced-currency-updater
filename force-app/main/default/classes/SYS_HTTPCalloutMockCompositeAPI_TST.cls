
/**
 * @description       : HTTP Mock Callout for SF Composite API
 * @author            : dave.pavan1@gmail.com
 * 
**/

@isTest
global with sharing class SYS_HTTPCalloutMockCompositeAPI_TST implements HttpCalloutMock 
{
    @testVisible static Boolean successMode;

    global HTTPResponse respond(HTTPRequest req) 
    {
        Boolean isCompositeAPI = req.getEndpoint().contains('/composite/sObjects');
        System.assertEquals(isCompositeAPI, true);

        HttpResponse res = new HttpResponse();
            
        res.setHeader('Content-Type', 'application/xml');

        if(req.getMethod() == 'POST')
        {
            List<SYS_CompositeAPIResponseParser> body = new List<SYS_CompositeAPIResponseParser>();                
            SYS_CompositeAPIResponseParser.Errors errorItem = new SYS_CompositeAPIResponseParser.Errors();
                
            if(req.getEndpoint().endsWith('?_HttpMethod=PATCH'))
            {
                // Mock the PATCH Response
                if(successMode == true)
                {
                    SYS_CompositeAPIResponseParser item = new SYS_CompositeAPIResponseParser(true, new List<SYS_CompositeAPIResponseParser.Errors>{errorItem});
                    body.add(item);
                                
                    res.setBody(JSON.serialize(body));
                    res.setStatusCode(200);
                }
                else 
                {
                    SYS_CompositeAPIResponseParser item = new SYS_CompositeAPIResponseParser(false, new List<SYS_CompositeAPIResponseParser.Errors>{errorItem});
                    // currently we are not reading errors hence keeping it empty for now
                    body.add(item);

                    res.setBody(JSON.serialize(body));
                    res.setStatusCode(400);
                    
                }            
            }
            else 
            {
                // Mock the POST Response
                if(successMode == true)
                {
                    SYS_CompositeAPIResponseParser item = new SYS_CompositeAPIResponseParser(true, new List<SYS_CompositeAPIResponseParser.Errors>{errorItem});
                    body.add(item);
                                
                    res.setBody(JSON.serialize(body));
                    res.setStatusCode(200);
                }
                else 
                {
                    SYS_CompositeAPIResponseParser item = new SYS_CompositeAPIResponseParser(false, new List<SYS_CompositeAPIResponseParser.Errors>{errorItem});
                    // currently we are not reading errors hence keeping it empty for now
                    body.add(item);

                    res.setBody(JSON.serialize(body));
                    res.setStatusCode(400);                    
                }            
            }
        }            

        return res;
    }

    @TestVisible static void setSuccessMode(Boolean val)
    {   
        successMode = val;
    }
}