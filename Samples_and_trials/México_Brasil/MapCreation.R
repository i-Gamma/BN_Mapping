
# paquetes
library(foreign) #permite leer archivos dbf
library(raster)
library(ggplot2)
library(scales)
library(RODBC)

# Directorios usados ------------------------------------------------------
# trabajo equipo port�til Miguel
dir.trabajo <- "~/0 Versiones controladas/GIT/Proyectos y publicaciones/ROBIN/Interp y redes (R)/M�xico_Brasil"

# datos que se usar�n para los c�lculos, tabla que incluye todas las variables
#dir.datos <- "C:/Julian/97IntegridadEcoNivelNacional/3mapas2"
dir.datos <- "~/1 Nubes/Google Drive/2 Proyectos/RoBiN/Datos RoBiN/Datos MEX/0 - Integridad - mapeo"

# Base de datos INFyS y otras variables
dir.bd.infys <- "C:/Users/miguel.equihua/Documents/1 Nubes/Google Drive/2 Proyectos/RoBiN/Datos RoBiN/Datos MEX/IEMex"


# Prepara rutinas de graficaci�n nuestras ---------------------------------

# Lee la rutina de graficaci�n del directorio de trabajo preparado y seleccionado
# datos del directorio de trabajo en el equipo port�til de Miguel
setwd(dir.trabajo)
source("scatter_fill.R")
source("grafica_mapa.R")


# Lectura de datos y preparaci�n de tablas --------------------------------
# Las coordenadas geogr�ficas de los datos est�n en este archivo
archivo.coord <- paste(dir.datos,"coordenadas.dbf", sep ="/" )
coordenadas <- read.dbf(archivo.coord)
head(coordenadas)

archivo.mexbio <- paste("~/1 Nubes/Google Drive/2 Proyectos/RoBiN/Datos RoBiN/Datos MEX/MEXBIO", 
                        "VARSIEMX_MEXBIO_relleno.dbf", sep="/")

mexbio <- read.dbf(archivo.mexbio)
head(mexbio)

# Lectura de datos directamente desde el archivo de Access
# esto supone que el driver apropiado est� instalado. Vease esto si no
# http://www.microsoft.com/es-es/download/details.aspx?id=13255
infys.dbq <- paste("DBQ=", dir.bd.infys, "/intmx_me.accdb", sep="")
infys.odbc <- paste ("DRIVER=Microsoft Access Driver (*.mdb, *.accdb)", infys.dbq,sep=";")
infys.odbc <- odbcDriverConnect(infys.odbc)
sqlTables(infys.odbc,tableType="TABLE")
datos <- sqlFetch(infys.odbc, "VarsIEMx")
head(datos)
odbcClose(infys.odbc)

# Si ODBC no jala hay qu cargar la tabla grandota de datos que gener� Juli�n en "txt"
# en el equipo de juli�n est� aqu�:
#datos <- read.table("VarsIEMx.txt",sep=",",header=TRUE)

# en el equipo port�til de Miguel uso una versi�n depurada (sin faltantes y sin "sgdam").
#archivo.datos <- paste(dir.datos,"completos_mapa_MXintegridad_28092013.txt", sep ="/" )
#datos <- read.table(archivo.datos,sep=",",header=TRUE)
#head(datos)

# Los NAs vienen como -9999 en los datos, para R, el valor de los missing values es NA
# hagamos los -9999, NA's
for (i in 1:ncol(mexbio)) { mexbio[mexbio[,i]==-9999,i]<-NA }

# se hizo el c�lculo de integridad s�lo para las observaciones sin missings
# quit�moslas (debemos quitar la s�ptima variable, "sgdam", porque ten�a muchos missings
# y se excluy� del ejercicio). La nueva matr�z es congruente con el vector de integridad.
mexbio <- mexbio[,-9]
id.datos <- mexbio[complete.cases(mexbio),]
head(id.datos)


# Lectura de los datos de integridad
integridades <- dir(dir.datos, pattern="(full)")

# s�lo nos interesa la integridad que es el dato en la columna 3 en estos archivos
int.1 <- read.table(paste(dir.datos, integridades[1], sep="/"), header=TRUE, sep="\t")
integ.datos <- data.frame(int.1[,3])
for (i in 2:4) 
  integ.datos <- cbind(integ.datos, read.table(paste(dir.datos, integridades[i], sep="/"), 
                       header=TRUE, sep="\t")[,3])
names(integ.datos) <- c("int.1","int.2","int.3","int.4")
head(integ.datos)

# Me quedo con los nombres de los archivos leidos sin la extensi�n para etiquetar mapas.
integridades <- as.character(strsplit(integridades[1:4], split=".txt"))

