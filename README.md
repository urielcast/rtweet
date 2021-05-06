###rtweet
###Redes sociais: Coleta e analises de dados em redes sociais usando R.

###O material parte de uma implementação de chamadas projetadas para coletar e organizar dados do Twitter por meio do REST do Twitter e fazer stream de Application Program Interfaces (API), que pode ser encontrada na seguinte URL: < https://developer.twitter.com/en/docs >. Este pacote foi revisado por pares por rOpenSci (v. 0.6.9) em < https://cran.r-project.org/web/packages/rtweet/index.html >.

###Primer código R e Gephi:


install.packages("rtweet", dependencies = TRUE)
library (rtweet)

###Creación del token para la aplicación que permite obtener tweets.

create_token(
  app = "nome_do_app_twetter",
  consumer_key = "consumer_key",
  consumer_secret = "consumer_secret")

###Búsqueda de tweets (parámetros: palabra clave, número de tweets a descargar, volver a buscar al alcanzar el límite de tweets, tipo de búsqueda, inclusión de retweets e idioma de los tweets).

BD <- search_tweets(
  "CCaraboboLibre", n = 1000, retryonratelimit = TRUE, type = "recent", include_rts = TRUE, lang = "es"
)

###Guarda el archivo con datos brutos sin tratar.

saveRDS(BD, file="bd.rds")

##2. Limpieza de datos.

###Selección de variables relevantes y renombramiento.

BD <- data.frame(BD$created_at, BD$screen_name, BD$text, BD$source, BD$favorite_count, BD$retweet_count, BD$description, BD$followers_count, BD$friends_count, BD$statuses_count, BD$account_created_at, BD$name, BD$location, BD$is_retweet)
names(BD) <- c("Fecha", "Nickname","Texto del tweet", "Fuente", "Favoritos", "Retweets", "Descripcion del autor", "Seguidores", "Seguidos", "Publicaciones", "Creacion de cuenta", "Nombre", "Ubicacion", "Retweet")

###Creación de variables de fecha, hora, fecha de creación de cuenta y fuente.

library(tidyr)
BD <- separate(BD, Fecha, c("Fecha","Hora"),sep = 10, convert = TRUE)
BD <- separate(BD, "Creacion de cuenta", c("FechaCuenta","HoraCuenta"),sep = 10, convert = TRUE)
BD <- BD[,-13]

BD$Fuente <- factor(BD$Fuente,
                    levels = c("Twitter for Android","Twitter for iPhone","Twitter Web Client","Twitter Lite","TweetDeck", "Otros"))

library(plyr)
BD$FuenteReco <- revalue(BD$Fuente, c("Twitter for Android" = "Android", "Twitter for iPhone" = "Iphone", "Twitter Web Client" = "Web", "Twitter Lite" = "Lite", "TweetDeck" = "Tweetdeck", "Otros" = "Otros"))
BD$FuenteReco <- replace_na(BD$FuenteReco, "Otros")
BD$Fuente <- BD$FuenteReco
BD <- BD[-17]

###Estimación del sexo del usuario (no es necesario para visualizar en Gephi, pero es una prueba que hice de las posibilidades de R).

BD <- separate(BD, Nombre, "NombreSexo", sep = " ", convert = TRUE, remove = FALSE)

BD$NombreSexo <- sapply(BD$NombreSexo, function(x) iconv(enc2utf8(x), sub = "byte"))

hombres <- read.csv("bdnombreshombres.csv")
mujeres <- read.csv("bdnombresmujeres.csv")

BD$NombreSexo <- tolower(BD$NombreSexo)
hombres$nombre <- tolower(hombres$nombre)
mujeres$nombre <- tolower(mujeres$nombre)
BD$Hombres <- match(BD$NombreSexo, hombres$nombre)
BD$Mujeres <- match(BD$NombreSexo, mujeres$nombre)

library(car)
BD$Hombres <- recode(BD$Hombres, "1:10000='Hombre'")
BD$Mujeres <- recode(BD$Mujeres, "1:10000='Mujer'")

BD$Sexo [BD$Hombres == "Hombre"] <- "Hombre"
BD$Sexo [BD$Mujeres == "Mujer"] <- "Mujer" 
BD <- BD[,-17:-18]

##3. Preparación para exportación a Gephi.

###Creación de conjunto de datos con aristas.

aristas1 <- data.frame(BD$screen_name, BD$is_quote, BD$is_retweet, BD$reply_to_status_id, BD$quoted_screen_name, BD$retweet_screen_name, BD$reply_to_screen_name)

names(aristas1) <- c("origen", "cita", "RT","respuesta","tocita","tort","torespuesta")

###Creación de tipo de interacción.

aristas1$clase = "tweet"
aristas1$clase[aristas1$cita == TRUE] <- "cita"
aristas1$clase[aristas1$RT == TRUE] <- "retweet"
aristas1$clase[aristas1$respuesta != TRUE] <- "respuesta"

aristas2 <- data.frame(aristas1$origen, aristas1$clase, aristas1$tocita, aristas1$torespuesta, aristas1$tort)
aristas3 <- aristas2[aristas2$aristas1.clase != "tweet",]

###Bucle de creación de variable única de usuario de destino independientemente del tipo de interacción.

for (i in 1:length(aristas3$aristas1.clase)) {
  if (aristas3$aristas1.clase[i] =="retweet") {
    aristas3$destino[i] <- as.character(aristas3$aristas1.tort[i])
  } else if (aristas3$aristas1.clase[i] == "respuesta") {
    aristas3$destino[i] <- as.character(aristas3$aristas1.torespuesta[i])
  } else {
    aristas3$destino[i] <- as.character(aristas3$aristas1.tocita[i])
  }
}

aristas3$destino <- as.factor(aristas3$destino)

aristas <- data.frame(aristas3$aristas1.origen, aristas3$aristas1.origen, aristas3$aristas1.clase, aristas3$destino)
names(aristas) <- c("Source", "Label", "Clase", "Target")

###Creación de conjunto de datos con nodos.

nodos_prev <- data.frame(BD$screen_name, BD$screen_name)
nodos <- unique(nodos_prev)
names(nodos) <- c("origen", "label")

### Exportación a xlsx importable a Gephi.

install.packages("openxlsx")
library(openxlsx)
write.xlsx(aristas,"aristas_convocatoriaelecciones.xlsx", asTable = FALSE)
write.xlsx(nodos,"nodos_convocatoriaelecciones.xlsx", asTable = FALSE)
write.xlsx(BD,"BD_convocatoriaelecciones.xlsx", asTable = FALSE)
