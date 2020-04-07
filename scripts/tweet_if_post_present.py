import sys
import requests
import twitter

import logging

from yaml import load, Loader

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
ch = logging.StreamHandler()
ch.setLevel(logging.INFO)
ch.setFormatter(formatter)
logger.addHandler(ch)

logger.info("starting Twitter run for post")

credentials_filename=sys.argv[1]
post_url=sys.argv[2]
tweet_message=sys.argv[3]

logger.info("credentials filename: {}".format(credentials_filename))
logger.info("post URL: {}".format(post_url))
logger.info("Tweet message:\n\n{}\n".format(tweet_message))

logger.info("Testing if post URL exists...")

r = requests.get(post_url, headers={"user-agent": "DSA/0.1 (Dark and Stormy Archives)"})

if r.status_code != 200:
    logger.critical("url {} is not present, not Tweeting".format(post_url))
    sys.exit(255)

logger.info("Post URL exists, reading Twitter credentials from {}".format(credentials_filename))

with open(credentials_filename) as f:
    credentials = load(f, Loader=Loader)

api = twitter.Api(
    consumer_key=credentials['consumer_key'],
    consumer_secret=credentials['consumer_secret'],
    access_token_key=credentials['access_token_key'],
    access_token_secret=credentials['access_token_secret']
)

logger.info("tweeting message")

api.PostUpdate(tweet_message[0:250] + "..." + "\n" + post_url)

logger.info("Tweet should be available now")