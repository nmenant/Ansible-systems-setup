#!/bin/bash

##
## we check if the parameters have been transmitted or not 
## if not, return syntax usage
##
key_file="/home/$USER/.ssh/id_rsa"
hosts_file="hosts_file"

check_parameters() {
   if [ -z $1 ]; then
      printf "Syntax: ./setup_systems.sh <setup or execute>\n - setup: setup the ssh keys, transfer keys , update sudoers and install git and ansible\n - execute: deploys the ansible playbook to setup the systems\n"
      exit
   fi
   if [ ${1,,} == "setup" ]; then 
      return 1
   elif [ ${1,,} == "execute" ]; then
      return 2
   else
      printf "Syntax: ./setup_systems.sh <setup or execute>\n - setup: setup the ssh keys, transfer keys , update sudoers and install git and ansible\n - execute: deploys the ansible playbook to setup the systems\n"
      exit
   fi
}

check_hosts_file() {
   tmp=0

   if [ -f $hosts_file ]; then
      printf "checking hosts_file\nSystems to setup:\n"   
      while read -r line
      do
         name="$line"
         if [[ ! $name =~ ^'#' ]] && [[ ! $name == '' ]] && [[ ! $name =~ "[nodes]" ]]; then
            printf "%s\n" $name
            tmp=1
         fi 
      done < "$hosts_file"
      if [ $tmp -eq 0 ]; then
         printf "no system specified in %s. Exiting\n" $hosts_file
         exit
      fi
   else
      printf "couldn't find %s. Exiting...\n" $hosts_file
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
   done < "$hosts_file"
}

add_user_sudoer_nopasswd() {
   while read -r line
      do
         name="$line"
         if [[ ! $name =~ ^'#' ]] && [[ ! $name == '' ]] && [[ ! $name =~ "[nodes]" ]]; then
            printf "updating sudoer file on %s so that %s doesn't need password prompt with sudo commands" $name $USER
            ssh -t $name 'sudo sh -c "echo \"$USER ALL=(ALL:ALL) NOPASSWD: ALL\" >> /etc/sudoers"'
         fi
   done < "$hosts_file"
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
   sudo cp $hosts_file /etc/ansible/hosts

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
## MAIN SCRIPT STARTS HERE
##

check_hosts_file
check_parameters $1

res=$?
if [ "$res" -eq 1 ]; then
   printf "Setup option specified ... doing the systems preparation\n"
   setup_base
elif [ "$res" -eq 2 ]; then
   printf "Execute option specified ... launching ansible playbooks\n"
fi

