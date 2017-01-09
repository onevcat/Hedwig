#!/bin/sh
cd ./test_smtp_server
npm start
cd ..
swift test
cd ./test_smtp_server
npm stop