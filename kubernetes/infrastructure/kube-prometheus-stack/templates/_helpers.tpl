{{/* Prefixed "kps-wrapper" to avoid colliding with upstream sub-chart helpers. */}}

{{- define "kps-wrapper.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "kps-wrapper.labels" -}}
app.kubernetes.io/name: {{ include "kps-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: infrastructure
{{- end }}
