terraform init

while true
do
  sleep 10
  terraform apply -auto-approve
  if [ $? -eq 0 ]
  then
    break
  fi
done

exit