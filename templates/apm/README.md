Run

```bash
oc create serviceaccount apm-server -n monitoring
oc adm policy add-scc-to-user anyuid -z apm-server -n monitoring
oc apply -f .
oc get pod -o go-template='{{range .items}}{{$scc := index .metadata.annotations "openshift.io/scc"}}{{.metadata.name}}{{" scc:"}}{{range .spec.containers}}{{$scc}}{{" "}}{{"\n"}}{{end}}{{end}}' -n monitoring
```

