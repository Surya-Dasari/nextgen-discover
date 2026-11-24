{{- define "catalogueservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "catalogueservice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "catalogueservice.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "catalogueservice.labels" -}}
app.kubernetes.io/name: {{ include "catalogueservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "catalogueservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "catalogueservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "catalogueservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "catalogueservice.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
