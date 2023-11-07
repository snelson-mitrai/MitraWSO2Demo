import ballerina/http;
import ballerina/log;

configurable int port = 8086;

@display {
    label: "MinfosAgent",
    id: "MINFOS POS Service"
}
service on new http:Listener(port) {
    resource function default [string... paths](@http:Header {name: "SOAPAction"} string soapAction,
            xml payload) returns xml|http:BadRequest {
        do {
            string trimmedComponent = soapAction.trim();
            string operation = trimmedComponent.substring(34, trimmedComponent.length());
            log:printInfo("Operation is: " + operation.toString());
            if operation == "GetOrderTemplates" {
                return mockGetTemplatesPayload;
            } else if operation == "CreateOrderTemplate" {
                return createTemplateMockPayload;
            } else if operation == "EditOrderTemplate" {
                return editOrderTemplatePayload;
            }
        }
        on fail {
            log:printError("Expected a SOAP request, cannot find SOAP action.");
            return <http:BadRequest>{body: "Expected a SOAP request"};
        }
        return mockGetTemplatesPayload;
    }
}

final xml & readonly mockGetTemplatesPayload =
    xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetOrderTemplatesResponse>
         <tem:GetOrderTemplatesResult>
            <nup:Templates>
               <nup:OrderTemplate>
                  <nup:Created>2023-11-06T00:00:00.000+05:00</nup:Created>
                  <nup:Description>The order template that captures Rosuvastin 6mg water soluable  film coated tablets</nup:Description>
                  <nup:Frequency>FORTNIGHTY</nup:Frequency>
                  <nup:NextRunDate>2023-11-30T00:00:00.000+05:00</nup:NextRunDate>
                  <nup:Supplier>Mylan Australia QLD</nup:Supplier>
               </nup:OrderTemplate>
            </nup:Templates>
         </tem:GetOrderTemplatesResult>
      </tem:GetOrderTemplatesResponse>
   </soapenv:Body>
</soapenv:Envelope>`;

final xml & readonly createTemplateMockPayload = 
    xml `
    <soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:CreateOrderTemplateResponse/>
   </soapenv:Body>
</soapenv:Envelope>`;

final xml & readonly editOrderTemplatePayload = 
    xml `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tem="http://tempuri.org/">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:EditOrderTemplateResponse/>
   </soapenv:Body>
</soapenv:Envelope>`;
