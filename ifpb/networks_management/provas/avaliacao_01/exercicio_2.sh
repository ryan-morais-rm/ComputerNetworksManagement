#!/bin/bash

sudo dnf install -y php php-cli 

php -r 'echo PHP_MAJOR_VERSION . "." . PHP_MINOR_VERSION . PHP_EOL;'

php t.php

php -v