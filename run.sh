#!/bin/bash
set -e
echo "Dist name: $1"
echo "Intaller name: $2"
mkdir -p ./tmp
cp ./build/dist.tar.gz ./tmp
pushd ./tmp
tar -xvf dist.tar.gz
tar -xvf $1.tar.gz
pushd $1
./cloudformation/run-performance-tests.sh \
-u heshanp@wso2.com \
-f ../$1.tar.gz \
-k /home/ubuntu/perf/bhashinee-ballerina.pem \
-n bhashinee-ballerina \
-j /home/ubuntu/perf/apache-jmeter-5.1.1.tgz \
-o /home/ubuntu/perf/jdk-8u345-linux-x64.tar.gz \
-g /home/ubuntu/perf/gcviewer-1.36.jar \
-s 'wso2-ballerina-test1-' \
-b ballerina-sl-9 \
-r 'us-east-1' \
-J c5.xlarge -S c5.xlarge -N c5.xlarge -B c5.large \
-i ../$2 \
-- -d 360 -w 180 \
-u 100 -u 200 -u 500 -u 1000 \
-b 500 -b 1000 -b 10000 -b 100000 \
-s 0 -j 2G -k 2G -m 2G -l 2G

summary_file=$(find . -name "summary.md" | head | xargs realpath)
if [ ! -f $summary_file ]; then
    echo "The file summary.md does not exist."
    exit 1
fi
echo "Summary file: $summary_file"
popd
popd
pushd ..

gh repo clone ballerina-platform/ballerina-performance new-ballerina-performance
pushd new-ballerina-performance
timestamp=$(date +"%Y%m%d%H%M%S")
git checkout -b "performance-results-${timestamp}"
mkdir -p performance-results
cp "$summary_file" "./performance-results/${timestamp}.md"
git add ./performance-results/${timestamp}.md
git commit -m "Add performance test results for ${timestamp}"

gh pr create --title "Add performance test results for ${timestamp}" --body "This PR adds the performance test results for ${timestamp}."
