# Group Subjects
Resources related to _Panoptes Subjects_.

## Subject [/subjects/{id}{?include}]
A single Subject object. A Subject is a resource that describe a
piece of media to be classified including metadata about the object.

- id
- zooniverse_id
- created_at
- updated_at
- locations
- metadata

*id*, *zooniverse_id*, *created_at*, and *updated_at* are assigned by
the API.

+ Parameters
  + id (required, integer) ... integer id of the subject resource

+ Model

    + Body

            {
                "links": {
                    "subjects.project": {
                        "href": "/projects/subjects.project",
                        "type": "projects"
                    },
                    "subjects.subject_sets": {
                        "href": "/subject_sets/subjects.subject_sets",
                        "type": "subject_sets"
                    }
                },
                "subjects": [{
                    "id": "1",
                    "zooniverse_id": "AGFS0001231",
                    "created_at": "2014-03-24T10:42:21Z",
                    "updated_at": "2014-03-24T10:42:21Z",
                    "locations": [
                        {"image/jpeg": "http://s3.amazonaws.com/subjects/1.png"}
                    ],
                    "metadata": {
                        "lens_type": "50mm"
                    },
                    "links": {
                        "project": "1",
                        "subject_sets": ["1"]
                    }
                }]
            }

### Retrieve a single Subject [GET]
+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Subject][]

### Edit a single Subject [PUT]
Users are permitted to edit subjects belonging to projects a user
has edit permissions for. A user may not change the project of a
subject.

The *locations* array should have the mime-types of the subject's
associated media. The response will contain signed s3 urls the client
may make a PUT request containing the media to. The signed urls will
be valid for 20 minutes.

A request chagning the *metadata* hash must contain a full
representation of the attribute.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subjects": {
                    "locations": [
                        "image/png"
                    ]
                }
            }

+ Response 200

    [Subject][]

### Destroy a single subject [DELETE]
Users are permitted to destroy a subjects they own or
subjects belongs to a project a user has destroy permissions for.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Subject Version [/subjects/{subject_id}/versions/{id}]
A Subject Version resource represents a set of changes made to
a Subject resource.

It has the following attributes:

- id
- changset
- whodunnit
- created_at

It is not editable.

+ Parameters
  + subject_id (required, integer) ... id of the subject to retreive versions for
  + id (required, integer) ... integer id of the version to load

+ Model

    + Body

            {
                "versions": [{
                    "id": "43",
                    "changeset": {
                        "metadata": [{
                            "ra": "20.2",
                            "dec": "12.4"
                        },{
                            "ra": "21.1",
                            "dec": "11.1"
                        }]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/subject/101",
                            "type": "subjects"
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

    [Subject Version][]

## Subject Version Collection [/subjects/{subject_id}/versions{?page_size,page}]
A collection of Subject Version resources.

All collections add a meta attribute hash containing paging
information.

Subject Versions are returned as an array under *versions*.

+ Parameters
  + subject_id (required, integer) ... id of the subject to retreive versions for

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
                        "first_href": "/subjects/101/versions?page_size=2",
                        "previous_href": "/subjects/101/versions?page=14page_size=2",
                        "next_href": "/subjects/101/versions/?page=2&page_size=2",
                        "last_href": "/subjects/101/versions?page=14&page_size=2"
                    }
                },
                "versions":  [{
                    "id": "42",
                    "changeset": {
                        "metadata": [{
                            "ra": "120.2",
                            "dec": "-12.4"
                        },{
                            "ra": "121.1",
                            "dec": "-11.1"
                        }]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/subject/101",
                            "type": "subjects"
                        }
                    }
                },{
                    "id": "43",
                    "changeset": {
                        "metadata": [{
                            "ra": "20.2",
                            "dec": "12.4"
                        },{
                            "ra": "21.1",
                            "dec": "11.1"
                        }]
                    },
                    "whodunnit": "stuartlynn",
                    "created_at": "2014-03-20T06:23:12Z",
                    "links": {
                        "item": {
                            "id": "101",
                            "href": "/subject/101",
                            "type": "subjects"
                        }
                    }
                }]
            }

