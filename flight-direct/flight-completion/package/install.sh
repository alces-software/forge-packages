#!/bin/bash

cp -R data/* "${FL_ROOT}"
flight ruby "$FL_ROOT"/scripts/completion.rb

