{{- define "gatus.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "gatus.labels" -}}
app.kubernetes.io/name: {{ include "gatus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: infrastructure
{{- end }}

{{- define "gatus.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gatus.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