### List all Subject Versions [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Subject Version Collection][]

## Subject Collection [/subjects{?page,page_size,sort,workflow_id,subject_set_id}]
Represents a collection of subjects.

All collections add a *meta* attribute hash containing paging information.

Subjects are returned as an array under the _subject_ key.

+ Model

    + Body

            {
                "links": {
                    "subjects.project": {
                        "href": "/projects/subjects.project",
                        "type": "projects"
                    },
                    "subjects.subject_sets": {
                        "href": "/subject_sets/subjects.subject_sets",
                        "type": "subject_sets"
                    }
                },
                "meta": {
                    "subjects": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/subjects?page_size=2",
                        "previous_href": "/subjects?page=14page_size=2",
                        "next_href": "/subjects?page=2&page_size=2",
                        "last_href": "/subjects?page=14&page_size=2"
                    }
                },
                "subjects": [{
                    "id": "1",
                    "zooniverse_id": "AGFS0001231",
                    "created_at": "2014-03-24T10:42:21Z",
                    "updated_at": "2014-03-24T10:42:21Z",
                    "locations": [
                        {"image/jpeg": "http://s3.amazonaws.com/subjects/1.png"}
                    ],
                    "metadata": {
                        "lens_type": "50mm"
                    },
                    "links": {
                        "project": "1"
                        "subject_sets": ["1"]
                    }
                },{
                    "id": "2",
                    "zooniverse_id": "AGFS0001232",
                    "created_at": "2014-03-24T10:44:21Z",
                    "updated_at": "2014-03-24T10:44:21Z",
                    "locations": [
                        {"image/jpeg": "http://s3.amazonaws.com/subjects/2.png"}
                    ],
                    "metadata": {
                        "lens_type": "50mm"
                    },
                    "links": {
                        "project": "1"
                        "subject_sets": ["1"]
                    }
                }]
            }

### Retrieve a List of Subjects [GET]

+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + workflow_id (optional, integer) ... filter to subjects belonging to a specific workflow
  + subject_set_id (optional, integer) ... return subjects belonging to the identified subject_set

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Subject Collection][]

### Retrieve subjects to classify [GET /api/v1/subjects/queued]

While the normal GET on the subjects resource will return a list of subjects in a project, there is a special API for getting some subjects that need classifications: `GET /api/v1/subjects/queued`. This special API is optimized specifically for serving a selection of subjects that should be shown to the user in the classify interface.

+ Parameters
  + workflow_id (required, integer) ... filter to subjects belonging to a specific workflow
  + subject_set_id (optional, integer) ... return subjects belonging to the identified subject_set, it is required when the workflow is grouped.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Subject Collection][]

### Create a Subject [POST]
A *locations* attribute and a project link are required.

To have the Zooniverse host your media resources the *locations* array
should have the mime-types of the subject's associated media,
e.g `"locations":["image/png", "image/jpeg", "image/png"]`,
note the locations mime types are stored in order.

The create response will contain signed s3 urls the client may make a PUT
request containing the media to. The signed urls will be valid for 20 minutes.
Please take the order of the returned s3 urls into account when PUT'ing
local media resources to the remote location.

To use your own hosted media resources the *locations* array
should be comprised of objects that represent the mime-type and the hosted URL
of the subject's associated media,
e.g. `"locations":[
{"image/png": "https://your.s3_account.com/subjects/1.png"},
{"image/jpeg": "https://your.s3_account.com/subjects/1.jpg"}
]`.

The *metadata* attribute is optional.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subjects": {
                    "locations": [
                        "image/png",
                        [
                            "video/webm",
                            "video/mp4"
                        ]
                    ],
                    "metadata": {
                        "lens_type": "50mm"
                    },
                    "links": {
                        "project": "1"
                    }
                }
            }

+ Response 201

    [Subject][]
