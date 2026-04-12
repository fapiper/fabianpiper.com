{{/*
Wrapper-chart helpers — prefixed "loki-wrapper" to avoid colliding with the
inner loki sub-chart's own "loki.*" helpers inside grafana/loki-stack.
Helm named templates are global: if the parent chart redefines a template that
a sub-chart also defines, the parent's version wins — potentially breaking
the sub-chart's selector/label logic.

This wrapper adds no extra Kubernetes resources (templates/ contains only this file),
so these helpers are intentionally unused stubs kept for potential future resources.
*/}}

{{/*
Wrapper chart name.
*/}}
{{- define "loki-wrapper.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for resources owned by this wrapper chart only.
Do NOT use these on sub-chart resource overrides.
*/}}
{{- define "loki-wrapper.labels" -}}
app.kubernetes.io/name: {{ include "loki-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: infrastructure
{{- end }}

{{/*
Selector labels for resources owned by this wrapper chart only.
*/}}
{{- define "loki-wrapper.selectorLabels" -}}
app.kubernetes.io/name: {{ include "loki-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
