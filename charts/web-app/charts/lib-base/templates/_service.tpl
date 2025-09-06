{{- define "lib.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "lib.fullname" . }}
spec:
  type: ClusterIP
  selector:
    app.kubernetes.io/name: {{ include "lib.name" . }}
  ports:
    - port: 80
      targetPort: {{ .Values.service.port | default 8080 }}
{{- end -}}
