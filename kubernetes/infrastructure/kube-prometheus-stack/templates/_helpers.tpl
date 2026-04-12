{{/*
Wrapper-chart helpers — prefixed "kps-wrapper" to avoid colliding with the
upstream kube-prometheus-stack sub-chart's own "kube-prometheus-stack.*" helpers.
Helm named templates are global: if the parent chart redefines a template that
the sub-chart also defines, the parent's version wins — overriding the sub-chart's
selector/label helpers and producing invalid Deployment specs (selector ≠ template labels).
*/}}

{{/*
Wrapper chart name (used only by ExternalSecret metadata).
*/}}
{{- define "kps-wrapper.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels for resources owned by this wrapper chart only.
Do NOT use these in sub-chart template overrides.
*/}}
{{- define "kps-wrapper.labels" -}}
app.kubernetes.io/name: {{ include "kps-wrapper.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: infrastructure
{{- end }}

