# -*- coding: utf-8 -*-
"""
Created on Thu Jun 25 21:07:25 2015

@author: Miguel
"""

import os
import re
from netCDF4 import Dataset as nc

# Ubicación de los datos en formato nc
direct_ROBIN = u"C:/Users/Miguel/Documents/1 Nube/GoogleDrive/2 Proyectos/RobiN"
direct_lpj = "/Datos RoBiN/México/0_Vigente/GIS/LPJ" 
os.chdir(direct_ROBIN + direct_lpj)
directorios = os.walk(".")
sub_dir = next(directorios)[1][0]
os.chdir(direct_ROBIN + "/" + sub_dir)
archivos = os.listdir(os.curdir)
archivos = [nombre for nombre in archivos if re.findall("\\.nc$", nombre)]

# Revisa los archivos en el directorio indicado
resultados = {"bueno" : [], "malo" : []}
for dataset in archivos:
    # Lee el archivo nc seleccionado
    try:
        nc_dataset = nc(dataset, "r", format="NETCDF4")
        resultados["bueno"].append(dataset)
        nc_dataset.close()
    except RuntimeError:
        resultados["malo"].append(dataset)
        

print "\nArchivos con errores  -----  no se pueden leer ***"
for d in resultados["malo"]:
    print "\t<%s>" %d
    
print "\n\nArchivos accesibles -----  parecen estar OK !!!!!"
for d in resultados["bueno"]:
    print "\t<%s>" %d