# agrego el dato de identificaci�n de las filas a la table de integridades
# lo tomo del archivo que us� para generar las integridades en NETICA
# completos_mapa_MXintegridad_28092013.txt
datos <- data.frame(id_mll=completos_mapa_MXintegridad_28092013$id_mll,integ.datos)
head(datos)

# MERGE DATA.FRAMES DONT JUST CONCATENATE! or coordinates will be fucked up
datos <- merge(datos,coordenadas,by="id_mll",all=FALSE)

datos.mexbio <- merge(id.datos, RB.integrity, by = "id_mll", all=FALSE)

# y tambi�n solo queremos una tabla con coordenadas e integridad
datos <- datos[, c(2:5,7,8)]

# Noto que las integridades est�n invertidas, as� que las restar� de 1.
datos [, 1:4] <-  1 - datos [, 1:4]

# estructura final de la base
head(datos)


# Producci�n de los mapas -------------------------------------------------

# Despliegue del mapa usando la librer�a ggplot2
# Versi�n "abreviada" de llamada a ggplot2
qplot(data = datos.mexbio, x = xcoord, y = ycoord, fill=int.mexbio, geom="raster")

# Una version "larga" pero con m�s control la constru� en la funci�n "grafica.mapa".
# que est� en un archivo separado pero que se lee en este script si est�n en el mismo dir.

# Asi genero el mapa, hay que cuidar la correspondencia entre dato de integridad
# y la etiqueta , en este caso deben corresponder.
mapa.1 <- grafica.mapa(datos[, 1], datos[, 5:6], integridades[1], nlevels=20)
mapa.2 <- grafica.mapa(datos[, 2], datos[, 5:6], integridades[2], nlevels=20)
mapa.3 <- grafica.mapa(datos[, 3], datos[, 5:6], integridades[3], nlevels=20)
mapa.4 <- grafica.mapa(datos[, 4], datos[, 5:6], integridades[4], nlevels=20)
mapa.5 <- grafica.mapa(datos.mexbio$int.mexbio, datos.mexbio[,2:3], "mexbio (Mel)", nlevels=20)

# Lo imprimo en tama�o doble cata o "tabloide", el tipo de archivo se toma de la extensi�n.
ggsave("int-1.pdf", plot=mapa.1, units="in", width=15, height= 9, dpi=600)
ggsave("int-2.pdf", plot=mapa.2, units="in", width=15, height= 9, dpi=600)
ggsave("int-3.pdf", plot=mapa.3, units="in", width=15, height= 9, dpi=600)
ggsave("int-4.pdf", plot=mapa.4, units="in", width=15, height= 9, dpi=600)
ggsave("int-5.pdf", plot=mapa.5, units="in", width=15, height= 9, dpi=600)

#Para el powerpoint
ggsave("int-1.png", plot=mapa.1, units="in", width=9, height= 7, dpi=92)
ggsave("int-2.png", plot=mapa.2, units="in", width=9, height= 7, dpi=92)
ggsave("int-3.png", plot=mapa.3, units="in", width=9, height= 7, dpi=92)
ggsave("int-4.png", plot=mapa.4, units="in", width=9, height= 7, dpi=92)


# Mapeo original de Juli�n ------------------------------------------------
# o se podr�a guardar el plot en un png, ejemplo:

# completos_mapa_MXintegridad_28092013-integr4
png(filename="integridad-MEZ.png",width=3000,height=2000)
scatter.fill(datos$XCOORD,datos$YCOORD,datos$int1,pch=".",nlevels=20,main="integridad",xlab="",ylab="") 
dev.off()

# RB-integrity (mapa-completo -HSI +deltaVP) 1
png(filename="RB-integrity_mapacompleto_HSI_deltaVP_1.png",width=3000,height=2000)
scatter.fill(datos$XCOORD,datos$YCOORD,datos$int2,pch=".",nlevels=20,main="integridad",xlab="",ylab="") 
dev.off()

# RB-integrity (mapa-completo -HSI +deltaVP) 2
png(filename="RB-integrity_mapacompleto_HSI_deltaVP_2.png",width=3000,height=2000)
scatter.fill(datos$XCOORD,datos$YCOORD,datos$int3,pch=".",nlevels=20,main="integridad",xlab="",ylab="") 
dev.off()

# deltaVP
png(filename="deltavp.png",width=3000,height=2000)
scatter.fill(datos$XCOORD,datos$YCOORD,datos$deltavp,pch=".",nlevels=18,main="deltavp",xlab="",ylab="") 
dev.off()

# podemos guardar el ejercicio como un texto para abrirlo en QGIS or whatever (como formato "texto delimitado)
write.table(datos[,20:ncol(datos)],"integridades_mas_coordenadas.txt",sep="\t",row.names=FALSE)
