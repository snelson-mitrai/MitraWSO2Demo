import ballerina/http;
import ballerina/log;

configurable int port = 8086;

final xml & readonly mockPayload =
    xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:tem="http://tempuri.org/" xmlns:nup="http://schemas.datacontract.org/2004/07/NuPro.Midas.Services.Orders.Models">
   <soapenv:Header/>
   <soapenv:Body>
      <tem:GetOrderTemplatesResponse>
         <!--Optional:-->
         <tem:GetOrderTemplatesResult>
            <!--Optional:-->
            <nup:Templates>
               <!--Zero or more repetitions:-->
               <nup:OrderTemplate>
                  <!--Optional:-->
                  <nup:Created>2023-11-03T00:00:00.000+05:00</nup:Created>
                  <!--Optional:-->
                  <nup:Description>Test Descriptiomn</nup:Description>
                  <!--Optional:-->
                  <nup:Frequency>Test</nup:Frequency>
                  <!--Optional:-->
                  
                  <!--Optional:-->
                  <nup:NextRunDate>2023-11-08T00:00:00.000+05:00</nup:NextRunDate><nup:Supplier>Test supplier</nup:Supplier>
               </nup:OrderTemplate>
            </nup:Templates>
         </tem:GetOrderTemplatesResult>
      </tem:GetOrderTemplatesResponse>
   </soapenv:Body>
</soapenv:Envelope>`;

@display {
    label: "MinfosAgent",
    id: "MINFOS POS Service"
}
service on new http:Listener(port) {
    resource function default [string... paths](@http:Header {name: "SOAPAction"} string soapAction,
            xml payload) returns xml|http:BadRequest {

        do {
            log:printInfo("SOAP action: " + soapAction);
        } on fail {
            log:printError("Expected a SOAP request, cannot find SOAP action.");
            return <http:BadRequest>{body: "expected a SOAP request"};
        }

        if soapAction == "MyMockOperation" {
            log:printInfo("Operation correct");
        } else {
            log:printInfo("Operation is: " + soapAction.toString());
        }
        return mockPayload;
    }
}

