@echo off
REM Run ONCE before first docker-compose up
REM Creates clean-named copies of model files for Docker volume mounts

copy "efficientnetb4-Plant Village Disease-weights1.h5" weights.h5
copy "Plant Village Disease-class_dict.csv" class_dict.csv

echo.
echo Created weights.h5 and class_dict.csv
echo Ready for: docker-compose up --build
