#!/bin/bash

mkdir -p data
mkdir -p target
docker run -v $(pwd)/data:/root/bow-wow/data -v $(pwd)/target:/root/bow-wow/target -it bow-wow-container
