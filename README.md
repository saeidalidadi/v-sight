
## Add flusher view to views

Go to views tab and click on `Add View`

* Design Document Name:

```
_design/dev_flusher 
```

* View Name:

```
get_all
```

* Click on edit and add bellow function to map:

``
function(doc) {emit(null, null)}
```
