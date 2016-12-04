# Ansible - Systems setup

## Introduction

The purpose of this project is to be able to setup a group of systems (today Ubuntu only) automatically

  * Update and upgrade the system 
  	- apt-get update / upgrade for Ubuntu systems
  * Setup Hostname
  * Setup /etc/hosts file
  * Setup the network interfaces
    - /etc/network/interfaces for Ubuntu systems

We will do the setup via an [ansible playbooks](http://docs.ansible.com/ansible/playbooks.html)

<hr>

## Pre -requisites

To be able to leverage Ansible, you'll have to do this before trying to use it. 

Create a user that will be able to connect to all the systems without : 
 * Authentication (via keys)
 * Run sudo command without prompt

To do so:

 * You can create ssh keys for the user via the *ssh-keygen* command. Run this command on the **node that will run Ansible**
 * Once you have your keys, you need to transfer them to all the systems involved (ssh-copy-id <user>@<IP>), **including your local system!!**
 * We enable the user to do sudo commands without authentication (needed to use ansible with this user). You can do this via the visudo command to specify that we allow passwordless sudo command for this user (here is a [thread](http://askubuntu.com/questions/504652/adding-nopasswd-in-etc-sudoers-doesnt-work/504666/) talking about how to do it.

<hr>

## How-to - Install Ansible

First thing is to make sure that ansible is installed on one of the system to setup (internet access required)

Here is how to install Ansible on **Ubuntu**

    sudo apt-get update -y

	sudo apt-get install -y software-properties-common
	
	sudo apt-add-repository ppa:ansible/ansible -y
	
	sudo apt-get update && sudo apt-get install ansible -y


## How-to - setup Ansible

Here are the config files that we will need to setup to be able to run ansible: /etc/ansible/ansible.cfg and /etc/ansible/hosts

Enable the following options in /etc/ansible/ansible.cfg (you need to use sudo)

 * inventory: specify which file contains the nodes available to ansible
 * become_user: allow to specify which user we impersonate when using become
 * host_key_checking: means that we bypass the security host check when connecting via ssh 


    inventory      = /etc/ansible/hosts

    become_user=root

    host_key_checking = False


/etc/ansible/hosts is used to list the nodes that are available to ansible. Create something like this (here we consider that we have 4 systems to setup and their hostname are system1, system2, system3, system4 - you must be able to resolve those hostnames) 

    [nodes]
    system1
    system2
    system3
    system4

**the names you specify in this file will become the hostname of the systems, so be careful**

One way to resolve those hostnames is to setup your /etc/hosts config file. 

for example: 

     10.1.1.1	system1	system1.my-lab
     10.1.1.2	system2	system2.my-lab
     10.1.1.3	system3	system3.my-lab
     10.1.1.4	system4	system4.my-lab

## How-to - test ansible

You can test your ansible setup by running the following command on the system where you installed ansible: 

    ansible all -a "ls -l"

this command will connect to **all** the systems setup in /etc/ansible/hosts and will run "ls -l" and give back the output. If there is any failure, check the output

## How-to - define your systems config

to explain how you expect your systems to be setup, you will need to update the following files: 

 * ansible/playbooks/group_vars/all - this file contain your systems definition from a networking perspective. Here you should specify all the interfaces to setup for each system

 * ansible/playbooks/roles/setup-hosts-hostname/templates/hosts.j2 - this will be the /etc/hosts file that will be pushed on all systems


To update the interfaces definition in *ansible/playbooks/group_vars/all*, here is the syntax: 

    for dhcp based interface: 
    { server_name: '<system name>', intf_name: '<interface id>', mode: '<static or dhcp>' }
    ex: { server_name: 'master1', intf_name: 'eth0', mode: 'dhcp' }
    
    for static IP based interface:
    { server_name: '<system name>', intf_name: '<interface id>', mode: 'static', addr: '<static or dhcp>', mask: '<mask>' }
    ex: { server_name: 'master1', intf_name: 'eth1', mode: 'static', addr: '10.1.10.11', mask: '255.255.255.0' }


Be aware that the *<system name>* must match the name you put in /etc/ansible/hosts

## How-to - Run the ansible playbook 

to run the playbook, you need to run the following command (from the Ansible-systems-setup directory):

    ansible-playbooks ansible/playbooks/site.yml









