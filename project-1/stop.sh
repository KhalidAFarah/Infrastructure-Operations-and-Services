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

#-------------------------- script on backup --------------------------
# # First destroying the backup server, this requires the puppetmaster public ip as it is dependant on it
# cd project-1
# while true
# do
#   terraform destroy -auto-approve -var "puppetmaster_ip=''"
#   if [ $? -eq 0 ]
#   then
#     break
#   fi
#   sleep 10
# done

# # Finally destroying the puppetmaster and the rest of the nodes created on safespring regarding alternative picked
# ssh ubuntu@212.162.146.228 "cd ./Infrastructure-Services-and-Operations/project-1 && ./stop.sh"