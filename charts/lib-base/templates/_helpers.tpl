{{- define "lib.name" -}}{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}{{- end -}}
{{- define "lib.fullname" -}}{{- $name := default .Chart.Name .Values.nameOverride -}}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end -}}
