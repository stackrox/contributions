apiVersion: v1
kind: Pod
metadata:
  name: prod-app
  labels:
    app: prod-app
spec:
  containers:
  - name: app-container
    image: gcr.io/rox-se/sample-image:getting-started
    ports:
    - containerPort: 8080
    securityContext:
      privileged: false
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
