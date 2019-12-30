# Secrets Module

## Commands

### insert

```
{ page : "secrets"
, action : "insert"
, id : null
, content : String
}
```

Inserts a new secret. If both users have inserted the same secret, it will
be revealed. Once a secret is revealed it can not be deleted.

### delete

```
{ page : "secrets"
, action : "delete"
, id : null
, content : String
}
```

Deletes a secret that has not yet been matched.

### sync

```
{ page : "secrets"
, action : "sync"
, id : null
, content : null
}
```

Manually requests a synchronization with the database.

## Subscriptions

```
{ secrets :
  [ { hash : String
    , user : String
    , raw : Nullable String
    }
  , ..
  ]
, ..
}
```

If both users have inserted the same secret, then its content will be revealed under
then `raw` field.