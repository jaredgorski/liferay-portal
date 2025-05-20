{{/*
Expand the name of the chart.
*/}}
{{- define "liferay-cx.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "liferay-cx.fullname" -}}
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
{{- define "liferay-cx.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
App name
*/}}
{{- define "liferay-cx.appname" -}}
{{- default .Release.Name .Values.nameOverride .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "liferay-cx.labels" -}}
helm.sh/chart: {{ include "liferay-cx.chart" . }}
{{ include "liferay-cx.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- if .Values.cxConfig.virtualInstanceId }}
dxp.lxc.liferay.com/virtualInstanceId: {{ .Values.cxConfig.virtualInstanceId }}
{{- end }}
ext.lxc.liferay.com/serviceId: {{ include "liferay-cx.appname" . }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "liferay-cx.selectorLabels" -}}
app: {{ include "liferay-cx.appname" . }}
app.kubernetes.io/name: {{ include "liferay-cx.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Ext Provision ConfigMap name
*/}}
{{- define "liferay-cx.ext-provision-configmap.name" -}}
{{- printf "%s-%s-lxc-ext-provision-metadata" .Release.Name .Values.cxConfig.virtualInstanceId | trunc 63 }}
{{- end }}

{{/*
Ext Provision ConfigMap labels
*/}}
{{- define "liferay-cx.ext-provision-configmap.labels" -}}
{{ include "liferay-cx.labels" . }}
lxc.liferay.com/metadataType: "ext-provision"
{{- end }}

{{/*
Ext Provision ConfigMap annotations
*/}}
{{- define "liferay-cx.ext-provision-configmap.annotations" -}}
ext.lxc.liferay.com/mainDomain: {{ .Values.cxConfig.domain }}
ext.lxc.liferay.com/domains: {{ .Values.cxConfig.domain }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "liferay-cx.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "liferay-cx.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
