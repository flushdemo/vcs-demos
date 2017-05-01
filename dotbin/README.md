Prerequisite
============

CC65 with Atari 2600 support. Currently available at the following
URL:

https://github.com/FlorentFlament/cc65

Get CC65, compile and install it:

    $ git clone https://github.com/FlorentFlament/cc65.git
    $ cd cc65
    $ make
    $ prefix=$HOME/ make install

Also set the `CC65_HOME` environment, like this:

    $ echo "export CC65_HOME=${HOME}/share/cc65" >> ~/.bashrc

And update the PATH in the `~/.bashrc` if required

    $ PATH=${HOME}/bin:${PATH}


Compiling the Demo
==================

    $ make


Running the Demo
================

    $ make run
