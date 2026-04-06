{{/*
Expand the name of the chart.
*/}}
{{- define "www.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels applied to every resource.
*/}}
{{- define "www.labels" -}}
app.kubernetes.io/name: {{ include "www.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/part-of: portfolio
{{- end }}

{{/*
Selector labels – used by Deployment.spec.selector and Service.spec.selector.
Kept minimal (name + instance) so the selector is stable across upgrades.
*/}}
{{- define "www.selectorLabels" -}}
app.kubernetes.io/name: {{ include "www.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Resolve the final container image reference.
When image.digest is set (populated by ArgoCD Image Updater) the reference
becomes <repository>@<digest> so the pod is pinned to an immutable digest.
Otherwise it falls back to <repository>:<tag>.
*/}}
{{- define "www.image" -}}
{{- if .Values.image.digest -}}
{{ .Values.image.repository }}@{{ .Values.image.digest }}
{{- else -}}
{{ .Values.image.repository }}:{{ .Values.image.tag }}
{{- end -}}
{{- end }}

