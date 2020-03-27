#!/bin/bash

date=$1
working_directory=$2

sg_url=`cat ${working_directory}/${date}/sg.url.txt`

echo "adding StoryGraph URL ${sg_url}"

sed -i '' -e "s?^storygraph_url:.*?storygraph_url: ${sg_url//&/\\&}?g" _posts/${date}-storygraph-bigstory.html
