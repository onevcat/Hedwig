#!/bin/sh
cd ./test_smtp_server
sudo npm start
cd ..
swift test
cd ./test_smtp_server
sudo npm stop