# Group ProjectPreference
Resources related to setting preferences for _Panoptes Projects_

## ProjectPreference [/project_preferences/{id}{?include}]
A Project Preference resource captures a user's settings for a
particular project.

It has the following attributes:

- id
- created_at
- updated_at
- preferences
- email_communication

*id*, *created_at*, and *updated_at* are set the by the API. Project
 preferences are only visible to user they belong to.

+ Parameters
  + id (required, integer) ... integer identifier of resource

+ Model

    + Body

            {
                "links": {
                    "project_preferences.user": {
                        "href": "/user/{project_preferences.user}",
                        "type": "users"
                    },
                    "project_preferences.project": {
                        "href": "/projects/{project_preferences.project}",
                        "type": "projects"
                    }
                },
                "project_preferences": [{
                    "id": "942",
                    "email_communication": true,
                    "preferences": {
                        "tutorial": true
                    },
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "user" : "30",
                        "project": "11"
                    }
                }]
            }

### Retrieve a single ProjectPreference [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectPreference][]

### Edit a ProjectPreference [PUT]
Only the owning user may edit a Project Preference resource. The
email_communication field and the preferences field may be edited.

Editing the preferences field requires a full representation of the
preferences hash to be sent.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_preferences": {
                    "preferences": {
                        "mini_course": false,
                    }
                }
            }

+ Response 200

    [ProjectPreference][]

## ProjectPreference Collection [/project_preferences{?user_id,project_id,page,page_size,sort,include}]
A Collection of ProjectPreference resources.

All collections add a meta attribute hash containing paging
information.

ProjectPreferences are returned as an array under *project_preferences*.

+ Model

            {
                "links": {
                    "project_preferences.user": {
                        "href": "/user/{project_preferences.user}",
                        "type": "users"
                    },
                    "project_preferences.project": {
                        "href": "/projects/{project_preferences.project}",
                        "type": "projects"
                    }
                },
                "meta": {
                    "project_preferences": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/project_preferences?page_size=2",
                        "previous_href": "/project_preferences?page=14page_size=2",
                        "next_href": "/project_preferences?page=2&page_size=2",
                        "last_href": "/project_preferences?page=14&page_size=2"
                    }
                },
                "project_preferences": [{
                    "id": "942",
                    "email_communication": true,
                    "preferences": {
                        "tutorial": true
                    },
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "user" : "30",
                        "project": "11"
                    }
                },{
                    "id": "949",
                    "email_communication": true,
                    "preferences": {
                        "tutorial": true
                    },
                    "created_at": "2014-08-20T06:23:12Z",
                    "updated_at": "2014-09-21T08:22:22Z",
                    "links": {
                        "user" : "33",
                        "project": "81"
                    }
                }]
            }

### List all ProjectPreferences [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + user_id (optional, integer) ... user_id to see preferences for
  + project_id (optional, integer) ... project_id to see preferences for
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectPreference Collection][]

### Create a ProjectPreference [POST]
Creating a Project Preference requires only a link to a
project. Optionally a boolean flag for email_communication or a hash
of settings for preferences may be included.

Since a user can only create, read, or modify their own preferences
the currently logged in user is always set as the linked user on
creation.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_preferences": {
                    "email_communication": true,
                    "preferences": {
                        "tutorial": true
                    },
                    "links": {
                        "project": "1"
                    }
                }
            }

+ Response 201

    [ProjectPreference][]

### Edit a ProjectPreference Setting [POST]
Project owners may edit the settings attribute of any user's Project Preferences associated
with that project (and only that project). You need to provide the "user_id" and the "project_id"
to specify the resource to apply the settings update to. Note: in the settings payload the
"workflow_id" is the only accepted parameter.

+ Parameters
  + user_id (string) ... The id of the user whose preference needs updating
  + project_id (string) ... The id of the project the preference setting should be scoped to
+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_preferences": {
                    "settings": {
                        "workflow_id": 1234,
                    }
                }
            }

+ Response 200

    [ProjectPreference][]
