{{- define "notificationservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "notificationservice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name (include "notificationservice.name" .) | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "notificationservice.labels" -}}
app.kubernetes.io/name: {{ include "notificationservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end }}

{{- define "notificationservice.selectorLabels" -}}
app.kubernetes.io/name: {{ include "notificationservice.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "notificationservice.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "notificationservice.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
