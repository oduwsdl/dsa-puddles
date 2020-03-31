#!/bin/bash

set -e

input_filename=$1
working_directory=$2

bfilename=`basename "${input_filename}"`
echo "base file name is ${bfilename}"

set +e
echo ${bfilename} | grep spst
status=$?
if [ $status == 0 ]; then
    story_type="Sliding Page Sliding Time"
    collection_id=`echo ${bfilename} | sed 's/spst.*$//g'`
fi
set -e

set +e
echo ${bfilename} | grep fpst
status=$?
if [ $status == 0 ]; then
    story_type="Fixed Page Sliding Time"
    collection_id=`echo ${bfilename} | sed 's/fpst.*$//g'`
fi
set -e

set +e
echo ${bfilename} | grep spft
status=$?
if [ $status == 0 ]; then
    story_type="Sliding Page Fixed Time"
    collection_id=`echo ${bfilename} | sed 's/spft.*$//g'`
fi
set -e

set +e
echo ${bfilename} | grep 1s_
status=$?
if [ $status == 0 ]; then
    generated_by="an expert archivist"
    post_layout="archiveit_curator_2016_post"
fi
set -e

set +e
echo ${bfilename} | grep 0s_
status=$?
if [ $status == 0 ]; then
    generated_by="the 2016 DSA software"
    post_layout="archiveit_dsacode_2016_post"
fi
set -e

archiveit_collection_url="https://archive-it.org/collections/${collection_id}"

echo "------"
echo "extracted story data:"
echo "Collection ID: ${collection_id}"
echo "Story type: ${story_type}"
echo "Generated by: ${generated_by}"
echo "Archive-It collection URL: ${archiveit_collection_url}"
echo "------"

jekyll_story_file=_posts/2016-10-07-archiveit-storify-story-${bfilename/_urims.tsv/}.html
metadata_file=${working_directory}/${bfilename/_urims.tsv/}-metadata.json
story_data_file=${working_directory}/${bfilename/_urims.tsv/}.json

echo "------"
echo "writing data out to Jekyll post file ${jekyll_story_file}"
echo "------"

# 1. Use Hypercane to generate metadata report
if [ ! -e ${metadata_file} ]; then
    hc report metadata -i archiveit -a ${collection_id} -o ${metadata_file} -cs mongodb://localhost/csStoryGraph 
fi

# 2. Generate Raintale story data
if [ ! -e ${story_data_file} ]; then
    hc synthesize raintale-story -i mementos -a "${input_filename}" -o ${story_data_file} -cs mongodb://localhost/csStoryGraph --collection_metadata ${metadata_file}
    # Hypercane should extract the title from the metadata
fi

# 3. Generate Raintale story
if [ ! -e ${jekyll_story_file} ]; then

    echo "`date` --- executing command:::"
    tellstory -i "${story_data_file}" --storyteller template --story-template raintale-templates/2016-archiveit-storify-story.html -o ${jekyll_story_file} --collection-url ${archiveit_collection_url} --generation-date 2016-10-07T12:56:22 --generated-by "${generated_by}"

    sed -i '' -e "s/{{ story_type }}/${story_type}/g" ${jekyll_story_file}
    sed -i '' -e "s/{{ post_layout }}/${post_layout}/g" ${jekyll_story_file}
    sed -i '' -e "s/{{ collection_id }}/${collection_id}/g" ${jekyll_story_file}

fi