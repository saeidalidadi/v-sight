

### Installation
```
sudo npm install v-sight
```

### Adding flusher view to views in `Couchbase`.
1.  Go to **views** tab and click on `Create Development View`
and insert bellows in fields:

```
Design Document Name:

_design/dev_flusher 

View Name:
get_all
```

2.  Click on `edit` and add bellow function to **map**:

```
function(doc) {emit(null, null)}
```
### Examples and usage
To find how to use please look at `examples`

