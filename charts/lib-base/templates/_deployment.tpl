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
      containers:
        - name: app
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: {{ .Values.service.port | default 8080 }}
          env:
            {{- range $k, $v in .Values.env }}
            - name: {{ $k }}
              value: "{{ $v }}"
            {{- end }}
          envFrom:
            - configMapRef:
                name: {{ include "lib.fullname" . }}-cfg
{{- end -}}
