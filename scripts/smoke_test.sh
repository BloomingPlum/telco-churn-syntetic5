#!/usr/bin/env bash
# End-to-end check of the running stack. Run from the repo root.
set -euo pipefail
API=${API:-http://localhost:8000}

echo "== Containers";  docker compose ps -a
echo; echo "== Images (multi-stage sizes)"
docker images --format 'table {{.Repository}}:{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|telco-churn|churn-api'

echo; echo "== One-shot jobs exit codes"
for s in generator trainer; do
  printf '%-10s exit=%s\n' "$s" "$(docker inspect -f '{{.State.ExitCode}}' "$(docker compose ps -aq $s)")"
done

echo; echo "== API health";  curl -fsS "$API/health"; echo
echo; echo "== Prediction"
curl -fsS -X POST "$API/predict" -H "Content-Type: application/json" -d '{
  "tenure": 12, "MonthlyCharges": 65.5, "TotalCharges": 786.0, "gender": "Male",
  "SeniorCitizen": 0, "Partner": "Yes", "Dependents": "No", "PhoneService": "Yes",
  "MultipleLines": "No", "InternetService": "Fiber optic", "OnlineSecurity": "No",
  "OnlineBackup": "No", "DeviceProtection": "No", "TechSupport": "No",
  "StreamingTV": "No", "StreamingMovies": "No", "Contract": "Month-to-month",
  "PaperlessBilling": "Yes", "PaymentMethod": "Electronic check"}'; echo

echo; echo "== Invalid input must return 422"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$API/predict" -H "Content-Type: application/json" -d '{"tenure":"abc"}')
echo "status=$code"; [ "$code" = "422" ]

echo; echo "== MLflow"; curl -fsS http://localhost:5000/health; echo
echo; echo "ALL CHECKS PASSED"
