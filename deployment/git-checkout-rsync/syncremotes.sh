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

IDEA BEHIND – Separation
------------------------

You now MVC pattern, right? You separate models from views from controllers. What about the application 
to bootstrap system relationship? I guess same thing could be considered for a third party software you 
use to build application.

I've been developing websites with WordPress and have some experience with CodeIgniter. What they have 
in common is that they are basically your foundation to your own application build on top of that.

### The GIT submodules

You can go the GIT submodules way any time. Separating WordPress from your worktree is not that easy 
but it can be accomplished. My case is different. I need to have few versions of this 'foundation' on 
my servers. Allows me to switch versions really fast and also I can run on the latest code if I need to 
and if something goes wrong I can go back to a stable version in the next directory.

Hence this script.

PREPARATION
-----------

1. Have your local clone of any GIT hosted repository (github.com, bitbucket.org,...) in one place like
   /Users/yourname/foundations/Wordpress
2. Copy `post-checkout` file to /Users/yourname/foundations/Wordpress/version-you-want-to-sync/.git/hooks
3. Copy this file 1 levels UP to /Users/yourname/foundations/Wordpress/

WORKFLOW
--------

1. You pull with --rebase from the git@github.com:WordPress/WordPress.git into your clone repository
2. After successful pull the hook is run wich runs this script with argumets for you
3. Runs RSYNC to sync your files to your server

SETUP (a Wordpress example)
---------------------------

Server setup
(root)
|- latest/
|- v3.4.2/
|- v3.4.1/
:
.

Local worktree
(root)
|- wp-config.php		< one level up config file allows moving WordPress one level up
|- [this-file].sh
|- latest/
|  |- .git/
|  :  |- hooks/
|  .  :  |- post-checkout	< hook runs after successfully receiving pull
|     .  :
|        .
|- v3.4.2/
|  |- .git/
|  :  |- hooks/
|  .  :  |- post-checkout	< hook must be in every repository you wish to sync to your host
|     .  :
|        .
|- v3.4.1/
:  |- .git/
.  :  ...
   .

Notes:

- You need to set the $userathost variable with your data
- The directory you wish to copy to must contain /.ssh/authorised_keys file to allow passwordless 
  connection
- This script can only sync immediate child directories on the root

*/

// wordpress.attitude.sk@attitude.sk
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

$path =& $repository_dir_path;

$command =
'rsync	-azv --delete --delete-excluded --delete-after \
	--exclude ".git" \
	--filter "P .ssh/*" \
	--exclude ".ssh" \
	--exclude ".DS_Store" \
	'.$path.'/. \
	'.$userathost.':/'.basename($path);
echo $command."\n";
// exit;

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

exit(0);

?>
