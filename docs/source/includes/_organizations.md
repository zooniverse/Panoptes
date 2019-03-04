# Group Organizations
Resources related to _Panoptes Organizations_.

## Organization [/organizations/{id}{?include,display_name}]
An Organization is a collection of projects that are related by dicipline, research group

It has the following attributes:

Organization(id: integer, display_name: string, slug: string, primary_language: string, listed_at: datetime, activated_state: integer, created_at: datetime, updated_at: datetime, urls: jsonb, listed: boolean, categories: string)

- id
- created_at
- updated_at
- display_name
- title
- description
- introduction
- urls
- available_languages
- listed
- avatar
- background

+ Parameters
  + id (required, integer) ... integer id of the resource to retrieve
  + display_name (string) ... name filter
  + listed (boolean) ... publicly visible

+ Model

    + Body

            {
              "organizations": [
                {
                  "id": "99",
                  "display_name": "United Federation of Projects",
                  "description": "Surveying planets and nebulae, mostly",
                  "introduction": "",
                  "title": "United Federation of Projects",
                  "href": "/organizations/18",
                  "primary_language": "en",
                  "listed_at": null,
                  "listed": false,
                  "slug": "user/slug",
                  "urls": [],
                  "categories": [],
                  "announcement": "",
                  "links": {
                    "organization_contents": [
                      "99"
                    ],
                    "organization_roles": [
                      "153808"
                    ],
                    "owner": {
                      "id": "9999",
                      "display_name": "Jean-Luc Picard",
                      "type": "users",
                      "href": "/users/9999"
                    },
                    "avatar": {
                      "href": "/organizations/99/avatar",
                      "type": "avatars"
                    },
                    "background": {
                      "href": "/organizations/99/background",
                      "type": "backgrounds"
                    },
                    "attached_images": {
                      "href": "/organizations/99/attached_images",
                      "type": "attached_images"
                    }
                  }
                }
              ],
              "links": {
                "organizations.attached_images": {
                  "href": "/organizations/{organizations.id}/attached_images",
                  "type": "media"
                },
                "organizations.organization_contents": {
                  "href": "/organization_contents?organization_id={organizations.id}",
                  "type": "organization_contents"
                },
                "organizations.organization_roles": {
                  "href": "/organization_roles?organization_id={organizations.id}",
                  "type": "organization_roles"
                },
                "organizations.projects": {
                  "href": "/projects?organization_id={organizations.id}",
                  "type": "projects"
                },
                "organizations.pages": {
                  "href": "/organizations/{organizations.id}/pages",
                  "type": "organization_pages"
                },
                "organizations.owner": {
                  "href": "/{organizations.owner.href}",
                  "type": "owners"
                },
                "organizations.avatar": {
                  "href": "/organizations/{organizations.id}/avatar",
                  "type": "media"
                },
                "organizations.background": {
                  "href": "/organizations/{organizations.id}/background",
                  "type": "media"
                }
              },
              "meta": {
                "organizations": {
                  "page": 1,
                  "page_size": 20,
                  "count": 1,
                  "include": [],
                  "page_count": 1,
                  "previous_page": null,
                  "next_page": null,
                  "first_href": "/organizations?id=18",
                  "previous_href": null,
                  "next_href": null,
                  "last_href": "/organizations?id=18"
                }
              }
            }

### Retrieve a single Organization [GET]
+ Parameters
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Organization][]

### Edit a single Organization[PUT]
A User must be the owner of a Organization or have update
permissions to edit the resource.

Setting has may links through a PUT, while supported, is not
recommended. Instead, use the link endpoints explained below.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "organizations": {
                    "display_name": "Klingon Empire",
                    "links": {
                        "workflows": ["1"],
                        "subject_sets": ["10"]
                    }
                }
            }

+ Response 200

    [Organization][]

### Destroy a single Organization [DELETE]
A user may destroy a Organization they own or have destroy permissions for.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Organization Create Links [/Organization/{id}/links/{link_type}]

### Add a Link [POST]
The body key must match the link_type parameter. Po

+ Parameters
  + id (required, integer) - the id of the project to add
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `projects`

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "projects": ["1", "2"]
            }

+ Response 200

    [Organization][]

## Organization Destroy Links [/Organization/{id}/links/{link_type}/{link_ids}]
The recommended way to destroy Organization links.

