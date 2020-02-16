# Error Module

```
{ error :
  { errorType : String
  , content : String
  }
, ..
}
```

The following Error Types can occur

## Elm Internal Errors

```
{ errorType = "bad-url"
, content = string
}

{ errorType = "timeout"
, content = ""
}

{ errorType = "network-error"
, content = ""
}

{ errorType = "bad-status"
, content = String
}

{ errorType = "bad-body"
, content = String
}

{ errorType = "wrong-input-format"
, content = String
}
```

## Interop Errors

```
{ errorType = "parsingError"
, content = string
}
```

The JSON object has the correct form, but a string contains an invalid keyword.

## Todo Specific

```
{ errorType = "no-permission"
, content = ""
}
```

You do not have the permission to perform a action

## Secret Specific

```
{ errorType = "is-matched"
, content = ""
}
```

The secret has been matched and can therefore not be deleted any longer.