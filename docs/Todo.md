# Todo Module

## Commands

### insert

```
{ page : "todo"
, action : "insert"
, id : null
, content : String
}
```

Inserts a new entry in the todo list.

### sync

```
{ page : "todo"
, action : "sync"
, id : null
, content : null
}
```

Manually requests a synchronization with the database.

### delete

```
{ page : "todo"
, action : "delete"
, id : String
, content : null
}
```

Deletes an entry.

Will cause an error if the entry was not created by the user.

### update

```
{ page : "todo"
, action : "update"
, id : String
, content : String
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
The list will update after every method call.