#!/bin/bash

export PATH=/usr/local/bin:$PATH

set -e
set -x

if [ -z $1 ]; then
    echo "You must specify a collection ID"
    exit 255
else
    collection_id=$1
fi

if [ -z $2 ]; then
    echo "You must specify a working directory"
    exit 255
else
    working_directory=$2/${collection_id}
    mkdir -p ${working_directory}
fi

if [ -z $3 ]; then
    mementoembed_endpoint="http://localhost:5550"
else
    mementoembed_endpoint=$3
fi

sg_month=`date '+%m'`
sg_date=`date '+%d'`
sg_year=`date '+%Y'`
sg_hour=`date '+%H'`
sg_minute=`date '+%m'`
sg_second=`date '+%S'`

post_date="${sg_year}-${sg_month}-${sg_date}"

cache_storage=mongodb://localhost/cs${collection_id}
mementos_file=${working_directory}/story-mementos.tsv
metadata_report=${working_directory}/metadata.json
entity_report=${working_directory}/entity_data.tsv
sumgram_report=${working_directory}/sumgram_data.tsv
image_report=${working_directory}/imagedata.json
sorted_mementos_file=${working_directory}/sorted-story-mementos.tsv
story_data_file=${working_directory}/raintale-story.json
jekyll_story_file=_posts/${post_date}-archiveit-collection-${collection_id}.html

# 1. sample mementos from the collection
if [ ! -e ${mementos_file} ]; then
    echo "`date` --- executing command"
    hc sample dsa1 -i archiveit -a ${collection_id} \
        -cs ${cache_storage} \
        --working-directory ${working_directory} \
        -l ${working_directory}/${collection_id}-`date '+%Y%m%d%H%M%S'`.log \
        --memento-damage-url http://localhost:32768 \
        -o ${mementos_file}

else

    echo "already discovered ${mementos_file} so moving on to next command..."

fi

# 2. Gather collection metadata
if [ ! -e ${metadata_report} ]; then
    echo "`date` --- executing command"
    hc report metadata -i archiveit -a ${collection_id} -cs ${cache_storage} -o ${metadata_report} -l ${working_directory}/${collection_id}-report-metadata-`date '+%Y%m%d%H%M%S'`.log
else
    echo "already discovered ${metadata_report} so moving on to next command..."
fi

# 3. Generate entity report
if [ ! -e ${entity_report} ]; then
    echo "`date` --- executing command"
    hc report entities -i mementos -a ${mementos_file} -cs ${cache_storage} -o ${entity_report} -l ${working_directory}/${collection_id}-report-entities-`date '+%Y%m%d%H%M%S'`.log
else
    echo "already discovered ${entity_report} so moving on to next command..."
fi

# 4. Generate sumgram report
if [ ! -e ${sumgram_report} ]; then
    echo "`date` --- executing command"
    hc report terms -i mementos -a ${mementos_file} -cs ${cache_storage} -o ${sumgram_report} --sumgrams -l ${working_directory}/${collection_id}-report-terms-`date '+%Y%m%d%H%M%S'`.log
else
    echo "already discovered ${sumgram_report} so moving on to next command..."
fi

# 5. Generate image report
if [ ! -e ${image_report} ]; then
    echo "`date` --- executing command"
    hc report image-data -i mementos -a ${mementos_file} -cs ${cache_storage} -o ${image_report} -l ${working_directory}/${collection_id}-report-imagedata-`date '+%Y%m%d%H%M%S'`.log
else
    echo "already discovered ${image_report} so moving on to next command..."
fi

# 6. Consolidate reports and URI-M list to generate Raintale story data
if [ ! -e ${story_data_file} ]; then
    echo "`date` --- executing command:::"
    hc synthesize raintale-story -i mementos -a ${mementos_file} -o ${story_data_file} -cs ${cache_storage} --imagedata ${image_report} --title "Archive-It Collection" --termdata ${sumgram_report} --entitydata ${entity_report} --collection_metadata ${metadata_report}
else
    echo "already discovered ${story_data_file} so moving on to next command..."
fi

# 7. Generate Jekyll HTML file for the day's rank r story
if [ ! -e ${jekyll_story_file} ]; then
    echo "`date` --- executing command:::"
    tellstory -i ${story_data_file} --storyteller template --story-template raintale-templates/archiveit-collection-template1.html -o ${jekyll_story_file} --mementoembed_api ${mementoembed_endpoint} --generated-by "AlNoamany's Algorithm"
else
    echo "already created story at ${jekyll_story_file}"
fi