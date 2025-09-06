{{- define "lib.name" -}}{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}{{- end -}}
{{- define "lib.fullname" -}}{{- $name := default .Chart.Name .Values.nameOverride -}}{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}{{- end -}}

{{- define "lib.configmap" -}}
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ include "lib.fullname" . }}-cfg
data:
  WEB_MESSAGE: {{ .Values.config.webMessage | quote }}
{{- end -}}

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

{{- define "lib.deployment" -}}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "lib.fullname" . }}
spec:
  replicas: {{ .Values.replicas | default 2 }}
  selector:
    matchLabels:
      app.kubernetes.io/name: {{ include "lib.name" . }}
  template:
    metadata:
      labels:
        app.kubernetes.io/name: {{ include "lib.name" . }}
    spec:
      {{- with .Values.imagePullSecrets }}
      imagePullSecrets:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: {{ .Values.service.port | default 8080 }}
          env:
            {{- range $k, $v := .Values.env }}
            - name: {{ $k }}
              value: "{{ $v }}"
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "lib.fullname" . }}-cfg
{{- end -}}
