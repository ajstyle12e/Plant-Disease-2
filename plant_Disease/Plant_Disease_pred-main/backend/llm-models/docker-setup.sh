#!/bin/bash
# Run this ONCE before docker-compose up
# Creates symlinks/copies with space-free filenames for Docker volume mounts

cp "efficientnetb4-Plant Village Disease-weights1.h5" weights.h5
cp "Plant Village Disease-class_dict.csv" class_dict.csv
echo "Done. weights.h5 and class_dict.csv created."
