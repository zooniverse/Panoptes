# Collection preferences

```json
{
    "collection_preferences": [{
        "id": "942",
        "preferences": {
            "display": "grid"
        },
        "created_at": "2014-03-20T06:23:12Z",
        "updated_at": "2014-04-21T08:22:22Z",
        "links": {
            "user" : "30",
            "collection": "11"
        }
    }],
    "links": {
        "collection_preferences.user": {
            "href": "/user/{collection_preferences.user}",
            "type": "users"
        },
        "collection_preferences.collection": {
            "href": "/collections/{collection_preferences.collection}",
            "type": "collections"
        }
    }
}
```

A Collection Preference resource captures a user's settings for a
particular collection.

It has the following attributes:

- id
- created_at
- updated_at
- preferences

*id*, *created_at*, and *updated_at* are set the by the API. Collection
 preferences are only visible to user they belong to.

## List collection preferences

All collections add a meta attribute hash containing paging information.

### Parameters

+ page (optional, integer) ... the index of the page to retrieve default is 1
+ page_size (optional, integer) ... number of items to include on a page default is 20
+ sort (optional, string) ... field to sort by
+ user_id (optional, integer) ... user_id to see preferences for
+ collection_id (optional, integer) ... collection_id to see preferences for
+ include (optional, string) ... comma separated list of linked resources to load


## Retrieve a single CollectionPreference [GET]

### Parameters

+ include (optional, string) ... comma separated list of linked resources to load


## Edit a CollectionPreference [PUT]

```http
PUT /api/collection_preferences/123 HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collection_preferences": {
        "preferences": {
            "receive_updates": false,
        }
    }
}
```

Only the owning user may edit a Collection Preference resource. The preferences field may be edited. Editing the preferences field requires a full representation of the preferences object to be sent.

## Create a CollectionPreference [POST]

```http
POST /api/collection_preferences HTTP/1.1
Accept: application/vnd.api+json; version=1
Content-Type: application/json

{
    "collection_preferences": {
        "preferences": {
            "display": "grid"
        },
        "links": {
            "collection": "1"
        }
    }
}
```

Creating a Collection Preference requires only a link to a collection. Optionally an object of settings for preferences may be included.

Since a user can only create, read, or modify their own preferences the currently logged in user is always set as the linked user on creation.

