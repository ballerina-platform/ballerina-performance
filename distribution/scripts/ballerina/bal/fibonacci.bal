import ballerina/http;

http:ListenerConfiguration serviceConfig = {
    secureSocket: {
        keyStore: {
            path: "${ballerina.home}/bre/security/ballerinaKeystore.p12",
            password: "ballerina"
        }
    }
};

@http:ServiceConfig { basePath: "/fibonacci" }
service passthroughService on new http:Listener(9090, serviceConfig) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{input}"
    }
    resource function passthrough(http:Caller caller, http:Request clientRequest, int input) {
        http:Response response = new;
        int payload = fibonacci(input);
        var result = caller->respond(payload);
    }
}

function fibonacci(int n) returns int {
    if (n == 0) {
        return 0;
    } else if (n == 1) {
      return 1;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}
