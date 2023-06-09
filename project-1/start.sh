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


#-------------------------- script on backup --------------------------
# ssh ubuntu@212.162.146.228 "cd ./Infrastructure-Services-and-Operations/project-1 && ./start.sh"

# while true
# do
#   sleep 10
#   ip=$(openstack --os-cloud safespring server list -c Networks -f value --name puppetmaster | awk '{print $2}')
#   if [ $? -eq 0 ]
#   then
#     if [ -n "$ip" ] && [ ${#ip} -lt 16 ]
#     then
#       echo "ip adreess: $ip"
#       echo "ip lenght ${#ip}"
#       break
#     fi
#   fi
# done

# echo "anotther test: $ip"
# cd project-1
# terraform init
# while true
# do
#   sleep 10
#   terraform apply -auto-approve -var "puppetmaster_ip=$ip"
#   if [ $? -eq 0 ]
#   then
#     break
#   fi
# done
# echo ""
# echo "----------------------------"
# echo -e "Puppetmaster ip address: \n$ip" | tee ~/infrastructure.txt
# echo -e "Webserver ip: \n$(openstack --os-cloud safespring server list -c Networks -f value --name webserver | awk '{print $2}')" | tee -a ~/infrastructure.txt
# echo -e "Databaseserver ip: \n$(openstack --os-cloud safespring server list -c Networks -f value --name databaseserver | awk '{print $2}')" | tee -a ~/infrastructure.txt
# echo -e "Loadbalancer ip: \n$(openstack --os-cloud safespring server list -c Networks -f value --name loadbalancer | awk '{print $2}')" | tee -a ~/infrastructure.txt
# echo -e "Backup ip: \n$(openstack --os-cloud alto server list -c Networks -f value --name backup | cut -d = -f2)" | tee -a ~/infrastructure.txt