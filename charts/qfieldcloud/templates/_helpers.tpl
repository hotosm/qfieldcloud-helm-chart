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
Name of the PVC shared between the workers and the QGIS jobs they spawn.
*/}}
{{- define "qfieldcloud.sharedPvcName" -}}
{{- printf "%s-shared" (include "qfieldcloud.fullname" .) }}
{{- end }}

{{/*
Name of the Secret holding the chart-managed Django secrets.
*/}}
{{- define "qfieldcloud.djangoSecretName" -}}
{{- printf "%s-django" (include "qfieldcloud.fullname" .) }}
{{- end }}

{{/*
Reuse the value already in the cluster so `helm upgrade` does not rotate keys.
*/}}
{{- define "qfieldcloud.retainedSecret" -}}
{{- $ctx := .ctx -}}
{{- $existing := lookup "v1" "Secret" $ctx.Release.Namespace (include "qfieldcloud.djangoSecretName" $ctx) -}}
{{- if and $existing $existing.data (hasKey $existing.data .key) -}}
{{- index $existing.data .key | b64dec -}}
{{- else -}}
{{- .default -}}
{{- end -}}
{{- end }}

{{/* Mirrors the subchart naming, to resolve the Service and Secret it creates. */}}
{{- define "qfieldcloud.postgresql.fullname" -}}
{{- if .Values.postgresql.fullnameOverride -}}
{{- .Values.postgresql.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "postgresql" .Values.postgresql.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end }}

{{/* The bundled subchart is authoritative when enabled; else database.* is required. */}}
{{- define "qfieldcloud.database.host" -}}
{{- if .Values.postgresql.enabled -}}
{{- include "qfieldcloud.postgresql.fullname" . -}}
{{- else -}}
{{- required "database.host is required when postgresql.enabled is false" .Values.database.host -}}
{{- end -}}
{{- end }}

{{- define "qfieldcloud.database.port" -}}
{{- if .Values.postgresql.enabled -}}
5432
{{- else -}}
{{- .Values.database.port | default 5432 -}}
{{- end -}}
{{- end }}

{{- define "qfieldcloud.database.name" -}}
{{- if .Values.postgresql.enabled -}}
{{- required "postgresql.auth.database is required when postgresql.enabled is true" .Values.postgresql.auth.database -}}
{{- else -}}
{{- required "database.name is required when postgresql.enabled is false" .Values.database.name -}}
{{- end -}}
{{- end }}

{{- define "qfieldcloud.database.user" -}}
{{- if .Values.postgresql.enabled -}}
{{- required "postgresql.auth.username is required when postgresql.enabled is true" .Values.postgresql.auth.username -}}
{{- else -}}
{{- required "database.user is required when postgresql.enabled is false" .Values.database.user -}}
{{- end -}}
{{- end }}

{{/*
Either a user-supplied Secret, the subchart's, or one this chart creates.
*/}}
{{- define "qfieldcloud.database.secretName" -}}
{{- if .Values.database.existingSecret -}}
{{- tpl .Values.database.existingSecret . -}}
{{- else if .Values.postgresql.enabled -}}
{{- if .Values.postgresql.auth.existingSecret -}}
{{- tpl .Values.postgresql.auth.existingSecret . -}}
{{- else -}}
{{- include "qfieldcloud.postgresql.fullname" . -}}
{{- end -}}
{{- else -}}
{{- printf "%s-database" (include "qfieldcloud.fullname" .) -}}
{{- end -}}
{{- end }}

{{- define "qfieldcloud.database.secretKey" -}}
{{- if .Values.database.existingSecret -}}
{{- .Values.database.existingSecretKey | default "password" -}}
{{- else if .Values.postgresql.enabled -}}
{{- $keys := .Values.postgresql.auth.secretKeys | default dict -}}
{{- if eq (.Values.postgresql.auth.username | default "") "postgres" -}}
{{- $keys.adminPasswordKey | default "postgres-password" -}}
{{- else -}}
{{- $keys.userPasswordKey | default "password" -}}
{{- end -}}
{{- else -}}
password
{{- end -}}
{{- end }}

{{/*
True when this chart is responsible for creating the database Secret itself.
*/}}
{{- define "qfieldcloud.database.createSecret" -}}
{{- if or .Values.database.existingSecret .Values.postgresql.enabled -}}
{{- else -}}
true
{{- end -}}
{{- end }}

{{- define "qfieldcloud.image" -}}
{{- printf "%s:%s" .image.repository (.image.tag | default .ctx.Chart.AppVersion | toString) -}}
{{- end }}

{{/*
Django environment shared by the web app, worker, cron jobs and migration job.
*/}}
{{- define "qfieldcloud.djangoEnv" -}}
- name: DJANGO_ALLOWED_HOSTS
  value: {{ .Values.django.settings.allowedHosts | quote }}
- name: DJANGO_SETTINGS_MODULE
  value: {{ .Values.django.settings.settingsModule | quote }}
{{- /* Both are mandatory in settings.py, read as os.environ[...]. */}}
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.djangoSecretName" . }}
      key: secret-key
- name: SALT_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.djangoSecretName" . }}
      key: salt-key
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
  value: {{ include "qfieldcloud.database.name" . | quote }}
- name: POSTGRES_USER
  value: {{ include "qfieldcloud.database.user" . | quote }}
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.database.secretName" . }}
      key: {{ include "qfieldcloud.database.secretKey" . }}
- name: POSTGRES_HOST
  value: {{ include "qfieldcloud.database.host" . | quote }}
- name: POSTGRES_PORT
  value: {{ include "qfieldcloud.database.port" . | quote }}
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
  value: {{ include "qfieldcloud.image" (dict "ctx" . "image" .Values.qgis.image) | quote }}
{{- if .Values.django.superuser.enabled }}
- name: DJANGO_SUPERUSER_USERNAME
  value: {{ required "django.superuser.username is required when django.superuser.enabled is true" .Values.django.superuser.username | quote }}
- name: DJANGO_SUPERUSER_EMAIL
  value: {{ required "django.superuser.email is required when django.superuser.enabled is true" .Values.django.superuser.email | quote }}
- name: DJANGO_SUPERUSER_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "qfieldcloud.djangoSecretName" . }}
      key: superuser-password
{{- end }}

{{- if not .Values.geodatabase.external }}
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
{{- end }}

{{- /* Run through `tpl` so values may contain template expressions. */}}
{{- range $key, $value := .Values.env }}
- name: {{ $key }}
  value: {{ tpl (toString $value) $ | quote }}
{{- end }}
{{- range $key, $value := .Values.worker.env }}
- name: {{ $key }}
  value: {{ tpl (toString $value) $ | quote }}
{{- end }}
{{- end }}
