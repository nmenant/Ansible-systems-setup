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

##
## The main function for the setup argument
## 1 - we check that our ssh private key exist (based on variable key_file)
## 2 - we copy the public key on all the specified hosts
##

setup_base() {
   check_id_rsa_exists
   transfer_public_key
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

