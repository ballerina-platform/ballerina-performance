import ballerina/file;
import ballerina/http;
import ballerina/io;
import ballerina/os;

configurable string password = ?;
configurable string epKeyPath = "ballerinaKeystore.p12";
configurable int port = 443;

listener http:Listener ep = new (port,
    secureSocket = {
        key: {
            path: epKeyPath,
            password: password
        }
    }
);

service / on ep {
    final string basePath;

    function init() {
        self.basePath = "./runArtifacts";
        checkpanic createDirIfNotExists(self.basePath);
    }

    resource function post triggerPerfTest(TestConfig testConfig) returns PerfTestTiggerResult {
        io:println("Triggering performance test");
        error? result = self.runTest(testConfig);
        if result is error {
            string errorMessage = "Failed to trigger the performance test due to " + result.message();
            io:println(errorMessage);
            return {message: result.message()};
        }
        io:println("Done");
        return "success";
    }

    isolated function runTest(TestConfig testConfig) returns error? {
        check dispatch(self.basePath, testConfig);
    }
}

isolated function createDirIfNotExists(string path) returns error? {
    if !check file:test(path, file:EXISTS) {
        return file:createDir(path);
    }
}

isolated function dispatch(string basePath, TestConfig config) returns error? {
    string ballerinaPerf = check file:createTempDir(dir = basePath);
    var {url, branch} = config.repo;
    check cloneRepository(url, branch, ballerinaPerf);
    io:println("Dispatching: ", config);
    _ = check exec("make",
            ["run", string `GITHUB_TOKEN=${config.token}`, string `DEB_URL=${config.balInstallerUrl}`],
            ballerinaPerf);
    io:println("Dispatched");
}

isolated function cloneRepository(string url, string branch, string targetPath) returns error? {
    if !check file:test(targetPath, file:EXISTS) {
        return error(string `Target path ${targetPath}  doesn't exists`);
    }
    os:Process proc = check os:exec({value: "git", arguments: ["clone", url, targetPath, "-b", branch]});
    int exitCode = check proc.waitForExit();
    if (exitCode != 0) {
        return error("Failed to clone the repository");
    }
}

isolated function exec(string command, string[] args, string? cwd = ()) returns os:Process|error {
    if cwd == () {
        io:println(string `${command} ${" ".join(...args)}`);
        return os:exec({value: command, arguments: args});
    }
    string commandLine = string `cd ${cwd} && ${command} ${" ".join(...args)}`;
    io:println(commandLine);
    return os:exec({
                       value: "sh",
                       arguments: ["-c", commandLine]
                   });
}

// Common types for both client and server
public type PerfTestTiggerResult "success"|record {string message;};

type Repo readonly & record {|
    string url;
    string branch;
|};

type TestConfig readonly & record {|
    string balInstallerUrl;
    string token;
    Repo repo;
|};