### Destroy a Link [DELETE]
Will destroy the comma separated list of link ids for the given link
type. For Organization, only project links can be
destroyed in this manner. The linked object will be destroyed with
this action.

+ Parameters
  + id (required, integer) ... the id of the project to modify
  + link_type (required, string)
    the name of the link to edit
        + Members
            + `projects`
  + link_ids (required, string) ... comma separated list of ids to destroy

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 204

## Organization Collection [/projects{?page,page_size,sort,owner,include}]
A collection of _Panotpes Organization_ resources.

All collections add a *meta* attribute hash containing
paging information.

Organizations are returned as an array under the _projects_ key.

+ Model

    A JSON API formatted representation of a collection of Organizations.

    + Body

            {
              "organizations": [
                {
                  "id": "5",
                  "display_name": "United Federation of Projects",
                  "description": "Every project in the galaxy",
                  "introduction": "Hello and welcome to the UFP",
                  "title": "United Federation of Projects",
                  "href": "/organizations/5",
                  "primary_language": "en",
                  "listed_at": null,
                  "listed": true,
                  "slug": "user/slug",
                  "urls": [
                    {
                      "url": "https://twitter.com/UFP",
                      "path": "United Federation of Twitter",
                      "site": "twitter.com/",
                      "label": ""
                    }
                  ],
                  "categories": [],
                  "announcement": "Oh Gosh!",
                  "links": {
                    "organization_contents": [
                      "5"
                    ],
                    "organization_roles": [
                      "9999"
                    ],
                    "projects": [
                      "1",
                      "2"
                    ],
                    "owner": {
                      "id": "811067",
                      "display_name": "meredithspalmer",
                      "type": "users",
                      "href": "/users/811067"
                    },
                    "pages": [
                      "5"
                    ],
                    "avatar": {
                      "href": "/organizations/5/avatar",
                      "type": "avatars",
                      "id": "27687087"
                    },
                    "background": {
                      "href": "/organizations/5/background",
                      "type": "backgrounds",
                      "id": "30335947"
                    },
                    "attached_images": {
                      "href": "/organizations/5/attached_images",
                      "type": "attached_images"
                    }
                  }
                }
              ],
              "links": {
                "organizations.attached_images": {
                  "href": "/organizations/{organizations.id}/attached_images",
                  "type": "media"
                },
                "organizations.organization_contents": {
                  "href": "/organization_contents?organization_id={organizations.id}",
                  "type": "organization_contents"
                },
                "organizations.organization_roles": {
                  "href": "/organization_roles?organization_id={organizations.id}",
                  "type": "organization_roles"
                },
                "organizations.projects": {
                  "href": "/projects?organization_id={organizations.id}",
                  "type": "projects"
                },
                "organizations.pages": {
                  "href": "/organizations/{organizations.id}/pages",
                  "type": "organization_pages"
                },
                "organizations.owner": {
                  "href": "/{organizations.owner.href}",
                  "type": "owners"
                },
                "organizations.avatar": {
                  "href": "/organizations/{organizations.id}/avatar",
                  "type": "media"
                },
                "organizations.background": {
                  "href": "/organizations/{organizations.id}/background",
                  "type": "media"
                }
              },
              "meta": {
                "organizations": {
                  "page": 1,
                  "page_size": 20,
                  "count": 1,
                  "include": [],
                  "page_count": 1,
                  "previous_page": null,
                  "next_page": null,
                  "first_href": "/organizations",
                  "previous_href": null,
                  "next_href": null,
                  "last_href": "/organizations"
                }
              }
            }

### List All Organizations [GET]
+ Parameters
  + page (optional, integer) ... the index of the page to retrieve default is 1
  + page_size (optional, integer) ... number of items to include on a page default is 20
  + sort (optional, string) ... field to sort by
  + owner (optional, string) ... string owner name of either a user or a user group to filter by.
  + include (optional, string) ... comma separated list of linked resources to include in the response

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

+ Response 200

    [Organization Collection][]


### Create a Organization [POST]
Requires at least a *display_name*, *description* and primary_language*.

+ Request

    + Headers

            Accept: application/vnd.api+json; version=1
            Content-Type: application/json

    + Body

            {
                "Organizations": {
                    "display_name": "United Federation of Projects",
                    "description": "Lots o' Projects",
                    "primary_language": "en-us",
                    "links": {
                        "projects": ["1", "2"]
                    }
                }
            }

+ Response 201

    [Organization][]
