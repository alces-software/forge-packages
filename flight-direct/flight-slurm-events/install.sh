#!/bin/sh
for a in events/*; do
    flight events listen $(basename "$a") flight-slurm $(pwd)/$a
done
