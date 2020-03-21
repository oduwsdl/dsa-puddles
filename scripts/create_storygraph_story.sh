#!/bin/bash

set -e
set -x

if [ -z $1 ]; then
    working_directory=`mktemp -d -t storygraph-stories-`
else
    working_directory=$1
    mkdir -p ${working_directory}
fi

if [ -z $2 ]; then
    sg_month=`date '+%m'`
    sg_date=`date '+%d'`
    sg_year=`date '+%Y'`
else
    sg_date=`echo $2 | awk -F- '{ print $3 }'`
    sg_month=`echo $2 | awk -F- '{ print $2 }'`
    sg_year=`echo $2 | awk -F- '{ print $1 }'`
fi

echo "`date` --- using working directory ${working_directory}"
echo "`date` --- using year: ${sg_year} ; month: ${sg_month}; date: ${sg_date}"


hr_sg_date="${sg_year}-${sg_month}-${sg_date}"
echo hr_sg_date=$hr_sg_date

# 1. query StoryGraph service for rank r story of the day
if [ ! -e ${working_directory}/story-original-resources.tsv ]; then

    sg_file="${working_directory}/sgtk-maxgraph-${sg_year}${sg_month}${sg_date}.json"

    echo "creating StoryGraph file ${sg_file}"

    # sgtk --pretty-print -o ${sg_file} maxgraph \
    #     --start-mm-dd ${sg_month}-${sg_date} --end-mm-dd ${sg_month}-${sg_date} \
    #     --daily-maxgraph-count 1 --year ${sg_year}
    sgtk --pretty-print -o ${working_directory}/graphs_links.txt maxgraph \
        --daily-maxgraph-count=0 -y ${sg_year} --start-mm-dd=${sg_month}-${sg_date} --end-mm-dd=${sg_month}-${sg_date} \
        --cluster-stories --format=maxstory_links --maxstory-count=1 > ${working_directory}/sg-output.txt 2>&1
    sg_base_uri=`cat ${working_directory}/sg-output.txt | grep "service uri:" | awk '{ print $3 }'`
    sg_fragment=`cat ${working_directory}/sg-output.txt | grep "maxgraph cursor:" | awk '{ print $3 }'`
    echo "${sg_base_uri}${sg_fragment}" > ${working_directory}/sg.url.txt
    # grep '"graph_uri":' ${sg_file} | sed 's/^[ ]*"graph_uri": "//g' | sed 's/"[,]*$//g' > ${working_directory}/sg.url.txt

    echo "URI-Rs" > ${working_directory}/story-original-resources.tsv
    cat ${working_directory}/graphs_links.txt >> ${working_directory}/story-original-resources.tsv
    # grep '"link":' ${sg_file} | sed 's/^[ ]*"link": "//g' | sed 's/"$//g' >> ${working_directory}/story-original-resources.tsv

else
    echo "already discovered ${working_directory}/story-original-resources.tsv so moving on to next command..."
fi

# 2. Create URI-Ms from URI-Rs
if [ ! -e ${working_directory}/story-mementos.tsv ]; then
    hc identify mementos -i original-resources -a ${working_directory}/story-original-resources.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/story-mementos.tsv
else
    echo "already discovered ${working_directory}/story-mementos.tsv so moving on to next command..."
fi

# 3. Generate entity report
if [ ! -e ${working_directory}/entity_data.tsv ]; then
    echo "`date` --- executing command"
    hc report entities -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/entity_data.tsv
else
    echo "already discovered ${working_directory}/entity_data.tsv so moving on to next command..."
fi

# 4. Generate sumgram report
if [ ! -e ${working_directory}/sumgram_data.tsv ]; then
    echo "`date` --- executing command"
    hc report terms -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/sumgram_data.tsv --sumgrams
else
    echo "already discovered ${working_directory}/sumgram_data.tsv so moving on to next command..."
fi

# 5. Generate image report
if [ ! -e ${working_directory}/imagedata.json ]; then
    echo "`date` --- executing command"
    hc report image-data -i mementos -a ${working_directory}/story-mementos.tsv -cs mongodb://localhost/csStoryGraph -o ${working_directory}/imagedata.json
else
    echo "already discovered ${working_directory}/imagedata.json so moving on to next command..."
fi

# 6. Order URI-Ms by publication date
if [ ! -e ${working_directory}/sorted-story-mementos.tsv ]; then
    echo "`date` --- executing command:::"
    hc order pubdate-else-memento-datetime -i mementos -a ${working_directory}/story-mementos.tsv -o ${working_directory}/sorted-story-mementos.tsv -cs mongodb://localhost/csStoryGraph
else
    echo "already discovered ${working_directory}/sorted-story-mementos.tsv so moving on to next command..."
fi

# 7. Consolidate reports and URI-M list to generate Raintale story data
if [ ! -e ${working_directory}/raintale-story.json ]; then
    echo "`date` --- executing command:::"
    hc synthesize raintale-story -i mementos -a ${working_directory}/story-mementos.tsv -o ${working_directory}/raintale-story.json -cs mongodb://localhost/csStoryGraph --imagedata ${working_directory}/imagedata.json --title "StoryGraph Biggest Story ${hr_sg_date}" --termdata ${working_directory}/sumgram_data.tsv --entitydata ${working_directory}/entity_data.tsv
else
    echo "already discovered ${working_directory}/raintale-story.json so moving on to next command..."
fi

post_date=`date '+%Y-%m-%d'`
# 8. Generate Jekyll HTML file for the day's rank r story
if [ ! -e _posts/${post_date}-storygraph-bigstory.html ]; then
    echo "`date` --- executing command:::"
    sg_url=`cat ${working_directory}/sg.url.txt`
    tellstory -i ${working_directory}/raintale-story.json --storyteller template --story-template raintale-templates/storygraph-story.html -o _posts/${post_date}-storygraph-bigstory.html --collection-url ${sg_url}
else
    echo "already created story at _posts/${post_date}-storygraph-bigstory.html"
fi

# 9. Publish to GitHub Pages
git pull
git add _posts/${post_date}-storygraph-bigstory.html
git commit -m "adding storygraph story for ${post_date}"
git push
