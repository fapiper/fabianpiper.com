{{- define "www.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "www.labels" -}}
app.kubernetes.io/name: {{ include "www.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: portfolio
{{- end }}

{{- define "www.selectorLabels" -}}
app.kubernetes.io/name: {{ include "www.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "www.image" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end }}
