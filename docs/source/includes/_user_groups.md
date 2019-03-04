#Group User Group
Resources related to _Panoptes User Groups_

## UserGroup [/user_groups/{id}{?include}]
A user group represents a collection of users that share ownership of
projects, collections, and classifications. Individual users within
the group can be given different levels of permissions to act on
group owned resources.

A User Group has the following attributes:

- id
- created_at
- updated_at
- classifications_count
- activated_state
- name
- display_name

*id*, *created_at*, *updated_at*, and *classifications_count* are all
 set by the API.

+ Model

    + Body

            {
                "links": {
                    "user_groups.projects": {
                        "href": "/projects?owner={user_groups.owner_name}",
                        "type": "projects"
                    },
                    "user_groups.classifications": {
                        "href": "/classifications?user_group_id={user_groups.id}",
                        "type": "classifications"
                    },
                    "user_groups.collections": {
                        "href": "/collections?owner={user_groups.owner_name}"
                        "type": "collections"
                    },
                    "user_groups.users": {
                        "href": "/users?user_group_id={user_groups.id}",
                        "type": "users"
                    },
                    "user_groups.memberships": {
                        "href": "/memberships?user_group_id={user_groups.id}",
                        "type": "memberships"
                    }
                },
                "user_groups": [{
                    "id": "42",
                    "name": "a_cool_group",
                    "display_name": "A Cool Group",
                    "owner_name": "a_cool_group",
                    "created_at": "2014-08-11T10:11:34Z",
                    "updated_at": "2014-12-11T00:11:34Z",
                    "classifications_count": "1002340",
                    "activated_state": "active",
                    "links": {
                        "memberships": ["101", "102"],
                        "users": ["10001", "9102"],
                        "projects": ["10"],
                        "collections": ["11"]
                    }
                }]
            }

### Retrieve a single User Group [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [UserGroup][]

### Edit a single User Group [PUT]
A user with edit permissions on a user group may edit the group's
name, display_name, or links to projects, collections and
users. Projects and Collections may only be removed. Removing a
link to a project or collection will destroy the project or
collection, removing a link to a user will set their
membership state to inactive.

Adding a user creates a membership link with an 'invited'
state. Membership and Classification links cannot be modified.

This is not the recommended way to modify links.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "user_groups": {
                    "display_name": "A Uncool Group",
                    "links": {
                        "projects": [],
                        "collections": []
                    }
                }
            }

+ Response 200

    [UserGroup][]


### Destroy a User Group [DELETE]
A user may destroy a group if they have the requisite permissions. A
destroyed group and linked projects, collections, and memberships will
be placed in an 'inactive' state.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Add a link [/user_groups/{id}/links/users]
Only links to users may be added.

### Add user links [POST]
Creates a membership for a user. The membership will be immediately
added, but a user won't show up in the group's links until they set
their membership to 'active'.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "users": ["123", "23"]
            }

+ Response 200

    [UserGroup][]

## Remove a Link [/user_groups/{id}/links/{link_type}/{link_ids}]
Allows links to users, projects, or collections to be removed. Removed
projects and collections are deleted. Removed users have their
membership set to 'inactive'.

+ Parameters
  + id (required, integer) ... id of the group to be edited.
  + link_type (required, string) ... name of the link to modify
  + link_ids (required, string) ... comma separated list of ids to remove

### Remove links [DELETE]

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## UserGroup Collection [/user_groups{?page,page_size,sort,user_id,include}]
A collection of User Group resources.

All collections add a meta attribute hash containing paging
information.

User Groups are returned as an array under *user_groups*.

+ Model

    + Body

            {
                 "links": {
                    "user_groups.projects": {
                        "href": "/projects?owner={user_groups.owner_name}",
                        "type": "projects"
                    },
                    "user_groups.classifications": {
                        "href": "/classifications?user_group_id={user_groups.id}",
                        "type": "classifications"
                    },
                    "user_groups.collections": {
                        "href": "/collections?owner={user_groups.owner_name}"
                        "type": "collections"
                    },
                    "user_groups.users": {
                        "href": "/users?user_group_id={user_groups.id}",
                        "type": "users"
                    },
                    "user_groups.memberships": {
                        "href": "/memberships?user_group_id={user_groups.id}",
                        "type": "memberships"
                    }
                },
                "meta": {
                    "user_groups": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/user_groups?page_size=2",
                        "previous_href": "/user_groups?page=14page_size=2",
                        "next_href": "/user_groups?page=2&page_size=2",
                        "last_href": "/user_groups?page=14&page_size=2"
                    }
                },
                "user_groups": [{
                    "id": "42",
                    "name": "a_cool_group",
                    "display_name": "A Cool Group",
                    "owner_name": "a_cool_group",
                    "created_at": "2014-08-11T10:11:34Z",
                    "updated_at": "2014-12-11T00:11:34Z",
                    "classifications_count": "1002340",
                    "activated_state": "active"
                    "links": {
                        "memberships": ["101", "102"],
                        "users": ["10001", "9102"],
                        "projects": ["10"],
                        "collections": ["11"]
                    }
                },{
                    "id": "44",
                    "name": "a_cool_gang",
                    "display_name": "A Cool Gang",
                    "owner_name": "a_cool_gang",
                    "created_at": "2014-09-10T10:41:54Z",
                    "updated_at": "2014-11-11T01:21:33Z",
                    "classifications_count": "2341",
                    "activated_state": "active"
                    "links": {
                        "memberships": ["101", "102"],
                        "users": ["10001", "9102"],
                        "projects": ["10"],
                        "collections": ["11"]
                    }
                }]
            }

### List all User Groups [GET]
+ Parameters
  + page (optional, integer) ... index of the page to retrieve 1 by default
  + page_size (optional, integer) ... number of items per page 20 by default
  + sort (optional, string) ... field to sort by, id by default
  + user_id (optional, integer) ... filter list to groups a user is part of
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [UserGroup Collection][]

### Create a User Group [POST]
A user can create new group by just giving it a name (how it appears
in a @mention and url) or display name (how it shown to other users).

In the case where only a display name is provided, the name will be
set to the underscored, downcased, and url escaped version of the
display name. When only a name is provided, display_name will be set
to the same string as name.

Optionally links to other users who will be given
memberships with the 'invited' state.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "user_groups": {
                    "display_name": "A Super Grouper!",
                    "links": {
                        "users": ["10", "22"]
                    }
                }
            }

+ Response 201

    [UserGroup][]
