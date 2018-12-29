#!/bin/bash

# Build the haproxy image
echo "************************  build haproxy image  ************************"
cd ha
docker build -t softengheigvd/ha .

# Build the webapp image
echo "************************  build webapp image  ************************"
cd ../webapp
docker build -t softengheigvd/webapp .
