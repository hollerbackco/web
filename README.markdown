API for HollerbackApp
=====================

Api for Hollerback.  Users can register, read and create conversations, and read and add videos


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
        name*
        email*
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

### GET /me
get a users info

    params
        access_token*     string

    response
        {
          name: 'name of user',
          email: 'email of user',
          phone: '+18885558888',
          conversation_ids: []
        }


### POST /me/conversations
create a conversation

    params
        access_token*     string
        invites*           array

    response
        {
          conversation: {
            members: [list of users],
            invites: [{phone: "+18885558888"}],
            videos: [{
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
        filename*           string

    response
        {
          data: [{
            id: 18,
            user: {..},
            url: ""
          }]
        }
