# @author Miguel Equihua 
# contact: equihuam@gmail.com
# Institution: Inecol
#
#  Genera histogramas de todas las variables que participan en el c�lculos de ZVH
#

library (ggplot2)
library(reshape2)

# Funci�n definida para generar histogramas de una variable en el ciclo anual y guardarlos
histogramas.clima <- function (vars, archivo, ubicaci�n)
{
  # Genera una tabla de datos con dos columnas que etiquetan 
  # los datos seg�n el nombre de la columna de or�gen
  mdat <- melt(climat.2.df@data[,vars]) 
  
  graf <- ggplot(mdat, aes(value)) +
    geom_histogram(aes(y=..count..), binwidth=2, colour='black', fill='skyblue') + 
    geom_density() + facet_wrap(~variable, scales="free")
  
  # Save the plot in GD sync structure
  ggsave(archivo, path = dir.ref, graf, width = 22, height = 17, units = "in" )
  
  return (graf)
}

# Variables to display
pp.vars <- c(1:12)
tmax.vars <- c(13:24)
tmin.vars <- c(25:36)

# Base directories for storage
dir <- ubica.trabajo(equipo="miguel_esc")
dir.ref <- paste(dir$GIS.in, "/2004/clima", sep="")

# Precipitaci�n
graf <- histogramas.clima (pp.vars, "ZVH_pp_hist.pdf", dir.ref)

# Temperatura m�xima
graf <- histogramas.clima (tmax.vars, "ZVH_tmax_hist.pdf", dir.ref)

# Temperatura m�nima
graf <- histogramas.clima (tmin.vars, "ZVH_tmin_hist.pdf", dir.ref)
