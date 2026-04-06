{{/*
Expand the name of the chart.
*/}}
{{- define "kube-prometheus-stack.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource in this wrapper chart.
*/}}
{{- define "kube-prometheus-stack.labels" -}}
app.kubernetes.io/name: {{ include "kube-prometheus-stack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: infrastructure
{{- end }}

{{/*
Selector labels for Deployments / Services in this wrapper chart.
*/}}
{{- define "kube-prometheus-stack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-prometheus-stack.name" . }}
{{- end }}

