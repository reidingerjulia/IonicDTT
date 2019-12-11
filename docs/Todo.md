# Todo Module

Initate the module using the following code snippet

```
var app = Elm.DTT.init({
  node: document.getElementById('elm'),
  flags:
  {
    user: "Julia",
    currentTime: Date.now(),
    initialSeed: Math.random()
  }
});
```

#### Json Structure
```
{ user : String
, currentTime : Int
, initialSeed : Float
}
```

**Note:**
`initialSeed` needs to be a random value between `0` and `1`.

## Methods

### insertTodoEntry

Inserts a new entry in the todo list.

#### Json Structure

```
{ message : String }
```

#### Example

```
app.ports.insertTodoEntry.send({message:"Hello World"});
```

### syncTodoEntry

Manually requests a synchronization with the database.

#### Example

```
app.ports.syncTodoEntry.send();
```

### deleteTodoEntry

Deletes an Entry.

Will cause an error if the entry was not created by the user.

#### Json Structure

```
{ id : String }
```

#### Example

```
app.ports.deleteTodoEntry.send({id:"729598701"});
```

### updateTodoEntry

Updates the message of an Entry.

Will cause an error if the entry was not created by the user.

#### Json Structure

```
{ id : String
, message : String
}
```

#### Example

```
app.ports.updateTodoEntry.send({id:"729598701",message:"I love you"});
```

## Subscriptions

### errorOccured

Subscripes to any error that occurs within the methods.

#### Example

```
app.ports.errorOccured.subscribe(function(string){console.log(string)});
```

### gotTodoList

Subscripes to a regular updating list of entries.
The list will update every minute as well as after every method call.

#### Json

```
[ { id : Id
  , user : String
  , message : String
  , lastUpdated : Int
  }
, ..
]
```

**Note:**
`lastUpdated` is given in unix time.

#### Example

```
app.ports.gotTodoList.subscribe(function(string){console.log(string)});
```