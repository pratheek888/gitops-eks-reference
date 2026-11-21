{{/* Chart name */}}
{{- define "service.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Fully qualified name: <release>-<alias> */}}
{{- define "service.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{- define "service.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "service.selectorLabels" -}}
app.kubernetes.io/name: {{ include "service.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "service.labels" -}}
helm.sh/chart: {{ include "service.chart" . }}
{{ include "service.selectorLabels" . }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: platform-app
{{- end }}

{{- define "service.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- include "service.fullname" . }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}

{{/* Name of the ingress Argo Rollouts manages for traffic shaping */}}
{{- define "service.ingressName" -}}
{{- include "service.fullname" . }}
{{- end }}
