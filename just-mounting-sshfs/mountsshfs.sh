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

/**
 * A nice-to-have script that streamlines the SSHFS mounting process as it creates the dir to mount to
 * for you.
 *
 * How to use this script:
 *
 * ./mountsshfs domain.tld
 * ./mountsshfs user@domain.tld
 *
 */

$help = '
   HELP
   ====
   
   Mounts a remote Websupport hosting directory.
   
   $ ./mountsshfs.sh [connection]
   
   connection (required)
     hostname or login@hostname
      - e.g.: attitude.sk
      - e.g.: specialuser@attitude.sk

';

if( ! isset($argv[1] ) )
	exit("\n ! Warning: You need to specify domain. Type ./mountsshfs.sh -help for help.'\n\n");

$connection = $argv[1];
if( $connection === '-help' || $connection === '-h' ) exit( $help );

$parts = explode( '.', $connection );

switch( sizeof($parts) )
{
	case 2:
		$host = $parts[0].'.'.$parts[1];
		$user = $host;
		$dirname = $host.'/root';
	break;
	//////
	case 3:
		$host = $parts[1].'.'.$parts[2];
		$user = $parts[0].'.'.$host;
		$dirname = $host.'/'.$parts[0];
	break;
	//////
	default:
		exit("\n ! Warning: Bad connection. Type ./mountsshfs.sh -help for help.'\n\n");
	break;
}

if( ! file_exists($dirname) )
{
	echo " > No directory with name '{$dirname}' ...\n";
	try
	{
		if( ! mkdir( $dirname, 0755, true ) )
		{
			throw new Exception("Unable to create directory '{$dirname}', try to create it manually\n");
		}
	}
	catch(Exception $e)
	{
		exit( ' ! ERROR: '.$e->getMessage() );
	}
	
	echo " > Target directory '{$dirname}' created ...\n";
}
elseif( ! is_dir($dirname) )
{
	exit (" ! ERROR: A file with the same name already exists. Cannot create a directory '{$dirname}'\n");
}

echo " > Target directory '{$dirname}' ready ...\n";
	
// http://www.dragffy.com/posts/using-sshfs-with-bazaar-bzr-or-git
// http://www.mail-archive.com/macfuse-devel@googlegroups.com/msg00586.html
// 
// Using default mount options for SSHFS leads to errors in both Git and Bzr, this is because (I believe) SSHFS doesn’t 
// directly support file renaming. It is possible to avoid these problems by using the -oworkaround=rename switch with 
// the mount command.
// 
// As an example my mount command looks similar to this:
// sshfs -oworkaround=rename user@computer1:/var/www /media/computer1
try
{
	// sshfs attitude.sk@attitude.sk:/ attitude.sk/subdir-by-user
	$command = "sshfs -oworkaround=rename {$user}@{$host}:/ {$dirname}";
	$output = array();
	$return = false;
	echo " > Mounting: \$ $command\n";
	exec($command, $output, $return);
	
	if( $return === 1 )
	{
		rmdir($dirname);
		
		throw new Exception("Unable to mount user '{$user}' at host '{$host}'.
   [i] Check your password for user '{$user}'
   [i] Check your /etc/hosts file
   [i] If using SSH authentification make sure the remote '/.ssh/authorized_keys' file contains your
       id_rsa.pub key\n");
	}
}
catch(Exception $e)
{
	exit( ' ! ERROR: '.$e->getMessage()."\n" );
}

echo " > Host {$connection} mounted to {$dirname} successfully\n >\n > See you soon, bye\n\n";

?>
