/**
 * @description       : Parser for Composite API Response
 * @author            : pavan.dave@pitcher.com
 *
 * * Modifications Log 
 * Ver   Date           Author                          Modification
 * 1.0   10-Mar-2023   pavan.dave@pitcher.com           Initial Version
**/

public with sharing class SYS_CompositeAPIResponseParser 
{
    public class Errors 
    {
        public String statusCode;
        public String message;
        public List<String> fields;
    }

    public Boolean success;
    public List<Errors> errors;
    
    public static List<SYS_CompositeAPIResponseParser> parse(String json) 
    {
        return (List<SYS_CompositeAPIResponseParser>) System.JSON.deserialize(json, List<SYS_CompositeAPIResponseParser>.class);
    }
}