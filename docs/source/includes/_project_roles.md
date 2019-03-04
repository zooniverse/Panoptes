# Group ProjectRole
Resources related to Roles for _Panoptes Projects_

## ProjectRole [/project_roles/{id}{?include}]
A Project Role resources contains an array of roles assigned to a user
for a particular project

It has the following attributes:

- id
- created_at
- updated_at
- roles

*id*, *created_at*, and *updated_at* are set the by the API. Project
roles are visible to the project owner and the user given roles.

roles for a project may be:
- collaborator - full access to edit or delete a project
- tester - Able to see a private project
- scientist - Able to moderate project Talk and see a private project
- moderator - Able to moderate project Talk and see a private project
- translator - Able to create new and edit project and workflow translations

+ Parameters
  + id (required, integer) ... integer identifier of the project role resource

+ Model

    + Body

            {
                "links": {
                    "project_roles.owner": {
                        "href": "/{project_roles.owner.href}",
                        "type": "owners"
                    },
                    "project_roles.project": {
                        "href": "/projects/{project_roles.project}",
                        "type": "projects"
                    }
                },
                "project_roles": [{
                    "id": "942",
                    "roles": ["collaborator"],
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "project": "11"
                        "owner": {
                            "id": "3",
                            "display_name": "Owner 3",
                            "type": "users",
                            "href": "users/3"
                        }
                    }
                }]
            }

### Retrieve a single ProjectRole [GET]
+ Parameters
  + include (optional, string) ... comma separate list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectRole][]

### Edit a ProjectRole [PUT]
A user with permissions to edit a project may modify roles for other
users in the project. A user without edit permissions may not edit
their own roles.

Editing requires sending a full representation of the roles array.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_roles": {
                    "roles": ["tester", "translator"]
                }
            }

+ Response 200

    [ProjectRole][]

## ProjectRole Collection [/project_roles{?user_id,project_id,page,page_size,sort,include}]
A Collection of ProjectRole resources.

All collections add a meta attribute hash containing paging
information.

ProjectRoles are returned as an array under *project_roles*.

+ Model

    + Body

            {
                "links": {
                    "project_roles.owner": {
                        "href": "/{project_roles.owner.href}",
                        "type": "owners"
                    },
                    "project_roles.project": {
                        "href": "/projects/{project_roles.project}",
                        "type": "projects"
                    }
                },
                "meta": {
                    "project_roles": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/project_roles?page_size=2",
                        "previous_href": "/project_roles?page=14page_size=2",
                        "next_href": "/project_roles?page=2&page_size=2",
                        "last_href": "/project_roles?page=14&page_size=2"
                    }
                },
                "project_roles": [{
                    "id": "942",
                    "roles": ["collaborator"],
                    "created_at": "2014-03-20T06:23:12Z",
                    "updated_at": "2014-04-21T08:22:22Z",
                    "links": {
                        "project": "11",
                        "owner": {
                            "id": "3",
                            "display_name": "Owner 3",
                            "type": "users",
                            "href": "users/3"
                        }
                    }
                },{
                "id": "949",
                    "roles": ["tester", "translator"],
                    "created_at": "2014-08-20T06:23:12Z",
                    "updated_at": "2014-09-21T08:22:22Z",
                    "links": {
                        "project": "81",
                        "owner": {
                            "id": "33",
                            "display_name": "Owner 33",
                            "type": "users",
                            "href": "users/33"
                        }
                    }
                }]
            }

### List all ProjectRoles [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + user_id (optional, integer) ... user_id to see roles for
  + project_id (optional, integer) ... project_id to see roles for
  + include (optional, string) ... comma separate list of linked resources to load

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [ProjectRole Collection][]

### Create a ProjectRole [POST]
Creating a Project Role resource requires a link to a user and a
project. You may also include an array of roles.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "project_roles": {
                    "roles": ["collaborator"],
                    "links": {
                        "project": "11",
                        "user": "30"
                    }
                }
            }

+ Response 201

    [ProjectRole][]
