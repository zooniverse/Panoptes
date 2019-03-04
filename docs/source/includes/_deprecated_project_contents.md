# Group ProjectContents
Resources related to the translatable strings for _Panotpes Projects_.

## ProjectContent [/project_contents/{id}{?include}]
A Project Content resources contains all strings for a project for a
particular language. This resource will normally only be accessed by
project translators. Users will receive translated versions of
projects based on their *Accept-Language* header or preferences.

It has the following attributes

- id
- language
- title
- description
- created_at
- updated_at
- introduction
- science_case
- team_members
- guide

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
                    "project_content.project": {
                        "href": "/project/{project_content.project}",
                        "type": "projects"
                    }
                },
                "project_contents": [{
                    "id": "42",
                    "language": "en_UK",
                    "title": "A Labourious and Colourful project",
                    "description": "Lots of colours and labour go into this",
                    "introduction": "Text..",
                    "science_case": "More text..",
                    "team_memebrs": [{
                        "name": "Rocky",
                        "bio": "a bio",
                        "institution": "whatsmattau",
                        "twitter": "@rocky",
                    }],
                    "guide": {
                        "image": "http://asdfasdf.jpg.gif",
                        "explanation": "It's a bear!"
                    },
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "project": "11"
                    }
                }]
            }


### Retrieve a single ProjectContent [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectContent][]

### Update a ProjectContent [PUT]
Only users with edit permissions for the parent project or users who
have the "translator" roles may edit project contents".

The *team_members* and *guide* fields must be updated as a full
representation. The *language* field is not editable once created.

Project Contents that have the same language as their parent project's
primary_language field may not be edited.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_contents": {
                    "title": "A Less Labourious Title"
                }
            }

+ Response 200

    [ProjectContent][]

### Destroy a ProjectConent [DELETE]
Only users who edit permissions for the parent project may remove
project content models.

Project Contents that have the same language as their parent project's
primary_language field may not be destroyed.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## ProjectContent Version [/project_contents/{project_contents_id}/versions/{id}]
A Project Content Version resource represents a set of changes made to
a Project Content resource.

It has the following attributes:

- id
- changset
- whodunnit
- created_at

It is not editable.

+ Model

    + Body

            {
                "versions": [{
                    "id": "42",
                    "changeset": {
                        "title": ["A Colourful Project", "A Colorful Project"]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            id: "101",
                            "href": "/project_contents/101",
                            "type": "project_contents"
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

    [ProjectContent Version][]


## ProjectContent Version Collection [/project_contents/{project_contents_id}/versions{?page_size,page}]
A collection of Project Content Version resources.

All collections add a meta attribute hash containing paging
information.

Project Content Versions are returned as an array under *versions*.

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
                        "first_href": "/project_contents/101/versions?page_size=2",
                        "previous_href": "/project_contents/101/versions?page=14page_size=2",
                        "next_href": "/project_contents/101/versions/?page=2&page_size=2",
                        "last_href": "/project_contents/101/versions?page=14&page_size=2"
                    }
                },
                "versions": [{
                    "id": "42",
                    "changeset": {
                        "title": ["A Colourful Project", "A Colorful Project"]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            id: "101",
                            "href": "/project_contents/101",
                            "type": "project_contents"
                        }
                    }
                },{
                    "id": "43",
                    "changeset": {
                        "description": ["No Words Here!", "Words"]
                    },
                    "whodunnit": "edwardothegreat",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            id: "101",
                            "href": "/project_contents/101",
                            "type": "project_contents"
                        }
                    }
                }]
            }

### List all Project Content Versions [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectContent Version Collection][]

## ProjectContent Collection [/project_contents{?project_id,language,page,page_size,include}]
A collection of Project Content resources.

All collections add a meta attribute hash containing paging
information.

Project Contents are returned as an array under *project_contents*.

+ Model

    + Body

            {
                "links": {
                    "project_contents.project": {
                        "href": "/project/{project_content.project}",
                        "type": "projects"
                    }
                },
                "meta": {
                    "project_contents": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/project_contents?page_size=2",
                        "previous_href": "/project_contents?page=14page_size=2",
                        "next_href": "/project_contents?page=2&page_size=2",
                        "last_href": "/project_contents?page=14&page_size=2"
                    }
                },
                "project_contents": [{
                    "id": "42",
                    "language": "en_UK",
                    "title": "A Labourious and Colourful project",
                    "description": "Lots of colours and labour go into this",
                    "introduction": "Text..",
                    "science_case": "More text..",
                    "team_memebrs": [{
                        "name": "Rocky",
                        "bio": "a bio",
                        "institution": "whatsmattau",
                        "twitter": "@rocky",
                    }],
                    "guide": {
                        "image": "http://asdfasdf.jpg.gif",
                        "explanation": "It's a bear!"
                    },
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "project": "11"
                    }
                },
                {
                    "id": "43",
                    "language": "en_CA",
                    "title": "A Labourious and Colourful project",
                    "description": "Lots of colours and labour go into this",
                    "introduction": "Text..",
                    "science_case": "More text..",
                    "team_memebrs": [{
                        "name": "Rocky",
                        "bio": "a bio",
                        "institution": "whatsmattau",
                        "twitter": "@rocky",
                    }],
                    "guide": {
                        "image": "http://asdfasdf.jpg.gif",
                        "explanation": "It's a bear!"
                    },
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "project": "11"
                    }
                }]
            }

### List all ProjectContents [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + project_id (optional, integer) ... project_id to see contents for
  + language (optional, string) ... language code to search for
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectContent Collection][]

### Create ProjectContent [POST]
A ProjectContent resource can be created for a project by either a
user with edit permissions for the project or a user with a
"translator" role.

The *language* field and a link to a project are the only required
fields to created a ProjectContent resource.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_contents": {
                    "language": "es",
                    "links": {
                        "project": "11"
                    }
                }
            }

+ Response 201

    [ProjectContent][]

# Group WorkflowContents
Resources related to the translatable strings for _Panotpes Workflows_.
