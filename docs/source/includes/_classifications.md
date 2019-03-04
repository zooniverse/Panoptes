# Classifications

```json
{
    "classifications": [{
        "id": 1001,
        "created_at": "2014-08-24T22:24:32Z",
        "updated_at": "2014-08-24T22:24:32Z",
        "completed": false,
        "metadata": {
            "started_at": "2014-08-24T22:20:21Z",
            "finished_at": "2014-08-24T22:24:31Z",
            "user_agent": "cURL",
            "user_language": "es_MX",
            "workflow_version": "11.12"
        },
        "annotations": [
            {
                "task": "task-1",
                "value": [10.4, 12.4, 13.2]
            }
        ],
        "links": {
            "user": "1",
            "subjects": ["10"],
            "workflow": "81",
            "project": "2"
        }
    }],
    "links": {
        "classifications.user": {
            "href": "/users/{classifications.user}",
            "type": "classifications"
        },
        "classifications.project": {
            "href": "/projects/{classifications.project}",
            "type": "projects"
        },
        "classifications.workflow": {
            "href": "/workflows/{classification.workflow}",
            "type": "workflows"
        },
        "classifications.subject": {
            "href": "/subjects/{classifications.subjects}",
            "type": "subjects"
        }
    },
}

```

A single Classification resource object. This represents a _user's_
responses to a _workflow's_ questions about a _subject_.

A classification has the following attributes:

Attribute | Type | Description
--------- | ---- | -----------
id | integer | read-only
created_at | string | read-only
updated_at | string | read-only
completed | string | read-only
metadata | hash |
gold_standard | boolean |
annotations | array(hash) |

Annotations is an array of maps of the form `{ "task": "task_key",
"value": "question answer" }`. Metadata contains additional information about a
classification including:

- started_at
- finished_at
- user_agent
- workflow_version
- user_language


## List classifications

```http
GET /api/classifications HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

Only lists classifications the active user has made or projects the user has edit permissions for.

Classifications have special collection routes that indicate the scope you would like to retrieve.

Possible options are:

+ `/api/classifications/` default, will fetch the current user's past complete classifications.
+ `/api/classifications/incomplete` will fetch the current user's past incomplete classifications.
+ `/api/classifications/project` will fetch classifications from projects a user has 'edit' permissions for
+ `/api/classifications/gold_standard` will fetch gold standard classifications for all marked workflows

Any of the scopes may be further filtered using the *project_id*, *workflow_id*
and *user_group_id* parameters.

### Parameters

+ page (optional, integer) ... index of the collection page, 1 is default
+ page_size (optional, integer) ... number of items on a page. 20 is default
+ sort (optional, string) ... fields to sort collection by. updated_at is default
+ project_id (optional, integer) ... only retrieve classifications for a specific project
+ workflow_id (optional, integer) ... only retrieve classifications for a specific workflow
+ user_group_id (optional, integer) ... only retrieve classifications for a specific user group
+ include (optional, string) ... comma separated list of linked resources to return with the collection
+ last_id (optional, integer) ... only classifications with ids greater than `last_id` will be returned (`/project` only, requires project_id)

<aside class="notice">
Please note that due to the cost of the page count queries on the
classifications table we are not returning the page counts for
this end point, please use the previous and next hrefs to page into the data.
</aside>


## Retrieve a single Classification

```http
GET /api/classifications/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A User may retrieve any classification, irrespective of the complete status.

### Parameters

+ `id` (required, integer) ... integer id of the resource to retrieve



## Create a Classification [POST]

```http
POST /api/classifications HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "classifications": {
        "completed": false,
        "metadata": {
            "started_at": "2014-08-24T22:20:21Z",
            "finished_at": "2014-08-24T22:24:31Z",
            "user_agent": "cURL",
            "user_language": "es_MX",
            "workflow_version": "11.12"
        },
        "annotations": [
            {
              "task": "task-name",
              "value": "Any type: string, hash, array, etc"
            }
        ],
        "links": {
            "subjects": ["11"],
            "workflow": "81",
            "project": "2"
        }
    }
}
```

Create a classification by providing a JSON-API formatted object, that
must include _metadata_, _annotations_ and a _links_ hash. Optionally, it
may include the _completed_ field, which if not included defaults to true.
The completed field is used to store half-completed classifications, so the user
can later continue from where they stopped.

The _links_ hash must contain a _subjects_ hash, a _project_ and a _workflow_.
The _metadata_ hash must contain all the keys specified in the example.
Please note, the _workflow_version_ should be the value returned from the
specific workflow representation. The annotations array must be in the
format specified in the example, i.e. an array of objects, containing a _task_ and a _value_.
The _task_ can be anything and must not necessarily align with the tasks of the workflow
(even though that is generally not advised).




## Edit a single Classification [PUT]

```http
PUT /api/classifications/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "classifications": {
        "annotations": [
            {
                "task": "task-1",
                "value": [10.4, 12.4, 13.2]
            },
            {
                "task": "workflow-2",
                "value": "fishy"
            }
        ],
        "completed": true
    }
}
```

A User may modify an incomplete classification. It should be marked as
completed when done.

The *annotations* attributes must be returned as a full representation
of the annotations array.


## Destroy a single Classification [DELETE]

```http
DELETE /api/classifications/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json
```

A User may delete an incomplete classification.
