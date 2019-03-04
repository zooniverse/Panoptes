
# Group SubjectWorkflowStatus
Resources related to setting preferences for _Panoptes Subject Workflow Status_

## SubjectWorkflowStatus [/SubjectWorkflowStatus/{id}{?include}]
An SubjectWorkflowStatus resource collates the status of a subject in a workflow.
This status includes the classificaiton count and the retirement state and reason.

It has the following attributes:

- id
- classifications_count
- retired_at
- retirement_reason,
- updated_at
- created_at

*id*, *created_at*, and *updated_at* are set the by the API. SubjectWorkflowStatuses are
only visible to users with rights on the workflow's associated project.

+ Parameters
  + id (required, integer) ... integer identifier of resource

+ Model

    + Body

            {
                "links": {
                    "SubjectWorkflowStatuses.workflow": {
                        "href": "/workflows/{subject_workflow_statuses.workflow}",
                        "type": "workflows"
                    },
                    "SubjectWorkflowStatuses.subject": {
                        "href": "/subjects/{subject_workflow_statuses.subject}",
                        "type": "subjects"
                    }
                },
                "subject_workflow_statuses": [{
                    "id": "1",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "classifications_count": 10,
                    "retired_at": "2014-04-21T08:22:22Z",
                    "retirement_reason": "consensus",
                    "links": {
                        "workflow" : "3",
                        "subject": "4"
                    }
                }]
            }

### Retrieve a single SubjectWorkflowStatus [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [SubjectWorkflowStatus][]

## SubjectWorkflowStatus Collection [/SubjectWorkflowStatuses{?workflow_id,subject_id,page,page_size,sort,include}]
A Collection of SubjectWorkflowStatus resources.

All collections add a meta attribute hash containing paging
information.

SubjectWorkflowStatuses are returned as an array under *subject_workflow_statuses*.

+ Model

            {
                "links": {
                    "SubjectWorkflowStatuses.workflow": {
                        "href": "/workflows/{subject_workflow_statuses.workflow}",
                        "type": "workflows"
                    },
                    "SubjectWorkflowStatus.subject": {
                        "href": "/subjects/{subject_workflow_statuses.subject}",
                        "type": "subjects"
                    }
                },
                "meta": {
                    "collection_preferences": {
                        "page": 1,
                        "page_size": 2,
                        "count": 2,
                        "include": [],
                        "page_count": 1,
                        "previous_page": 0,
                        "next_page": 0,
                        "first_href": "/subject_workflow_statuses?page_size=2",
                        "previous_href": "",
                        "next_href": "",
                        "last_href": "/subject_workflow_statuses?page=2&page_size=2"
                    }
                },
                "subject_workflow_statuses": [{
                    "id": "1",
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "classifications_count": 10,
                    "retired_at": "2014-04-21T08:22:22Z",
                    "retirement_reason": "consensus",
                    "links": {
                        "workflow" : "3",
                        "subject": "4"
                    }
                },{
                    "id": "2",
                    "created_at": "2014-03-21T06:23:12Z",
                    "updated_at": "2014-04-22T08:22:22Z",
                    "classifications_count": 2,
                    "retired_at": "2014-04-22T08:22:22Z",
                    "retirement_reason": "blank",
                    "links": {
                        "workflow" : "3",
                        "subject": "5"
                    }
                }]
            }

### List all SubjectWorkflowStatuses [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + workflow_id (optional, integer) ... workflow to see SubjectWorkflowStatuses for
  + subject_id (optional, integer) ... subject_id to see SubjectWorkflowStatuses for
  + include (optional, string) ... comma separated list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [SubjectWorkflowStatus Collection][]
