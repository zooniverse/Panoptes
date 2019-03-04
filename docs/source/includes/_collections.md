
# Group Collection
Resources related to _Panoptes Collections_.

## Collection [/collection/{id}]
A collection is a user curated set of subjects for a particular
project.

It has the following attributes:

- id
- created_at
- updated_at
- name
- display_name
- default_subject

*id*, *created_at*, and *updated_at* are set by the API.

+ Model

    + Body

            {
                "links": {
                    "collections.subjects": {
                        "href": "/subjects{?collection_id=collections.id}",
                        "type": "subjects"
                    }
                },
                "collections": [{
                    "id": "101",
                    "created_at": "2014-04-20T06:23:12Z",
                    "updated_at": "2014-04-20T06:23:12Z",
                    "name" : "flowers",
                    "display_name": "Lots of Pretty flowers",
                    "default_subject_src": "panoptes-uploads.zooniverse.org/production/subject_location/hash.jpeg",
                    "links": {
                        "owner": {
                            "id": "10",
                            "display_name": "Owner 10",
                            "href": "/users/10",
                            "type": "users"
                        }
                    }
                }]
            }

### Retrieve a single collection [GET]

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Collection][]

### Edit a collection [PUT]
A user may edit a collection they are the owner of or have edit
permissions for. A user may edit a collection's name, or display_name,
and may also send a full representation of a collections subject links
or a single subject id to set the default subject.

Sending subject links through a put is not recommend, especially if a
collection has many subjects.

Removing subjects from a collection does not destroy the subject record.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "collections": {
                    "name": "flower_power",
                }
            }

+ Response 200

    [Collection][]

### Destroy a Collection [DELETE]
A user who is the owner of a collection or who has destroy permissions
for a collection, may delete it.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Add subject links [/collections/{id}/links/subjects]
Add subjects to a collection.

### Add links [POST]
A user is permitted to add subject if they are the collection owner or
have edit permissions.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "subjects": ["1", "2"]
            }

+ Response 200

    [Collection][]

## Remove subject links [/collection/{id}/links/subjects/{link_ids}]
Remove subjects from a collection.

### Remove links [DELETE]
A user is permitted to remove subjects if they are the collection
owner or have edit permissions.

+ Parameters
  + id (required, integer) ... id of collection to edit
  + link_ids (required, string) ... comma separated list of ids to remove

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Add default subject link [/collections/{id}/links/default_subject]
Links a default subject to a collection. This subject's first media
location URL will be included in the serialized collection and used
as the thumbnail. Update this attribute with `null` to use the first
subject in the linked list instead.

### Add links [POST]
A user is permitted to add a default subject if they are the collection
owner or have edit permissions.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "default_subject": "1"
            }

+ Response 200

    [Collection][]

## Collection Collection [/collections{?page,page_size,sort,owner}]
A collection of Collection resources.

All collections add a meta attribute hash containing paging
information.

Collections are returned as an array under *collections*.

+ Model

    + Body

            {
                "links": {
                    "collections.subjects": {
                        "href": "/subjects{?collection_id=collections.id}",
                        "type": "subjects"
                    }
                },
                "meta": {
                    "collections": {
                        "page": 1,
                        "page_size": 2,
                        "count": 28,
                        "include": [],
                        "page_count": 14,
                        "previous_page": 14,
                        "next_page": 2,
                        "first_href": "/collections?page_size=2",
                        "previous_href": "/collections?page=14page_size=2",
                        "next_href": "/collections?page=2&page_size=2",
                        "last_href": "/collections?page=14&page_size=2"
                    }
                },
                "collections": [{
                    "id": "101",
                    "created_at": "2014-04-20T06:23:12Z",
                    "updated_at": "2014-04-20T06:23:12Z",
                    "name" : "flowers",
                    "display_name": "Lots of Pretty flowers",
                    "links": {
                        "owner": {
                            "id": "10",
                            "display_name": "Owner 10",
                            "href": "/users/10",
                            "type": "users"
                        }
                    }
                },{
                    "id": "102",
                    "created_at": "2014-04-21T09:23:12Z",
                    "updated_at": "2014-04-21T16:23:12Z",
                    "name" : "bad_flowers",
                    "display_name": "Lots of Ugly flowers",
                    "links": {
                        "owner": {
                            "id": "11",
                            "display_name": "Owner 11",
                            "type": "user_groups",
                            "href": "/user_groups/11"
                        }
                    }
                }]
            }

### List all collections [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string name of either a user or user group to filter by

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Collection Collection][]

### Create Collection [POST]
A Collection only needs a *display name* to be created. By default
name will be the underscored and downcased version of *display_name*,
and the current user will be set as the owner.

Optionally a create request may include name, a link to an
owner, and links to subjects.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "collections": {
                    "display_name": "flowers",
                    "links": {
                        "owner": {
                            "id" : "10",
                            "display_name": "Owner 10",
                            "type": "user_groups",
                            "href": "/user_groups/10"
                        }
                    }
                }
            }

+ Response 201

    [Collection][]
