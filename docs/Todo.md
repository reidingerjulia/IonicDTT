# Todo Module

## Commands

### insert

```
{ page : "todo"
, action : "insert"
, id : null
, message : String
}
```

Inserts a new entry in the todo list.

### sync

```
{ page : "todo"
, action : "sync"
, id : null
, message : null
}
```

Manually requests a synchronization with the database.

### delete

```
{ page : "todo"
, action : "delete"
, id : String
, message : null
}
```

Deletes an entry.

Will cause an error if the entry was not created by the user.

### update

```
{ page : "todo"
, action : "update"
, id : String
, message : String
}
```

Updates the message of an entry.

Will cause an error if the entry was not created by the user.

## Subscriptions

```
{ todo :
  [ { id : Id
    , user : String
    , message : String
    , lastUpdated : Posix
    }
  , ..
  ]
, ..
}
```

* `lastUpdated` is given in unix time.

Subscripes to a regular updating list of entries.
The list will update every minute as well as after every method call.