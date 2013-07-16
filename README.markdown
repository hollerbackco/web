TODO
- install graphite/statsd to start measuring performance and monitor server

activity

1. Main web api;
2. Sidekiq background workers;
3. Poller services listens to video-stitch-ready sqs queue. Marks stitched;

videos as complete.

API for HollerbackApp
=====================

Users can register, read and create conversations, and read and add videos


Server
------
temp server is located at http://calm-peak-4397.herokuapp.com/


Dependencies
------------
Only runs on postgres. Installing postgres:
http://www.moncefbelyamani.com/how-to-install-postgresql-on-a-mac-with-homebrew-and-lunchy/


Installing Locally
------------------

    bundle install
    createdb hollerback_dev
    rake db:migrate
    rerun -- thin start


The Envelope
------------
Every response is contained by an envelope. That is, each response has a predictable set of keys with which you can expect to interact:

    {
        "meta": {
            "code": 200
        },
        "data": {
            ...
        },
        "pagination": {
            "next_url": "...",
            "next_max_id": "13872296"
        }
    }


Routes
------

### POST /register
register a user

    params
        email*
        username*
        password*
        phone*             string, i.e. '+18885558888'

    response
        {
          access_token: "anaccesstoken",
          user: {}
        }

### POST /session
get an access token

    params
        email*
        password*

    response
        {
          access_token: "anaccesstoken",
          user: {}
        }

### GET /me/conversations
list of conversations

    params
        access_token*     string

    response
        {
          data: [{
            unread_count: 10,
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
              isRead: false,
              id: 1,
              created_at: timestamp,
              url: "http://url",
              meta: {}
            }]
          }]
        }

### POST /me/conversations
create a conversation

    params
        access_token*     string
        invites*           array of phone numbers

    response
        {
          data: {
            id: 1,
            unread_count: 10,
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
              isRead: false,
              id: 1,
              created_at: timestamp,
              url: "http://url",
              meta: {}
            }]
          }
        }

### GET /me/conversations/:id
get info about a conversation

    params
        access_token*     string

    response
        {
          data: {
            id: 18,
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
              isRead: false,
              id: 1,
              created_at: timestamp,
              url: "http://url",
              meta: {}
            }]
          }
        }

### POST /me/conversations/:id/videos
get info about a conversation

    params
        access_token*     string
        filename*         string

    response
        {
          data: [{
            id: 18,
            user: {..},
            url: ""
          }]
        }

### POST /me/videos/:id/read
mark a video as read

    params
        access_token*     string

    response
        {
          data: {
            conversation_id: 1,
            id: 18,
            created_at: timestamp,
            isRead: true,
            user: {..},
            url: ""
          }
        }
