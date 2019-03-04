# Group Subject Set
Resources related to _Panoptes SubjectSets_

## SubjectSet [/subject_sets/{id}{?include}]
Subject Sets represent collections of Subjects that are paired with a
workflow of questions to be answered. A SubjectSet belongs to one
Workflow, while a single Workflow may have many SubjectSets.

A SubjectSet has the following attributes

- id
- display_name
- metadata
- set_member_subjects_count
- created_at
- updated_at

All attributes except display_name are set by the API

+ Parameters
  + id (required, integer) ... integer id of the subject_set to retrieve

+ Model

    + Body

            {
                "links": {
                    "subject_sets.workflows": {
                        "href": "/workflows?subject_set_id={subject_sets.id}",
                        "type": "workflows"
                    },
                    "subject_sets.subjects": {
                        "href": "/subjects{?subject_set_id=subject_sets.id}",
                        "type": "subjects"
                    },
                    "subject_sets.set_member_subjects": {
                        "href": "/set_member_subjects{?subject_set_id=subject_sets.id}",
                        "type": "set_member_subjects"
                    },
                    "subject_sets.project": {
                        "href": "/project/{subject_sets.project}",
                        "type": "projects"
                    }
                },
                "subject_sets": [{
                    "id": "20",
                    "display_name": "Weird Looking Galaxies",
                    "metadata": {
                        "category": "things"
                    },
                    "created_at": "2014-02-13T10:11:34Z",
                    "updated_at": "2014-02-13T10:11:34Z",
                    "set_member_subject_count": 100,
                    "links": {
                        "project": "1",
                        "workflow": "10"
                    }
                }]
            }

### Retrieve a single Subject Set [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [SubjectSet][]

### Edit a single Subject Set [PUT]
A user may only edit a subject if they edit permissions for the parent
project. The display_name attributes and links to workflows and subjects are
editable. Editing links requires a full representation of the new set
of links, but does not destroy unlinked resources.

This is not the recommended way to manage linked subjects.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

              {
                  "subject_sets": {
                      "display_name": "Normal Galaxies",
                      "links": {
                          "subjects": ["1", "2", "4", "5", "10"]
                      }
                  }
              }

+ Response 200

    [SubjectSet][]

### Destroy a single Subject Set [DELETE]
A user may only destroy a subject set if they have destroy permissions
for the subject set's project.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Subject Set Links [/subject_sets/{id}/links/{link_type}]
Allows the addition of links to subjects to a subject
set object without needing to send a full representation of the linked
relationship.

This is the recommended way to managed linked subjects.

+ Parameters
  + id (required, integer) ... the id of the Subject Set to modify
  + link_type (required, string) ... the relationship to modify must be the same as the supplied body key

### Add to link [POST]
Only Subjects links may be edited.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subjects": ["1", "5", "9", "11"]
            }

+ Response 200

    [SubjectSet][]

## Destroy Subject Set Links [/subject_sets/{id}/links/{link_type}/{link_ids}]
Allows links to be removed without sending a full representation of the
linked relationship.

+ Parameters
  + id (required, integer) ... the id of the Subject Set to modify
  + link_type (required, string) ... the relationship to modify
  + link_ids (required, integer) ... comma separated list of ids to remove

### Destroy some links [DELETE]
Will only remove the link. This operation does not destroy the linked object.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## SubjectSet Collection [/subject_sets{?page,page_size,sort,project_id,workflow_id,include}]
A collection of SubjectSet resources.

All collections add a meta attribute hash containing paging
information.

Subject Sets are returned as an array under *subject_sets*.

+ Model

    + Body

            {
                "links": {
                    "subject_sets.workflows": {
                        "href": "/workflows?subject_set_id={subject_sets.id}",
                        "type": "workflows"
                    },
                    "subject_sets.subjects": {
                        "href": "/subjects{?subject_set_id=subject_sets.id}",
                        "type": "subjects"
                    },
                    "subject_sets.set_member_subjects": {
                        "href": "/set_member_subjects{?subject_set_id=subject_sets.id}",
                        "type": "set_member_subjects"
                    },
                    "subject_sets.project": {
                        "href": "/project/{subject_sets.project}",
                        "type": "projects"
                    }
                },
                "meta": {
                    "subject_sets": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/subject_sets?page_size=2",
                        "previous_href": "/subject_sets?page=14page_size=2",
                        "next_href": "/subject_sets?page=2&page_size=2",
                        "last_href": "/subject_sets?page=14&page_size=2"
                    }
                },
                "subject_sets": [{
                    "id": "20",
                    "display_name": "Weird Looking Galaxies",
                    "metadata": {
                        "category": "things"
                    },
                    "created_at": "2014-02-13T10:11:34Z",
                    "updated_at": "2014-02-13T10:11:34Z",
                    "set_member_subject_count": 100,
                    "links": {
                        "project": "1",
                        "workflow": "10"
                    }
                },{
                    "id": "20",
                    "display_name": "Boring Looking Galaxies",
                    "metadata": {
                        "category": "things"
                    },
                    "created_at": "2014-02-13T10:11:34Z",
                    "updated_at": "2014-02-13T10:11:34Z",
                    "set_member_subject_count": 100,
                    "links": {
                        "project": "1",
                        "workflow": "11"
                    }
                }]
            }

### Retrieve a list of Subject Sets [GET]
+ Parameters
  + page (optional, integer) ... index of the page to retrieve 1 by default
  + page_size (optional, integer) ... number of items per page 20 by default
  + sort (optional, string) ... field to sort by, id by default
  + project_id (optional, integer) ... filter by linked project
  + workflow_id (optional, integer) ... filter by linked workflow
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [SubjectSet Collection][]

### Create a Subject Set [POST]
A subject set must supply a display_name and a link to a project. Optionally,
it may include links to subjects and a single workflow.

Instead of a list of subjects a SubjectSet may include a link to a
Collection which will import the collection's subjects into a new
SubjectSet.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subject_sets": {
                    "display_name": "A Group of Interesting Subjects",
                    "metadata": {
                        "category": "things"
                    },
                    "links": {
                        "project": "43",
                        "workflows": ["47"],
                        "subjects": ["234", "1243", "8023"]
                    }
                }
            }

+ Response 201

    [SubjectSet][]
