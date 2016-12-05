#!/bin/bash

##
## we check if the parameters have been transmitted or not 
## if not, return syntax usage
##
key_file="/home/$USER/.ssh/id_rsa"
ansible_hosts_file="ansible_hosts_file"
systems_hosts_file="systems_hosts_file"

check_parameters() {
   if [ -z $1 ]; then
      printf "Syntax: ./setup_systems.sh <setup or ansible or all>\n  - setup: setup the ssh keys, transfer keys , update sudoers and install git and ansible\n - ansible: deploys the ansible playbook to setup the systems\n - all: will do setup and then ansible\n"
      exit
   fi
   if [ ${1,,} == "setup" ]; then 
      return 1
   elif [ ${1,,} == "ansible" ]; then
      return 2
   elif [ ${1,,} == "all" ]; then
      return 3
   else
      printf "Syntax: ./setup_systems.sh <setup or ansible or all>\n - setup: setup the ssh keys, transfer keys , update sudoers and install git and ansible\n - ansible: deploys the ansible playbook to setup the systems\n - all: will do setup and then ansible\n"
      exit
   fi
}

##
## Check the hosts files (ansible and systems) to see if they exist. Then check that at least a system is defined into ansible_hosts_file
##

check_hosts_file() {
   tmp=0

   if [ -f $ansible_hosts_file ]; then
      while read -r line
      do
         name="$line"
         if [[ ! $name =~ ^'#' ]] && [[ ! $name == '' ]] && [[ ! $name =~ "[nodes]" ]]; then
            tmp=1
         fi 
      done < "$ansible_hosts_file"
      if [ $tmp -eq 0 ]; then
         printf "no system specified in %s. Exiting\n" $ansible_hosts_file
         exit
      fi
   else
      printf "couldn't find %s. Exiting...\n" $ansible_hosts_file
      exit
   fi
   if [ ! -f $systems_hosts_file ]; then
      printf "couldn't find %s. Exiting...\n" $systems_hosts_file
      exit
   fi
}

##
## Check whether the user already has a key in .ssh/ (id_rsa)
##

check_id_rsa_exists() {
   if [ -f $key_file ]; then
      printf "found %s, nothing to do here\n" $key_file
   else
      printf "no %s file found, create ssh key with ssh-keygen\n" $key_file
      ssh-keygen
   fi
}

##
## use ssh-copy-id on all systems specified in the hosts_file
##

transfer_public_key() {
   while read -r line
   do
      name="$line"
      if [[ ! $name =~ ^'#' ]] && [[ ! $name == '' ]] && [[ ! $name =~ "[nodes]" ]]; then
         printf "copying key to %s" $name
         ssh-copy-id $USER@$name
      fi
   done < "$ansible_hosts_file"
}

add_user_sudoer_nopasswd() {
   while read -r line
      do
         name="$line"
         if [[ ! $name =~ ^'#' ]] && [[ ! $name == '' ]] && [[ ! $name =~ "[nodes]" ]]; then
            printf "updating sudoer file on %s so that %s doesn't need password prompt with sudo commands\n" $name $USER
            ssh -T $name 'sudo -S sh -c "echo \"$USER ALL=(ALL:ALL) NOPASSWD: ALL\" >> /etc/sudoers"'
         fi
   done < "$ansible_hosts_file"
}

update_upgrade_repos() {
   sudo apt-get update
   sudo apt-get install -y software-properties-common
   sudo apt-add-repository ppa:ansible/ansible -y
   sudo apt-get update
}

install_setup_ansible() {
   sudo apt-get install -y ansible
   printf "setting up ansible...\n"
   printf "copying %s to /etc/ansible/hosts" $hosts_file
   
   sudo cp $ansible_hosts_file /etc/ansible/hosts
   sudo sed -i s/#inventory/inventory/ /etc/ansible/ansible.cfg   
   sudo sed -i s/#become_user/become_user/ /etc/ansible/ansible.cfg
   sudo sed -i s/#host_key_checking/host_key_checking/ /etc/ansible/ansible.cfg 
   
}

##
## The main function for the setup argument
## 1 - we check that our ssh private key exist (based on variable key_file)
## 2 - we copy the public key on all the specified hosts
## 3 - we update /etc/sudoers on each systems so that our user won't be prompted for password when issuing sudo command ... needed for ansible
## 4 - add ansible repo to systems and do update / upgrade
## 5 - install git and ansible. Once it's done, retrieve our git repo https://github.com/nmenant/Ansible-systems-setup (dev) , setup ansible config files

setup_base() {
   check_id_rsa_exists
   transfer_public_key
   add_user_sudoer_nopasswd
   update_upgrade_repos
   install_setup_ansible
}

##
## with this function we will setup our playbook with the relevant information so that it's processed successfully
## 1 - move ansible_variables to our group_vars dir so that those will become variables in our playbook. It includes different needed information
## 2 - move systems_hosts_file into our playbook so that this will be pushed on all our systems. 
## 3 - launch the ansible playbook 
##

execute_ansible_playbook() {

   cp ansible_variables ansible/playbooks/group_vars/all
   cp systems_host_file ansible/playbooks/roles/setup-hosts-hostname/templates/hosts.j2
   ansible-playbook ansible/playbooks/site.yml
}
##
## MAIN SCRIPT STARTS HERE
##

check_parameters $1
res=$?
check_hosts_file

if [ "$res" -eq 1 ]; then
   printf "Setup option specified ... doing the systems preparation\n"
   setup_base
elif [ "$res" -eq 2 ]; then
   printf "Ansible option specified ... launching ansible playbooks\n"
   execute_ansible_playbook
elif [ "$res" -eq 3 ]; then
   printf "All option specified ... doing Setup and Ansible playbook\n"
   setup_base
   execute_ansible_playbook
fi

