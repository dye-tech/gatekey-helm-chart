{{/*
Expand the name of the chart.
*/}}
{{- define "gatekey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "gatekey.fullname" -}}
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

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "gatekey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "gatekey.labels" -}}
helm.sh/chart: {{ include "gatekey.chart" . }}
{{ include "gatekey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: gatekey
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "gatekey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "gatekey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Server labels
*/}}
{{- define "gatekey.server.labels" -}}
{{ include "gatekey.labels" . }}
app.kubernetes.io/component: server
{{- end }}

{{- define "gatekey.server.selectorLabels" -}}
{{ include "gatekey.selectorLabels" . }}
app.kubernetes.io/component: server
{{- end }}

{{/*
Web labels
*/}}
{{- define "gatekey.web.labels" -}}
{{ include "gatekey.labels" . }}
app.kubernetes.io/component: web
{{- end }}

{{- define "gatekey.web.selectorLabels" -}}
{{ include "gatekey.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end }}

{{/*
PostgreSQL labels
*/}}
{{- define "gatekey.postgresql.labels" -}}
{{ include "gatekey.labels" . }}
app.kubernetes.io/component: postgresql
{{- end }}

{{- define "gatekey.postgresql.selectorLabels" -}}
{{ include "gatekey.selectorLabels" . }}
app.kubernetes.io/component: postgresql
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "gatekey.serviceAccountName" -}}
{{- if .Values.server.serviceAccount.create }}
{{- default (printf "%s-server" (include "gatekey.fullname" .)) .Values.server.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.server.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Return the proper image name
*/}}
{{- define "gatekey.server.image" -}}
{{- $registryName := .Values.global.imageRegistry | default "" -}}
{{- $repositoryName := .Values.server.image.repository -}}
{{- $tag := .Values.server.image.tag | default .Chart.AppVersion -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

{{- define "gatekey.web.image" -}}
{{- $registryName := .Values.global.imageRegistry | default "" -}}
{{- $repositoryName := .Values.web.image.repository -}}
{{- $tag := .Values.web.image.tag | default .Chart.AppVersion -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

{{- define "gatekey.postgresql.image" -}}
{{- $registryName := .Values.global.imageRegistry | default "" -}}
{{- $repositoryName := .Values.postgresql.image.repository -}}
{{- $tag := .Values.postgresql.image.tag -}}
{{- if $registryName }}
{{- printf "%s/%s:%s" $registryName $repositoryName $tag -}}
{{- else }}
{{- printf "%s:%s" $repositoryName $tag -}}
{{- end }}
{{- end }}

{{/*
Return the database URL
*/}}
{{- define "gatekey.databaseUrl" -}}
{{- if .Values.secrets.databaseUrl }}
{{- .Values.secrets.databaseUrl }}
{{- else if .Values.postgresql.enabled }}
{{- $host := printf "%s-postgresql" (include "gatekey.fullname" .) }}
{{- $port := "5432" }}
{{- $user := .Values.postgresql.auth.username }}
{{- $db := .Values.postgresql.auth.database }}
{{- printf "postgres://%s:$(POSTGRES_PASSWORD)@%s:%s/%s?sslmode=disable" $user $host $port $db }}
{{- else }}
{{- $host := .Values.externalDatabase.host }}
{{- $port := .Values.externalDatabase.port | toString }}
{{- $user := .Values.externalDatabase.username }}
{{- $db := .Values.externalDatabase.database }}
{{- printf "postgres://%s:$(POSTGRES_PASSWORD)@%s:%s/%s?sslmode=disable" $user $host $port $db }}
{{- end }}
{{- end }}

{{/*
Return the secrets name
*/}}
{{- define "gatekey.secretsName" -}}
{{- if .Values.secrets.existingSecret }}
{{- .Values.secrets.existingSecret }}
{{- else }}
{{- printf "%s-secrets" (include "gatekey.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Return the postgresql secrets name
*/}}
{{- define "gatekey.postgresql.secretsName" -}}
{{- if .Values.postgresql.auth.existingSecret }}
{{- .Values.postgresql.auth.existingSecret }}
{{- else }}
{{- printf "%s-postgresql-secrets" (include "gatekey.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Generate random password
*/}}
{{- define "gatekey.randomPassword" -}}
{{- randAlphaNum 32 -}}
{{- end }}
