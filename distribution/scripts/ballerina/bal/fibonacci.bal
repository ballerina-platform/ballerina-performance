import ballerina/http;

@http:ServiceConfig { basePath: "/fibonacci" }
service fibonacciService on new http:Listener(9090) {

    @http:ResourceConfig {
        methods: ["POST"],
        path: "/{input}"
    }
    resource function fibonacciResource(http:Caller caller, http:Request clientRequest, int input) {
        http:Response response = new;
        int payload = fibonacci(input);
        var result = caller->respond(input.toString() + "th fibonacci number: " + payload.toString());
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
