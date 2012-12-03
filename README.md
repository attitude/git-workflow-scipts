Git Workflow Scipts
===================

\#!/usr/bin/php scripts I use to sync and deploy to Websupport.sk servers using GIT hooks, RSYNC and 
SSHFS (all scripts are experimental)

While trying to use **mounted hosting using SSHFS** what frustrated me most was the fact that every 
command  run near zero speed. Any *git* command was **painfully slow** and in the end it just failed 
(might have been my mistake).

Anyway, to be able to use any *GIT flow deployment tactics* you need to have some direct acces to a git 
enabled host directly. Well even with the best hosting providers you can hardly get SSHFS, RSYNC. 
Forget about getting access to GIT command any soon. Although, some rumors say, there might be some 
hope in the future.

And since GIT looks at the whole repository when looking for changes, every command requiring lookup 
through remote files was a waste of time and trafic of files up-down for (not tested all but all 
mostly used like *clone*, *pull*) every GIT command.

So I did my homework, researched a bit and realised that it can be done the other way. This way:

1. I realised that GIT is a distributed system and therefore, I can use the same tools to create my own 
   "remote origin" on my machine. Soon I found out that you can only push to a --bare repository 
   (otherwise you would need to make a hard reset of the HEAD).
1. If you upload a `id_rsa.pub` (public key) to the [Websupport.sk](http://www.websupport.sk/) servers 
   you don't need to write any password during the connection process. (You need to rename it to 
   `/.ssh/authorized_keys` where `/` is the root of your path to which the user.your-hosting.sk has 
   access - not necessarily the root of the server.
1. You can pull to any other repository from the bare repo to get the copy of your working files.
1. Rsync is a very fast way to sync any local dir with remote dir.

Boom, you might now see the pattern or navigate to the scripts and read the inline comments for 
more inside perspective.

Why the hack did you chose PHP?
-------------------------------

1. I used PHP as language of choice as it allows me to do what I need to do (GTD).
1. It is the language I use the most, so I can write scripts quite fast (learning curve reason).
1. I am not as close to be skilled in BASH and other fancy shell stuff as I am skilled in PHP (quality).

Requirements
------------

- any UNIX/LINUX/OSX will do
- git, rsync, sshfs installed
- /.ssh/authorized_keys on server

*Note:* I use Homebrew, [The missing package manager for OS X](http://mxcl.github.com/homebrew/).
Others might want to use *apt-get* (Ubuntu and other Defian-based) or *yum* (CentOS).
Feel free to suggest others packaging managers.

So if you are the match, feel free to fork and make something awesome with it, spreading word is also 
appreciated. I might also add issues for this repository so if that is true feel free to open one if 
you get the feeling that there's something you might want to say. Any ideas are wellcome.

More reading
------------

Same stuff that inspired me to write this scripts (Slovak language):

- [You should use SSHFS](http://blog.websupport.sk/2012/11/pouzivate-sshfs-mali-by-ste/)
- [FTP is passé, move on to RSYNC](http://blog.websupport.sk/2012/09/ftp-je-pase-prejdite-na-rsync/)
- [Deployment using SSHFS and good hosting](http://blog.ujovlado.sk/clanky/jednoduchy-deployment-s-pomocou-sshfs-a-dobreho-hostingu)

About me
--------

Web designer, mostly graphic designer, coding enthusiast, occasional developer and a [dog lover](http://instagram.com/martin_adamko).
If you feel like saying hi, you can do it on [Twitter](http://twitter.com/martin_adamko).

*Note:* I am not anyhow related to [Websupport.sk](http://www.websupport.sk/), I just they are the best 
web hosting service around so you might want to check them out.

Licensed under the [Apache License, Version 2.0](http://www.apache.org/licenses/LICENSE-2.0).

