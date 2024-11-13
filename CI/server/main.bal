// Copyright (c) 2024, WSO2 LLC. (https://www.wso2.com) All Rights Reserved.
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/file;
import ballerina/http;
import ballerina/log;
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

    resource function post triggerPerfTest(TestConfig testConfig) returns PerfTestTriggerResult {
        log:printInfo("Triggering performance test");
        error? result = self.runTest(testConfig);
        if result is error {
            string message = "Failed to trigger the performance test due to " + result.message();
            log:printError(message);
            return {message};
        }
        log:printInfo("Done");
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
    log:printDebug(string `Dispatching:  ${config.toJsonString()}`);
    _ = check exec("make",
            ["run", string `GITHUB_TOKEN=${config.token}`, string `DEB_URL=${config.balInstallerUrl}`],
            ballerinaPerf);
    log:printDebug("Dispatched");
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
        log:printDebug(string `${command} ${" ".join(...args)}`);
        return os:exec({value: command, arguments: args});
    }
    string commandLine = string `cd ${cwd} && ${command} ${" ".join(...args)}`;
    log:printDebug(commandLine);
    return os:exec({
                       value: "sh",
                       arguments: ["-c", commandLine]
                   });
}

// Common types for both client and server
public type PerfTestTriggerResult "success"|record {string message;};

type Repo readonly & record {|
    string url;
    string branch;
|};

type TestConfig readonly & record {|
    string balInstallerUrl;
    string token;
    Repo repo;
|};
