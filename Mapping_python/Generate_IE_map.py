import os

import numpy as np

import pandas as pd

import re

from geotiffio import readtif, createtif, writetif

from win32com.client import Dispatch

"""
  Funciones locales para el cálculo de la IE
"""


def lista_nodos_diccionario(BNet):
    # Get the pointer to the set of nodes
    nodesList_p = BNet.Nodes
    # get number of nodes
    nnodes = nodesList_p.Count
    # Collect all node names in network
    node_names = {}
    for i in range(nnodes):
        node_p = nodesList_p[i]   # node_p
        name = node_p.name        # name
        node_names[name] = node_p
    return node_names


def process_on_data_table(lic_arch, net_file_name, data_table):
    # Read the beleif values under specified conditions
    net.compile()
    expected_val = []
    for j in xrange(data_table.shape[0]):
        net.RetractFindings()
        if data_table["dem30_mean1000"][j] > -999:
            for nd in data_table.columns:
                if nd != "zz_delt_vp" and data_table[nd][j] > -999:
                    node_lst[nd].EnterValue(data_table[nd][j])
            expected_val.append(node_lst["zz_delt_vp"].GetExpectedValue())
        else:
            expected_val.append(-999)
    return expected_val

    # Se libera el espacio de momoria usado por la red
    net.Delete()


def on_toy():
    """
      Detecta si está corriendo en un equipo conocido y ajusta
      las rutas necesarias.
    """
    list_users = os.listdir("c:/users")
    if u"miguel.equihua" in list_users:
        equipo = "esc_m"
    elif u"Miguel" in list_users:
        equipo = "lap_m"
    else:
        print "Hay que especificar la ubicación de los archivos necesarios:"
        print "     licencia de Netica"
        print "     Archivos tif de variables"
        print "     Red entrenada"
    return equipo
# ----------------------------------------------------

equipo = on_toy()

if equipo == "lap_m":
    netica_dir = u"".join([
        u"C:/Users/Miguel/Documents/0 Versiones/2 Proyectos/",
        u"BN_Mapping/Netica/"])
    dir_robin =\
        u"C:/Users/Miguel/Documents/1 Nube/GoogleDrive/2 Proyectos/RoBiN"
else:
    netica_dir = u"".join([u"C:/Users/miguel.equihua/Documents/0-GIT/",
                          u"Publicaciones y proyectos/BN_Mapping/Netica/"])
    dir_robin = u"C:/Users/miguel.equihua/Documents/1 Nube/" +\
                u"Google Drive/2 Proyectos/RoBiN"

dir_datos = u"". join([u"/Datos RoBiN/México/0_Vigente/GIS/",
                      u"Mapas_base/2004/train_data_pack/"])

# Activate Netica and Read BN
# Vincula la interface COM de NETICA y activa la aplicación
nt = Dispatch("Netica.Application")
print "Welcome to Netica API for COM with Python!"

# Lee la licensia de activasión de Netica
lic_arch = netica_dir + "/inecol_netica.txt"
licencia = open(lic_arch, "rb").read()
nt.SetPassword(licencia)
# Window status could be: Regular, Minimized, Maximized, Hidden
nt.SetWindowPosition(status="Regular")

# Display NETICA version
print "Using Netica version " + nt.VersionString
net_file_name = dir_robin + dir_datos +\
 "EI_Naive_Step_n10_zvh31_peinada_sin_medias.neta"
# Prepare the stream to read requested BN
streamer = nt.NewStream(net_file_name)

# ReadBNet 'options' can be one of "NoVisualInfo", "NoWindow",
# or the empty string (means create a regular window)
net = nt.ReadBNet(streamer, "")
node_lst = lista_nodos_diccionario(net)

dir_tif = re.sub(u"train_data_pack/", "", dir_robin + dir_datos)
files = {re.sub(".tif", "", re.sub("2004_", "", f1)): f1
         for f1 in os.listdir(dir_tif) if re.findall("tif$", f1)}
for f in files.keys():
    if f not in node_lst:
        files.pop(f)

# read one image to get metadata
dataset, rows, cols, bands = readtif(dir_tif + files.values()[0])

# image metadata
projection = dataset.GetProjection()
transform = dataset.GetGeoTransform()
driver = dataset.GetDriver()

# prediction table (pixels are rows, columns are variables)
names = files.keys()
data_table = pp = pd.DataFrame(index=xrange(cols*rows), columns=names)

for b in xrange(len(files)):
    image, rows, cols, bands = readtif(dir_tif + files.values()[b])
    band = image.GetRasterBand(1)
    band = band.ReadAsArray(0, 0, cols, rows).astype(float)
    band = [b1 if b1 > -999 else -999 for b1 in np.ravel(band)]
    data_table[names[b]] = np.ravel(band)

### insert process to predict using data_table
ie_map = process_on_data_table(netica_dir, net_file_name, data_table)

### write ie_map to disk
output_name = dir_tif + "filename.tif"

outData = createtif(driver, rows, cols, 1, output_name)

writetif(outData, ie_map, projection, transform, order='c')

# close dataset properly
outData = None
