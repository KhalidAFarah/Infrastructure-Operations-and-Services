while true
do
  sleep 10
  terraform destroy -auto-approve
  if [ $? -eq 0 ]
  then
    break
  fi
done

exit