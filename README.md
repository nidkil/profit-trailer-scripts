# profit-trailer-scripts
This repository contains a number of bash scripts I use to manage Profit Trailer (PT) on my VPS running on Ubuntu 17.10. PT is an cryptocurrency trading bot.

This repository contains the following scripts:
1. Deploy script (deploy-scripts.sh)
2. PT upgrade (ptm-upgrade.sh)

What the scripts do is described in the following sections.

# 1. Deploy scripts (deploy-scripts.sh)

This script deploys the scripts to each Profit Trailer (PT) instances, so each instance has the latest versions of the scripts. This means you can use git clone and pull to keep the scripts up to date. When a new version becomes available, just do a pull to sync and then call this script to deploy it to the PT instances.

## What does it do?

The script does the following:

* It retrieves all the  symbolic links from the /op/profit-trailer directory that end with \'-cur\'
* It publishes all scripts to the directories the symbolic links are pointing to
* It makes the main scripts executable

## Important

This script is based on my setup of [Ubuntu](http://nidkil.me/2018/01/19/initial-server-setup-ubuntu-17-10/), [Profit Trailer](http://nidkil.me/2018/01/22/profittrailer-setup-on-ubuntu-17-10/) and [PT Magic](http://nidkil.me/2018/02/19/pt-magic-setup-on-ubuntu-17-10/).

* This script expects that the following directory layout is used:

    | Directory                               | Description                                  |
    | --------------------------------------- | -------------------------------------------- |
    | /opt/profit-trailer/pt-\<exchange\>-cur | softlink pointing to the current PT versions |
  
Where \<exchange\> is the exchange the PT installation is trading against.

## Command line arguments

Usage: publish-scripts.sh

Example: publish-scripts.sh

# 2. PT upgrade (pt-upgrade.sh)

Upgrades a Profit Trailer (PT) instance to the latest version. It downloads the latest version of PT from GitHub and installs it to a new directory with existing data and config files. This script must be run from inside the directory of the current PT instance you wish to upgrade. If the latest version is already installed it will display a warning message and exit.

## What does it do?

The script does the following:

* Checks if a new version of PT is available on GitHub
* If a new version is available it downloads it
* Installs the downloaded version of PT to a new directory
* Stops PT using the PT API
* Copies the data files, configs and scripts from the current PT instances to the new directory, so that the data and configs are maintained, this also makes it possible to rollback to the previous version if necessary
* Sets a softlink (pt-\<exchange\>-cur) to the new directory, so that it becomes the current version
* Removes the PM2 settings, as these are pointing to the old PTM directory
* Restarts PT using PM2

## Important

This script is based on my setup of [Ubuntu](http://nidkil.me/2018/01/19/initial-server-setup-ubuntu-17-10/), [Profit Trailer](http://nidkil.me/2018/01/22/profittrailer-setup-on-ubuntu-17-10/) and [PT Magic](http://nidkil.me/2018/02/19/pt-magic-setup-on-ubuntu-17-10/).

1) This script expects that the following directory layout is used:

    | Directory                                | Description                                 |
    | ---------------------------------------- | ------------------------------------------- |
    | /opt/profit-trailer/ptm-\<exchange\>-cur | softlink pointing to the current PT version |
  
2) It also expects that PM2 is used to manage PT and process identifiers conform with the following naming convention:

    | Naming convention    | Description                                        |
    | -------------------- | -------------------------------------------------- |
    | pt-\<exchange\>      | Profit Trailer instance for the specified exchange |
  
Where \<exchange\> identifies the exchange the PT instance is trading against.

The script will extract the unique exchange identifier from the directory name it is executed from.

## Command line arguments

Usage: pt-upgrade.sh [-d]

&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;optional arguments:
  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;-d  show initialized variables and exit the script, for debugging purposes only

Example: pt-upgrade.sh
# Done

The following has been implemented:

* Automated the upgrade to the latest version of PT
* Automated the deployment of the latest versions of scripts to all PT instances

# To do

The following still needs to be implemented:

* Support for multiple instances per exchange (test, production, sell only)

I hope this is helpful. If you have any tips how to improve the scripts or any other suggestions drop me a message.
