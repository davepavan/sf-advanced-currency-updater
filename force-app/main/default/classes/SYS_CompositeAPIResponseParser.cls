/**
 * @description       : Parser for Composite API Response
 * @author            : dave.pavan1@gmail.com
 *
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

    public SYS_CompositeAPIResponseParser(Boolean s, List<SYS_CompositeAPIResponseParser.Errors> e)
    {
        success = s;
        errors = e;
    }
}