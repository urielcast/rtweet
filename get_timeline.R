###Obtener datos de un usuario de twitter

###Necesitamos el paquete rtweet
install.packages("rtweet")
library (rtweet)

###Creación del token para la aplicación que permite obtener tweets.

APP_NAME <-  "nombre del app"
API_KEY <-  "xxxxx"
API_SECRET_KEY <-  "xxxxxx"
ACCES_TOKEN <- "xxxxx"
ACCESS_TOKEN_SECRET <-  "xxxxxx"
twitter_token <- create_token(app = APP_NAME,consumer_key = API_KEY, consumer_secret = API_SECRET_KEY, access_token = ACCES_TOKEN, access_secret = ACCESS_TOKEN_SECRET)

###Búsqueda de tweets (parámetros: usuario, n es el número de tweets a descargar, inclusión de retweets e idioma de los tweets).

BD <- get_timeline("CCaraboboLibre", n = 2500, include_rts = FALSE, lang = "es")

###Separar la fecha y la hora en dos columnas
library (tidyr)
BD <- separate(BD, created_at, c("Fecha","Hora"),sep = 10, convert = TRUE)

###Reorganizar la base de datos BD en dataframe para exportar en csv
CCaraboboLibre = as.data.frame(BD)
save_as_csv(CCaraboboLibre, "CCaraboboLibre.csv")
