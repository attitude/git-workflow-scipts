#!/usr/bin/php
<?php

/**
 * Copyright 2012 Martin Adamko
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

/*
HOW TO
======

PREPARATION
-----------

1. Have your local clone of any GIT hosted repository (github.com, bitbucket.org,...) in one place like
   /Users/yourname/Sites/current_project
2. Prepare some "dummy" remotes in the second place (anywhere where you can run .sh files) like
   /Users/yourname/Remotes/current_project.git (git clone --bare <github/bitbucket/anyother>)
   /Users/yourname/Remotes/current_project (git clone current.project.git)
   Heads up! When you clone from bare repository this bare repository is automatically set as origin.
   This is assumed to be true by this script as it pulls changes to it from origin
3. Add /Users/yourname/Remotes/current_project.git as remote to your /Users/yourname/Sites/current_project
   repository and name it something like `deploy`
4. Copy `post-receive` file to /Users/yourname/Remotes/current_project.git/hooks
5. Copy this file 2 levels UP to /Users/yourname (TODO: find some way to make it more general)

WORKFLOW
--------

1. You work on your local working copy and when you wish to propagate changes you push to remote `deploy`
2. The bare remote /Users/yourname/Remotes/current_project.git receives a push and runs a post-receive 
   hook script which runs this script with argumets for you
3. This cript pulls changes from bare repo to non-bare
4. Runs RSYNC to sync your files to your server

THE SETUP
=========

My server setup:
----------------
(root)
|- domain1/
:  |- subdomain-1/
.  |- subdomain-2/
   |- ...
   `- subdomain-n/

Receiving remote git repos setup:
---------------------------------
(root)
|- [this-file].sh
|- domain1/
.  |- subdomain-1.git/		< this is the bare repository (can receive push but has no workfiles)
   |  |- hooks/
   |  :  |- post-receive	< hook runs after successfully receiving push
   |  .  :
   |     .
   |- subdomain-1/		< a clone repo of a bare repository to have workfiles somewhere
   :  |- .git/
   .  |- ...			< your awesome work files (remote copy to be synced)
      :
      .

Local working copy		< where the hard work is done
------------------
(anywhere-you-want)
|- subdomain-1-local-copy/	< a working clone of your remote repository
:  |- .git/
.  |- ...			< your awesome local work files
   :
   .

Notes:

- This setup is not a default WEBSUPPORT.sk setup. I use .htaccess to root my subdirectories
  a lot as I have few domain redirects active to my unlimited hosting.
  To use with default setup you need to figure out how many dirname() functions to use in the 
  post-receive hook to find [this-file].sh script.
- You need to set the $userathost variable with your data
- The directory you wish to copy to must contain /.ssh/authorised_keys file to allow passwordless 
  connection

 */

// Mine is e.g. public.attitude.sk@attitude.sk
$userathost = 'user.your.host@your.host';

if( ! (isset($argv[1]) && ! empty($argv[1]) ) )
{
	exit(" ! Wrong syntax, use: ".basename(__FILE__)." <dir_to_sync>\n");
}

$repository_dir_name = rtrim($argv[1],'/');
if( $repository_dir_name[0] === '/' )
{
	$repository_dir_path = $repository_dir_name;
}
else
{
	$repository_dir_path = dirname(__FILE__).'/'.$repository_dir_name;
}

if( ! (file_exists($repository_dir_path) && is_dir($repository_dir_path)) )
{
	exit(" ! Error: Directory `{$repository_dir_path}` does not exist\n");
}

$git_path	=& $repository_dir_path;
$path		= str_replace( '.git@£$%^&*()_+', '', $git_path.'@£$%^&*()_+');

// Does the $path exist?
if( file_exists($path) && ! is_dir($path) )
{
	if( rename($path,$path.'.bkp') )
	{
		echo "! A file/directory with the same name already exists, rename hack in action.\n";
		define( 'RENAMEHACK', true);
	}
	else
	{
		exit( " ! ERROR: Unable to use rename hack, a file with the same name as new repository already exists\n" );
	}
}

if( ! file_exists($path) )
{
	mkdir( $path, 0755, true );
	
	// init git repository
	try
	{
		$output = array();
		$return = 0;
		
		exec('git clone '.$git_path.' '.$path, $output, $return);
		
		if( $return !== 0 )
		{
			throw new Exception("Unable to clone bare repository into directory: ".$path);
		}
	
		echo "> ".implode("\n> ",$output)."\n";
	}
	catch(Exception $e)
	{
		exit( ' ! ERROR: '.$e->getMessage()."\n" );
	}
}
else
{
	// update git repository
	try
	{
		$output = array();
		$return = 0;
		
		// unset GIT_DIR or http://stackoverflow.com/questions/8560618/how-can-i-use-full-paths-in-git
		$cmd = 'cd '.$path.' && unset GIT_DIR && git pull --rebase origin';
		exec($cmd, $output, $return);
		
		if( $return !== 0 )
		{
			throw new Exception("Unable to update repository into directory `".$path."`");
		}
	
		echo "> ".implode("\n> ",$output)."\n";
	}
	catch(Exception $e)
	{
		exit( ' ! ERROR: '.$e->getMessage()."\n" );
	}
}

// Replace with your directives, might also be moved to external file
$command =
'rsync	-azv --delete --delete-excluded --delete-after \
	--filter "P .ssh/*" \
	--filter "P wp-content/uploads/*" \
	--exclude ".git" \
	--exclude ".ssh" \
	--exclude ".gitignore" \
	--exclude ".DS_Store" \
	'.$path.'/. \
	'.$userathost.':/'.str_replace( dirname(__FILE__).'/', '', $path );
echo $command."\n";

try
{
	$output = array();
	$return = false;
	
	exec($command, $output, $return);
	
	if( $return === 1 )
	{
		throw new Exception("Unable to sync with remote");
	}
	
	echo "> ".implode("\n> ",$output)."\n";
}
catch(Exception $e)
{
	exit( ' ! ERROR: '.$e->getMessage()."\n" );
}

// Heads up! Everytime the renamehack is used a new clone of bare repository is created resulting in 
// Rsync syncing all the files once again. You should not encounter this behaviour, it's a really edge 
// case.
if( defined('RENAMEHACK') )
{
	// remove the directory
	try
	{
		$output = array();
		$return = 0;
		
		exec('rm -rf '.$path, $output, $return);
		
		if( $return !== 0 )
		{
			throw new Exception("Unable to remove directory: ".$path."
  [i] You need to remove it manually and rename back the .bkp file");
		}
	
		echo "> ".implode("\n> ",$output)."\n";
	}
	catch(Exception $e)
	{
		exit( ' ! ERROR: '.$e->getMessage()."\n" );
	}
	
	if( rename($path.'.bkp', $path) )
	{
		echo "> Rename hack successful\n";
	}
	else
	{
		echo "! File/directory cannot be renamed back after the rename hack. Remove .bkp manually\n";
	}
}

echo "> Sync with remote successful\n";

exit(0);

?>
