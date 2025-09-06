{{- define "lib.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "lib.fullname" . }}-cfg
data:
  WEB_MESSAGE: {{ .Values.config.webMessage | quote }}
{{- end -}}
