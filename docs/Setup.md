# Setup

Initate the module using the following code snippet

```
var app = Elm.Main.init({
  flags: flag
});
```

were `flag` is a JSON object with the following structure

```
{ user : String
, currentTime : Int
, initialSeed : Float
}
```

* `currentTime` is given in unix time.
* `initialSeed` needs to be a random value between `0` and `1`.

## Send Data

You can send data using

```
app.ports.toElm.send(data)
```

where `data` is a JSON object with the following structure

```
{ page : String
, action : String
, id : Nullable String
, content : Nullable String
}
```

## Recieve Data

Subscribe to data through

```
app.ports.fromElm.subscribe(function(data){
  //Add your code here
});
```

where `data` is a JSON object with the following structure

```
{ error : Nullable ..
, todo : Nullable ..
, secrets : Nullable ..
}
```

Note that only one field is **NOT** `Null`.