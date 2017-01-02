# Ansible - Systems setup

## Introduction

The purpose of this project is to be able to setup a group of systems (today Ubuntu only) automatically

  * Update and upgrade the system 
  	- apt-get update / upgrade for Ubuntu systems
  * Setup Hostname
  * Setup /etc/hosts file
  * Setup the network interfaces
    - /etc/network/interfaces for Ubuntu systems

We will do the setup via a shell script that will call an [ansible playbooks](http://docs.ansible.com/ansible/playbooks.html) to finalize the setup

The shell script will: 

 * Setup the environment to be able to use ansible (create ssh keys if they don't exist, copy key, enable sudo without password, ) - **the user must be allowed to do sudo commands to make this work**
 * call ansible playbook once the environment is staged properly (setup /etc/hosts, hostname and network interfaces)

<hr>

## Define your environment

Before running the script, you'll need to define your environment. To do this, you'll need to setup the following files: 

 * ansible_hosts_file: this file is used by the shell script and ansible to know which systems to setup. 
  - **The system running the script need to be able to resolve those names**. 
  - **Those names will be used to setup /etc/hostname on the different sytems**
 * ansible_variables: this file is used to specify some information to ansible: 
  - specify which system run ansible. This system will not be rebooted but everything will be
  - your network interfaces to be setup on each node
 * systems_hosts_file : this file will be pushed and will replace /etc/hosts on all the targeted systems. 

## Run the solution

To run the solution, you'll launch the script setup_systems.sh

Here is the syntax: 

    Syntax: ./setup_systems.sh <setup or ansible or all>
 
Here are the options : 
 * setup: setup the ssh keys, transfer keys , update sudoers and install git and ansible
 * ansible: deploys the ansible playbook to setup the systems
 * all: will do setup and then ansible

