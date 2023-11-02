// todo!

import ballerina/http;
import ballerina/log;
import ballerina/mime;

configurable int port = 8086;

final xml & readonly mockPayload =
    xml `<soapenv:Envelope xmlns:soapenv="http://www.w3.org/2003/05/soap-envelope" xmlns:nst="http://www.example.com/mynamespace">
   <soapenv:Header>
      <!-- You can include header elements here if needed -->
   </soapenv:Header>
   <soapenv:Body>
      <nst:MyMockOperation>
         <nst:Parameter1>MockValue1</nst:Parameter1>
         <nst:Parameter2>MockValue2</nst:Parameter2>
         <!-- Add more mock parameters as needed -->
      </nst:MyMockOperation>
   </soapenv:Body>
</soapenv:Envelope>`;

@display {
    label: "MinfosAgent",
    id: "MINFOS POS Service"
}
service on new http:Listener(port) {
    resource function default [string... paths](@http:Header {name: mime:CONTENT_TYPE} string contentTypeHeader,
            xml payload) returns xml|http:BadRequest {

        string? soapAction = ();
        do {
            foreach string component in re `;`.split(contentTypeHeader) {
                string trimmedComponent = component.trim();
                if trimmedComponent.startsWith("action=") {
                    soapAction = trimmedComponent.substring(7, trimmedComponent.length());
                    log:printInfo("SOAP action:  " + soapAction.toString());
                    break;
                }
            }

            if soapAction is () {
                fail error("Failed to find the operation.");
            }
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
