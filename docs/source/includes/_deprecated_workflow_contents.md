## WorkflowContent [/workflow_contents/{id}{?include}]
A Workflow Content resource contains strings for a workflow in a
particular language.

This resource will normally only be accessed by
project translators. Users will receive translated versions of
workflows based on their *Accept-Language* header or preferences.

It has the following attributes

- id
- language
- created_at
- updated_at
- strings

*id*, *created_at*, and *updated_at* are created by the api
server.

*language* is a two or five character identifier where the first two
characters are the [ISO 639](http://en.wikipedia.org/wiki/ISO_639)
language codes. In the five character version, the middle character
may be a "-" or "_" and the final two characters the [ISO 3166-1 alpha-2](http://en.wikipedia.org/wiki/ISO_3166-1_alpha-2)
country code. This allows multiple translations for each language, for
instance Simplified Chinese (zh_CN) vs Traditional Chinese (zh_TW or
zh_HK).

+ Parameters
  + id (required, integer) ... integer id of the resource

+ Model

    + Body

            {
                "links": {
                    "workflow_contents.workflow": {
                        "href": "/workflows/{workflow_content.workflow}",
                        "type": "workflows"
                    }
                },
                "workflow_contents": [{
                    "id": "43",
                    "strings": [
                        "a string",
                        "oh look",
                        "another one"
                    ],
                    "language": "en_US",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "workflow": "11"
                    }
                }]
            }


### Retrieve a single WorkflowContent [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [WorkflowContent][]

### Update a WorkflowContent [PUT]
Only users with edit permissions for the parent project or users who
have the "translator" roles may edit workflow contents.

The *strings* field must be edited as a full representation. The
*language* field may not be changed.

Workflow Contents that have the same language as their parent workflow's
primary_language field may not be edited.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "workflow_contents": {
                    "strings": [
                        "a replacement string"
                    ]
                }
            }

+ Response 200

    [WorkflowContent][]

### Destroy a WorkflowConent [DELETE]
Only users who edit permissions for the parent project may remove
workflow content models.

Workflow Contents that have the same language as their parent workflow's
primary_language field may not be destroyed.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## WorkflowContent Version [/workflow_contents/{workflow_contents_id}/versions/{id}]
A Workflow Content Version resource represents a set of changes made to
a Workflow Content resource.

It has the following attributes:

- id
- changset
- whodunnit
- created_at

It is not editable.

+ Parameters
  + workflow_contents_id (required, integer) ... id of the workflow to retrieve versions for
  + id (required, integer) ... integer id of the version to load

+ Model

    + Body

            {
                "versions": [{
                    "id": "42",
                    "changeset": {
                        "strings": [[
                            "a string",
                            "another string",
                            "stringer bell"
                        ],[
                            "a string",
                            "another string",
                            "Stringer Bell"
                        ]]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/workflow_contents/101",
                            "type": "workflow_contents"
                        }
                    }
                }]
            }

### Retrieve a Single Version [GET]

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [WorkflowContent Version][]


## WorkflowContent Version Collection [/workflow_contents/{workflow_contents_id}/versions{?page_size,page}]
A collection of Workflow Content Version resources.

All collections add a meta attribute hash containing paging
information.

Workflow Content Versions are returned as an array under *versions*.

+ Parameters
  + workflow_contents_id (required, integer) ... id of the workflow to retrieve versions for

+ Model

    + Body

            {
                "meta": {
                    "versions": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/workflow_contents/101/versions?page_size=2",
                        "previous_href": "/workflow_contents/101/versions?page=14page_size=2",
                        "next_href": "/workflow_contents/101/versions/?page=2&page_size=2",
                        "last_href": "/workflow_contents/101/versions?page=14&page_size=2"
                    }
                },
                "versions":  [{
                    "id": "42",
                    "changeset": {
                        "strings": [[
                            "a string",
                            "another string",
                            "stringer bell"
                        ],[
                            "a string",
                            "another string",
                            "Stringer Bell"
                        ]]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/workflow_contents/101",
                            "type": "workflow_contents"
                        }
                    }
                },{
                    "id": "43",
                    "changeset": {
                        "strings": [[
                            "a string",
                            "another string",
                            "Stringer Bell"
                        ],[
                            "a string",
                            "a brother string",
                            "Stringer Bell"
                        ]]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/workflow_contents/101",
                            "type": "workflow_contents"
                        }
                    }
                }]
            }

### List all Workflow Content Versions [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [WorkflowContent Version Collection][]

## WorkflowContent Collection [/workflow_contents{?workflow_id,language,page,page_size,include}]
A collection of Workflow Content resources.

All collections add a meta attribute hash containing paging
information.

Workflow Contents are returned as an array under *workflow_contents*.

+ Model

    + Body

            {
                "links": {
                    "workflow_contents.workflow": {
                        "href": "/project/{workflow_content.workflow}",
                        "type": "workflows"
                    }
                },
                "meta": {
                    "workflow_contents": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/workflow_contents?page_size=2",
                        "previous_href": "/workflow_contents?page=14page_size=2",
                        "next_href": "/workflow_contents?page=2&page_size=2",
                        "last_href": "/workflow_contents?page=14&page_size=2"
                    }
                },
                "workflow_contents": [{
                    "id": "43",
                    "strings": [
                        "a string",
                        "oh look",
                        "another one"
                    ],
                    "language": "en_US",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "workflow": "11"
                    }
                },{
                    "id": "44",
                    "strings": [
                        "a string",
                        "oh look",
                        "another one"
                    ],
                    "language": "en_US",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "workflow": "12"
                    }
                }]
            }

### List all WorkflowContents [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + workflow_id (optional, integer) ... id of workflow to see contents for
  + language (optional, string) ... language code to search for
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [WorkflowContent Collection][]

### Create WorkflowContent [POST]
A WorkflowContent resource can be created for a workflow by either a
user with edit permissions for the parent project or a user with a
"translator" role.

The *language* field and a link to a workflow are the only required
fields to create a WorkflowContent resource.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "workflow_contents": {
                    "language": "es",
                    "links": {
                        "workflow": "11"
                    }
                }
            }

+ Response 201

    [WorkflowContent][]
