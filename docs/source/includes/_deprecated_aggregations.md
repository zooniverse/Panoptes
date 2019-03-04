# Group Aggregation
Resources related to setting preferences for _Panoptes Collections_

## Aggregation [/aggregation/{id}{?include}]
An Aggregation resource captures the results of the aggregation engine for
the set of classifications for a particular workflow and subject.

It has the following attributes:

- id
- created_at
- updated_at
- aggregation

*id*, *created_at*, and *updated_at* are set the by the API. Aggregations are
only visible to users with rights on the workflow's associated project.

+ Parameters
  + id (required, integer) ... integer identifier of resource

+ Model

    + Body

            {
                "links": {
                    "aggregation.workflow": {
                        "href": "/workflows/{aggregation.workflow}",
                        "type": "workflows"
                    },
                    "aggregation.subject": {
                        "href": "/subjects/{aggregation.subject}",
                        "type": "subjects"
                    }
                },
                "aggregations": [{
                    "id": "5",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "aggregation": {
                        "mean": 1,
                        "std": 1,
                        "count": [1, 1, 1],
                        "workflow_version": "1.1"
                    },
                    "links": {
                        "workflow" : "3",
                        "subject": "4"
                    }
                }]
            }

### Retrieve a single Aggregation [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Aggregation][]

### Edit an Aggregation [PUT]
Only a user with rights on the workflow's project may edit an Aggregation resource.
The aggregation field may be edited.

Editing the aggregation field requires a full representation of the
aggregation object to be sent.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "aggregations": {
                    "aggregation": {
                        "mean": 1,
                    }
                }
            }

+ Response 200

    [Aggregation][]

## Aggregation Collection [/aggregations{?workflow_id,subject_id,page,page_size,sort,include}]
A Collection of Aggregation resources.

All collections add a meta attribute hash containing paging
information.

Aggregations are returned as an array under *aggregations*.

+ Model

            {
                "links": {
                    "aggregation.workflow": {
                        "href": "/workflows/{aggregation.workflow}",
                        "type": "workflows"
                    },
                    "aggregation.subject": {
                        "href": "/subjects/{aggregation.subject}",
                        "type": "subjects"
                    }
                },
                "meta": {
                    "collection_preferences": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/collection_preferences?page_size=2",
                        "previous_href": "/collection_preferences?page=14page_size=2",
                        "next_href": "/collection_preferences?page=2&page_size=2",
                        "last_href": "/collection_preferences?page=14&page_size=2"
                    }
                },
                "aggregations": [{
                    "id": "5",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "aggregation": {
                        "mean": 1,
                        "std": 1,
                        "count": [1, 1, 1],
                        "workflow_version": "1.1"
                    },
                    "links": {
                        "workflow" : "3",
                        "subject": "4"
                    }
                }, {
                    "id": "6",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:23:22Z",
                    "aggregation": {
                        "mean": 2,
                        "std": 3,
                        "count": [2, 1, 1],
                        "workflow_version": "1.2"
                    },
                    "links": {
                        "workflow" : "4",
                        "subject": "3"
                    }
                }]
            }

### List all Aggregations [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + workflow_id (optional, integer) ... workflow to see aggregations for
  + subject_id (optional, integer) ... subject_id to see aggregations for
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Aggregation Collection][]

### Create a Aggregation [POST]
Creating an Aggregation requires an aggregation hash with the _workflow_version_
set. Please note, the _workflow_version_ should be the value returned from the
specific aggregation workflow's representation. The workflow and subject links
must be provided as well.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "aggregations": {
                    "aggregation": {
                        "mean": 1,
                        "std": 1,
                        "count": [1, 1, 1],
                        "workflow_version": "1.1"
                    },
                    "links": {
                        "workflow" : "3",
                        "subject": "4"
                    }
                }
            }

+ Response 201

    [Aggregation][]
