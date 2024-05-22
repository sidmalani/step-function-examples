export AWS_DEFAULT_REGION=ap-southeast-2

mv poly_a.py main.py
zip function_a.zip main.py
version=$(aws lambda update-function-code --function-name  poly-step-function-step --publish --zip-file fileb://function_a.zip | jq -r '.Version')

aws lambda create-alias \
    --function-name poly-step-function-step \
    --description "alias for live version of function" \
    --function-version $version \
    --name v1

sleep 5

mv poly_b.py main.py
zip function_b.zip main.py
version=$(aws lambda update-function-code --function-name  poly-step-function-step --publish --zip-file fileb://function_b.zip | jq -r '.Version')

aws lambda create-alias \
    --function-name poly-step-function-step \
    --description "alias for live version of function" \
    --function-version $version \
    --name v2