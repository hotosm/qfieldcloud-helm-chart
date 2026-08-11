{{/*
Expand the name of the chart.
*/}}
{{- define "qfieldcloud.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "qfieldcloud.fullname" -}}
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
{{- define "qfieldcloud.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qfieldcloud.labels" -}}
helm.sh/chart: {{ include "qfieldcloud.chart" . }}
{{ include "qfieldcloud.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qfieldcloud.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qfieldcloud.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "qfieldcloud.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "qfieldcloud.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }} 
{{/*
Common Django application environment variables.
Used by the web application and migration job.
*/}}
{{- define "qfieldcloud.djangoEnv" -}}
- name: DJANGO_ALLOWED_HOSTS
  value: {{ .Values.django.settings.allowedHosts | quote }}

- name: DJANGO_SETTINGS_MODULE
  value: {{ .Values.django.settings.settingsModule | quote }}

- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.fullname" . }}-django
      key: secret-key

- name: DEBUG
  value: {{ .Values.django.settings.debug | quote }}

- name: ENVIRONMENT
  value: {{ .Values.django.settings.environment | quote }}

- name: SENTRY_DSN
  value: {{ .Values.django.sentry.dsn | quote }}

- name: SENTRY_RELEASE
  value: {{ .Values.django.sentry.release | quote }}

- name: SENTRY_ENVIRONMENT
  value: {{ .Values.django.settings.environment | quote }}

- name: SENTRY_SAMPLE_RATE
  value: {{ .Values.django.sentry.sampleRate | quote }}

- name: POSTGRES_DB
  value: {{ .Values.database.name | quote }}

- name: POSTGRES_USER
  value: {{ .Values.database.user | quote }}

- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.fullname" . }}-postgresql
      key: password

- name: POSTGRES_HOST
  value: {{ .Values.database.host | quote }}

- name: POSTGRES_PORT
  value: {{ .Values.database.port | quote }}

- name: POSTGRES_SSLMODE
  value: {{ .Values.database.sslMode | quote }}

- name: MINIO_API_PORT
  value: {{ .Values.django.storage.minioApiPort | quote }}

- name: MINIO_BROWSER_PORT
  value: {{ .Values.django.storage.minioBrowserPort | quote }}

- name: STORAGES
  value: {{ .Values.django.storage.storagesConfig | toJson | quote }}

- name: STORAGES_PROJECT_DEFAULT_STORAGE
  value: {{ .Values.django.storage.projectDefaultStorage | quote }}

- name: GEODB_HOST
  value: {{ .Values.geodatabase.host | quote }}

- name: GEODB_PORT
  value: {{ .Values.geodatabase.port | quote }}

- name: GEODB_USER
  value: {{ .Values.geodatabase.user | quote }}

- name: GEODB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.fullname" . }}-geodatabase
      key: password

- name: GEODB_DB
  value: {{ .Values.geodatabase.name | quote }}

- name: ACCOUNT_EMAIL_VERIFICATION
  value: {{ .Values.django.settings.accountEmailVerification | quote }}

- name: QFIELDCLOUD_SUBSCRIPTION_MODEL
  value: {{ .Values.django.settings.subscriptionModel | quote }}

- name: QFIELDCLOUD_AUTH_TOKEN_EXPIRATION_HOURS
  value: {{ .Values.django.settings.authTokenExpirationHours | quote }}

- name: QFIELDCLOUD_USE_I18N
  value: {{ .Values.django.settings.useI18n | quote }}

- name: QFIELDCLOUD_DEFAULT_LANGUAGE
  value: {{ .Values.django.settings.defaultLanguage | quote }}

- name: QFIELDCLOUD_DEFAULT_TIME_ZONE
  value: {{ .Values.django.settings.defaultTimeZone | quote }}

- name: DJANGO_USE_X_FORWARDED_HOST
  value: {{ .Values.django.settings.useXForwardedHost | quote }}

- name: QFIELDCLOUD_QGIS_IMAGE_NAME
  value: "{{ .Values.qgis.image.repository }}:{{ .Values.qgis.image.tag }}"

{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}

{{- range $key, $value := .Values.worker.env }}
- name: {{ $key }}
  value: {{ $value | quote }}
{{- end }}

{{- end }}